//! Expression parsing

use relanote_ast::*;
use relanote_core::{intern, Spanned};
use relanote_lexer::TokenKind;

use crate::error::{ParseError, ParseResult};
use crate::parser::Parser;

impl Parser {
    /// Parse any expression
    pub fn parse_expression(&mut self) -> ParseResult<Spanned<Expr>> {
        self.parse_pipe_expr()
    }

    /// Parse pipe expression: expr |> expr
    fn parse_pipe_expr(&mut self) -> ParseResult<Spanned<Expr>> {
        let mut left = self.parse_or_expr()?;

        while self.match_token(&TokenKind::PipeOp) {
            let right = self.parse_or_expr()?;
            let span = left.span.merge(right.span);
            left = Spanned::new(
                Expr::Pipe(Pipe {
                    left: Box::new(left),
                    right: Box::new(right),
                }),
                span,
            );
        }

        Ok(left)
    }

    /// Parse logical or: expr or expr
    fn parse_or_expr(&mut self) -> ParseResult<Spanned<Expr>> {
        let mut left = self.parse_and_expr()?;

        while self.match_ident("or") {
            let right = self.parse_and_expr()?;
            let span = left.span.merge(right.span);
            left = Spanned::new(
                Expr::Binary(Binary {
                    op: BinaryOp::Or,
                    left: Box::new(left),
                    right: Box::new(right),
                }),
                span,
            );
        }

        Ok(left)
    }

    /// Parse logical and: expr and expr
    fn parse_and_expr(&mut self) -> ParseResult<Spanned<Expr>> {
        let mut left = self.parse_equality_expr()?;

        while self.match_ident("and") {
            let right = self.parse_equality_expr()?;
            let span = left.span.merge(right.span);
            left = Spanned::new(
                Expr::Binary(Binary {
                    op: BinaryOp::And,
                    left: Box::new(left),
                    right: Box::new(right),
                }),
                span,
            );
        }

        Ok(left)
    }

    /// Parse equality: expr == expr
    fn parse_equality_expr(&mut self) -> ParseResult<Spanned<Expr>> {
        let mut left = self.parse_comparison_expr()?;

        loop {
            if self.check(&TokenKind::Eq) && self.peek_next().kind == TokenKind::Eq {
                self.advance();
                self.advance();
                let right = self.parse_comparison_expr()?;
                let span = left.span.merge(right.span);
                left = Spanned::new(
                    Expr::Binary(Binary {
                        op: BinaryOp::Eq,
                        left: Box::new(left),
                        right: Box::new(right),
                    }),
                    span,
                );
            } else {
                break;
            }
        }

        Ok(left)
    }

    /// Parse comparison: expr < expr | expr > expr
    fn parse_comparison_expr(&mut self) -> ParseResult<Spanned<Expr>> {
        let mut left = self.parse_additive_expr()?;

        loop {
            let op = if self.match_token(&TokenKind::LAngle) {
                if self.match_token(&TokenKind::Eq) {
                    Some(BinaryOp::Le)
                } else {
                    Some(BinaryOp::Lt)
                }
            } else if self.match_token(&TokenKind::RAngle) {
                if self.match_token(&TokenKind::Eq) {
                    Some(BinaryOp::Ge)
                } else {
                    Some(BinaryOp::Gt)
                }
            } else {
                None
            };

            if let Some(op) = op {
                let right = self.parse_additive_expr()?;
                let span = left.span.merge(right.span);
                left = Spanned::new(
                    Expr::Binary(Binary {
                        op,
                        left: Box::new(left),
                        right: Box::new(right),
                    }),
                    span,
                );
            } else {
                break;
            }
        }

        Ok(left)
    }

    /// Parse addition/subtraction/concatenation
    fn parse_additive_expr(&mut self) -> ParseResult<Spanned<Expr>> {
        let mut left = self.parse_multiplicative_expr()?;

        loop {
            // Note: PlusPlus must be checked before Plus
            let op = if self.match_token(&TokenKind::PlusPlus) {
                Some(BinaryOp::Concat)
            } else if self.match_token(&TokenKind::Plus) {
                Some(BinaryOp::Add)
            } else if self.match_token(&TokenKind::Minus) {
                Some(BinaryOp::Sub)
            } else {
                None
            };

            if let Some(op) = op {
                let right = self.parse_multiplicative_expr()?;
                let span = left.span.merge(right.span);
                left = Spanned::new(
                    Expr::Binary(Binary {
                        op,
                        left: Box::new(left),
                        right: Box::new(right),
                    }),
                    span,
                );
            } else {
                break;
            }
        }

        Ok(left)
    }

    /// Parse multiplication/division
    fn parse_multiplicative_expr(&mut self) -> ParseResult<Spanned<Expr>> {
        let mut left = self.parse_unary_expr()?;

        loop {
            let op = if self.match_token(&TokenKind::Staccato) {
                // * is also used for multiplication
                Some(BinaryOp::Mul)
            } else {
                None
            };

            if let Some(op) = op {
                let right = self.parse_unary_expr()?;
                let span = left.span.merge(right.span);
                left = Spanned::new(
                    Expr::Binary(Binary {
                        op,
                        left: Box::new(left),
                        right: Box::new(right),
                    }),
                    span,
                );
            } else {
                break;
            }
        }

        Ok(left)
    }

    /// Parse unary: -expr | not expr
    fn parse_unary_expr(&mut self) -> ParseResult<Spanned<Expr>> {
        let start = self.current_span();

        if self.match_token(&TokenKind::Minus) {
            let operand = self.parse_unary_expr()?;
            let span = self.span_from(start);
            return Ok(Spanned::new(
                Expr::Unary(Unary {
                    op: UnaryOp::Neg,
                    operand: Box::new(operand),
                }),
                span,
            ));
        }

        if self.match_ident("not") {
            let operand = self.parse_unary_expr()?;
            let span = self.span_from(start);
            return Ok(Spanned::new(
                Expr::Unary(Unary {
                    op: UnaryOp::Not,
                    operand: Box::new(operand),
                }),
                span,
            ));
        }

        self.parse_postfix_expr()
    }

    /// Check if the current token can start a function argument (for Haskell-style application)
    fn can_start_argument(&self) -> bool {
        matches!(
            self.current(),
            TokenKind::Integer(_)
                | TokenKind::Float(_)
                | TokenKind::String(_)
                | TokenKind::True
                | TokenKind::False
                | TokenKind::Root
                | TokenKind::Interval(_)
                | TokenKind::AbsolutePitch(_)
                | TokenKind::Ident(_)
                | TokenKind::LParen
                | TokenKind::LBracket
                | TokenKind::Pipe
                | TokenKind::LAngle
        )
    }

    /// Parse postfix: expr(args) | expr[index] | expr.field | expr arg (Haskell-style)
    fn parse_postfix_expr(&mut self) -> ParseResult<Spanned<Expr>> {
        let mut expr = self.parse_primary_expr()?;

        loop {
            if self.match_token(&TokenKind::LParen) {
                let args = self.parse_list(&TokenKind::RParen, |p| p.parse_expression())?;
                self.expect(&TokenKind::RParen, ")")?;
                let span = self.span_from(expr.span);
                expr = Spanned::new(
                    Expr::Application(Application {
                        func: Box::new(expr),
                        args,
                    }),
                    span,
                );
            } else if self.can_start_argument() {
                // Haskell-style function application: f x y z = f(x, y, z)
                // Collect all adjacent arguments into a single Application
                let mut args = Vec::new();
                while self.can_start_argument() {
                    args.push(self.parse_primary_expr()?);
                }
                let span = if let Some(last) = args.last() {
                    expr.span.merge(last.span)
                } else {
                    expr.span
                };
                expr = Spanned::new(
                    Expr::Application(Application {
                        func: Box::new(expr),
                        args,
                    }),
                    span,
                );
            } else if self.match_token(&TokenKind::LBracket) {
                let index = self.parse_expression()?;
                self.expect(&TokenKind::RBracket, "]")?;
                let span = self.span_from(expr.span);
                expr = Spanned::new(
                    Expr::Index(Index {
                        base: Box::new(expr),
                        index: Box::new(index),
                    }),
                    span,
                );
            } else if self.match_token(&TokenKind::Dot) {
                let field = self.parse_ident()?;
                let span = self.span_from(expr.span);
                expr = Spanned::new(
                    Expr::Field(Field {
                        base: Box::new(expr),
                        field,
                    }),
                    span,
                );
            } else {
                break;
            }
        }

        Ok(expr)
    }

    /// Parse primary expressions
    pub fn parse_primary_expr(&mut self) -> ParseResult<Spanned<Expr>> {
        let start = self.current_span();

        match self.current().clone() {
            // Literals
            TokenKind::Integer(n) => {
                self.advance();
                Ok(Spanned::new(Expr::Integer(n), start))
            }

            TokenKind::Float(n) => {
                self.advance();
                Ok(Spanned::new(Expr::Float(n), start))
            }

            TokenKind::String(s) => {
                self.advance();
                Ok(Spanned::new(Expr::String(s), start))
            }

            TokenKind::True => {
                self.advance();
                Ok(Spanned::new(Expr::Bool(true), start))
            }

            TokenKind::False => {
                self.advance();
                Ok(Spanned::new(Expr::Bool(false), start))
            }

            // Root/Rest
            TokenKind::Root => {
                self.advance();
                Ok(Spanned::new(Expr::Root, start))
            }

            // Interval
            TokenKind::Interval(data) => {
                self.advance();
                let interval = IntervalLit {
                    quality: data.quality,
                    degree: data.degree,
                    accidentals: data.accidentals,
                };
                Ok(Spanned::new(Expr::Interval(interval), start))
            }

            // Absolute pitch (C4, D#3, Bb5, etc.)
            TokenKind::AbsolutePitch(data) => {
                self.advance();
                let pitch = AbsolutePitchLit::from(data);
                Ok(Spanned::new(Expr::AbsolutePitch(pitch), start))
            }

            // Lambda
            TokenKind::Lambda => self.parse_lambda(),

            // If expression
            TokenKind::If => self.parse_if_expr(),

            // Let expression
            TokenKind::Let => self.parse_let_expr(),

            // Block
            TokenKind::Pipe => self.parse_block(),

            // Array
            TokenKind::LBracket => {
                self.advance();
                let elements = self.parse_list(&TokenKind::RBracket, |p| p.parse_expression())?;
                self.expect(&TokenKind::RBracket, "]")?;
                let span = self.span_from(start);
                Ok(Spanned::new(Expr::Array(elements), span))
            }

            // Tuple or parenthesized expression
            TokenKind::LParen => {
                self.advance();

                if self.match_token(&TokenKind::RParen) {
                    let span = self.span_from(start);
                    return Ok(Spanned::new(Expr::Unit, span));
                }

                let first = self.parse_expression()?;

                if self.match_token(&TokenKind::Comma) {
                    let mut elements = vec![first];
                    if !self.check(&TokenKind::RParen) {
                        elements
                            .extend(self.parse_list(&TokenKind::RParen, |p| p.parse_expression())?);
                    }
                    self.expect(&TokenKind::RParen, ")")?;
                    let span = self.span_from(start);
                    Ok(Spanned::new(Expr::Tuple(elements), span))
                } else {
                    self.expect(&TokenKind::RParen, ")")?;
                    let span = self.span_from(start);
                    Ok(Spanned::new(Expr::Paren(Box::new(first)), span))
                }
            }

            // Scale index <n>
            TokenKind::LAngle => {
                self.advance();
                if let TokenKind::Integer(n) = self.current().clone() {
                    self.advance();
                    let mut accidentals = Vec::new();
                    while self.match_token(&TokenKind::Plus) {
                        accidentals.push(relanote_lexer::token::Accidental::Sharp);
                    }
                    while self.match_token(&TokenKind::Minus) {
                        accidentals.push(relanote_lexer::token::Accidental::Flat);
                    }
                    self.expect(&TokenKind::RAngle, ">")?;
                    let span = self.span_from(start);

                    let pitch = if accidentals.is_empty() {
                        Pitch::ScaleIndex(n as u8)
                    } else {
                        Pitch::ScaleIndexMod(n as u8, accidentals)
                    };

                    Ok(Spanned::new(
                        Expr::Block(Block::new(vec![Spanned::new(
                            Slot::Note {
                                pitch: Spanned::new(pitch, span),
                                articulations: vec![],
                                duration: None,
                            },
                            span,
                        )])),
                        span,
                    ))
                } else {
                    Err(ParseError::custom("expected integer in scale index", start))
                }
            }

            // Section
            TokenKind::Section => self.parse_section(),

            // Layer
            TokenKind::Layer => self.parse_layer(),

            // Part
            TokenKind::Part => self.parse_part(),

            // Env
            TokenKind::Env => self.parse_envelope(),

            // Render - treat as function identifier
            TokenKind::Render => {
                self.advance();
                Ok(Spanned::new(
                    Expr::Ident(Ident::new(intern("render"))),
                    start,
                ))
            }

            // Context - treat as function identifier
            TokenKind::Context => {
                self.advance();
                Ok(Spanned::new(
                    Expr::Ident(Ident::new(intern("Context"))),
                    start,
                ))
            }

            // Key - treat as identifier for Key.C etc
            TokenKind::Key => {
                self.advance();
                Ok(Spanned::new(Expr::Ident(Ident::new(intern("Key"))), start))
            }

            // Identifier
            TokenKind::Ident(name) => {
                self.advance();
                Ok(Spanned::new(Expr::Ident(Ident::new(intern(&name))), start))
            }

            // Tuplet
            TokenKind::LBrace => self.parse_tuplet_expr(),

            // In scale expression: in Scale
            TokenKind::In => {
                self.advance();
                let scale = self.parse_postfix_expr()?;
                let span = self.span_from(start);
                Ok(Spanned::new(
                    Expr::InScale(InScaleExpr {
                        scale: Box::new(scale),
                    }),
                    span,
                ))
            }

            _ => Err(ParseError::InvalidExpression { span: start }),
        }
    }

    /// Parse lambda: \x -> expr or \x y -> expr
    fn parse_lambda(&mut self) -> ParseResult<Spanned<Expr>> {
        let start = self.current_span();
        self.expect(&TokenKind::Lambda, "\\")?;

        let mut params = Vec::new();
        while !self.check(&TokenKind::Arrow) && !self.is_at_end() {
            params.push(self.parse_pattern()?);
        }

        self.expect(&TokenKind::Arrow, "->")?;
        let body = self.parse_expression()?;
        let span = self.span_from(start);

        Ok(Spanned::new(
            Expr::Lambda(Lambda {
                params,
                body: Box::new(body),
            }),
            span,
        ))
    }

    /// Parse if expression: if cond then expr else expr
    fn parse_if_expr(&mut self) -> ParseResult<Spanned<Expr>> {
        let start = self.current_span();
        self.expect(&TokenKind::If, "if")?;

        let condition = self.parse_expression()?;
        self.expect(&TokenKind::Then, "then")?;
        let then_branch = self.parse_expression()?;

        let else_branch = if self.match_token(&TokenKind::Else) {
            Some(self.parse_expression()?)
        } else {
            None
        };

        let span = self.span_from(start);
        Ok(Spanned::new(
            Expr::If(Box::new(IfExpr {
                condition,
                then_branch,
                else_branch,
            })),
            span,
        ))
    }

    /// Parse let expression: let x = e1 in e2
    fn parse_let_expr(&mut self) -> ParseResult<Spanned<Expr>> {
        let start = self.current_span();
        self.expect(&TokenKind::Let, "let")?;

        let pattern = self.parse_pattern()?;
        self.expect(&TokenKind::Eq, "=")?;
        let value = self.parse_expression()?;

        if self.match_token(&TokenKind::In) {
            let body = self.parse_expression()?;
            let span = self.span_from(start);
            Ok(Spanned::new(
                Expr::Let(Box::new(LetExpr {
                    pattern,
                    type_ann: None,
                    value,
                    body,
                })),
                span,
            ))
        } else {
            Ok(value)
        }
    }

    /// Parse a pattern
    pub fn parse_pattern(&mut self) -> ParseResult<Spanned<Pattern>> {
        let start = self.current_span();

        match self.current().clone() {
            TokenKind::Ident(name) if name == "_" => {
                self.advance();
                Ok(Spanned::new(Pattern::Wildcard, start))
            }

            TokenKind::Ident(name) => {
                self.advance();
                Ok(Spanned::new(
                    Pattern::Ident(Ident::new(intern(&name))),
                    start,
                ))
            }

            TokenKind::Integer(n) => {
                self.advance();
                Ok(Spanned::new(
                    Pattern::Literal(LiteralPattern::Integer(n)),
                    start,
                ))
            }

            TokenKind::String(s) => {
                self.advance();
                Ok(Spanned::new(
                    Pattern::Literal(LiteralPattern::String(s)),
                    start,
                ))
            }

            TokenKind::True => {
                self.advance();
                Ok(Spanned::new(
                    Pattern::Literal(LiteralPattern::Bool(true)),
                    start,
                ))
            }

            TokenKind::False => {
                self.advance();
                Ok(Spanned::new(
                    Pattern::Literal(LiteralPattern::Bool(false)),
                    start,
                ))
            }

            TokenKind::LParen => {
                self.advance();
                if self.match_token(&TokenKind::RParen) {
                    let span = self.span_from(start);
                    return Ok(Spanned::new(Pattern::Literal(LiteralPattern::Unit), span));
                }

                let first = self.parse_pattern()?;
                if self.match_token(&TokenKind::Comma) {
                    let mut patterns = vec![first];
                    if !self.check(&TokenKind::RParen) {
                        patterns
                            .extend(self.parse_list(&TokenKind::RParen, |p| p.parse_pattern())?);
                    }
                    self.expect(&TokenKind::RParen, ")")?;
                    let span = self.span_from(start);
                    Ok(Spanned::new(Pattern::Tuple(patterns), span))
                } else {
                    self.expect(&TokenKind::RParen, ")")?;
                    Ok(first)
                }
            }

            _ => Err(ParseError::custom("expected pattern", start)),
        }
    }
}
