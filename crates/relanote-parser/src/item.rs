//! Item parsing

use relanote_ast::*;
use relanote_core::Spanned;
use relanote_lexer::TokenKind;

use crate::error::{ParseError, ParseResult};
use crate::parser::Parser;

impl Parser {
    /// Parse a top-level item
    pub fn parse_item(&mut self) -> ParseResult<Spanned<Item>> {
        let start = self.current_span();

        match self.current() {
            TokenKind::Scale => self.parse_scale_def(),
            TokenKind::Chord => self.parse_chord_def(),
            TokenKind::Let => self.parse_let_binding(),
            TokenKind::Import => self.parse_import(),
            TokenKind::Export => self.parse_export(),
            _ => {
                let expr = self.parse_expression()?;
                let span = self.span_from(start);
                Ok(Spanned::new(Item::ExprStmt(expr), span))
            }
        }
    }

    /// Parse scale definition
    fn parse_scale_def(&mut self) -> ParseResult<Spanned<Item>> {
        let start = self.current_span();
        self.expect(&TokenKind::Scale, "scale")?;

        let name = self.parse_ident()?;
        self.expect(&TokenKind::Eq, "=")?;

        // Check if this is a modification
        if self.check(&TokenKind::Ident("".to_string())) && !self.check(&TokenKind::LBrace) {
            let base = self.parse_expression()?;
            self.expect(&TokenKind::With, "with")?;
            self.expect(&TokenKind::LBrace, "{")?;
            let intervals = self.parse_interval_list()?;
            self.expect(&TokenKind::RBrace, "}")?;
            let span = self.span_from(start);

            Ok(Spanned::new(
                Item::ScaleDef(ScaleDef {
                    name,
                    base: Some(base),
                    intervals,
                }),
                span,
            ))
        } else {
            self.expect(&TokenKind::LBrace, "{")?;
            let intervals = self.parse_interval_list()?;
            self.expect(&TokenKind::RBrace, "}")?;
            let span = self.span_from(start);

            Ok(Spanned::new(
                Item::ScaleDef(ScaleDef {
                    name,
                    base: None,
                    intervals,
                }),
                span,
            ))
        }
    }

    /// Parse chord definition
    fn parse_chord_def(&mut self) -> ParseResult<Spanned<Item>> {
        let start = self.current_span();
        self.expect(&TokenKind::Chord, "chord")?;

        let name = self.parse_ident()?;
        self.expect(&TokenKind::Eq, "=")?;
        self.expect(&TokenKind::LBracket, "[")?;

        let intervals = self.parse_interval_list()?;

        self.expect(&TokenKind::RBracket, "]")?;
        let span = self.span_from(start);

        Ok(Spanned::new(Item::ChordDef(ChordDef { name, intervals }), span))
    }

    /// Parse let binding
    fn parse_let_binding(&mut self) -> ParseResult<Spanned<Item>> {
        let start = self.current_span();
        self.expect(&TokenKind::Let, "let")?;

        let first_pattern = self.parse_pattern()?;

        let mut params = Vec::new();
        while !self.check(&TokenKind::Eq) && !self.is_at_end() {
            params.push(self.parse_pattern()?);
        }

        self.expect(&TokenKind::Eq, "=")?;
        let value = self.parse_expression()?;

        // Check for `in` keyword - if present, this is a let expression, not a binding
        if self.match_token(&TokenKind::In) {
            let body = self.parse_expression()?;
            let span = self.span_from(start);

            if params.is_empty() {
                Ok(Spanned::new(
                    Item::ExprStmt(Spanned::new(
                        Expr::Let(Box::new(LetExpr {
                            pattern: first_pattern,
                            type_ann: None,
                            value,
                            body,
                        })),
                        span,
                    )),
                    span,
                ))
            } else {
                // let f x = e1 in e2 -> let f = \x -> e1 in e2
                let name = match &first_pattern.node {
                    Pattern::Ident(id) => id.clone(),
                    _ => {
                        return Err(ParseError::custom(
                            "function name must be an identifier",
                            first_pattern.span,
                        ))
                    }
                };
                let lambda = self.build_lambda(&params, value);
                Ok(Spanned::new(
                    Item::ExprStmt(Spanned::new(
                        Expr::Let(Box::new(LetExpr {
                            pattern: Spanned::new(Pattern::Ident(name), first_pattern.span),
                            type_ann: None,
                            value: lambda,
                            body,
                        })),
                        span,
                    )),
                    span,
                ))
            }
        } else {
            let span = self.span_from(start);

            if params.is_empty() {
                Ok(Spanned::new(
                    Item::LetBinding(LetBinding {
                        pattern: first_pattern,
                        type_ann: None,
                        value,
                    }),
                    span,
                ))
            } else {
                let name = match &first_pattern.node {
                    Pattern::Ident(id) => id.clone(),
                    _ => {
                        return Err(ParseError::custom(
                            "function name must be an identifier",
                            first_pattern.span,
                        ))
                    }
                };

                Ok(Spanned::new(
                    Item::FunctionDef(FunctionDef {
                        name,
                        params,
                        return_type: None,
                        body: value,
                    }),
                    span,
                ))
            }
        }
    }

    /// Build a lambda expression from parameters and body
    fn build_lambda(&self, params: &[Spanned<Pattern>], body: Spanned<Expr>) -> Spanned<Expr> {
        if params.is_empty() {
            return body;
        }
        let span = params.first().unwrap().span.merge(body.span);
        Spanned::new(
            Expr::Lambda(Lambda {
                params: params.to_vec(),
                body: Box::new(body),
            }),
            span,
        )
    }

    /// Parse import
    fn parse_import(&mut self) -> ParseResult<Spanned<Item>> {
        let start = self.current_span();
        self.expect(&TokenKind::Import, "import")?;

        let items = if self.match_token(&TokenKind::Staccato) {
            if self.match_token(&TokenKind::As) {
                let alias = self.parse_ident()?;
                vec![ImportItem::AllAliased(alias)]
            } else {
                vec![ImportItem::All]
            }
        } else if self.match_token(&TokenKind::LBrace) {
            let mut items = Vec::new();
            loop {
                let name = self.parse_ident()?;
                if self.match_token(&TokenKind::As) {
                    let alias = self.parse_ident()?;
                    items.push(ImportItem::Aliased { name, alias });
                } else {
                    items.push(ImportItem::Named(name));
                }

                if !self.match_token(&TokenKind::Comma) {
                    break;
                }
            }
            self.expect(&TokenKind::RBrace, "}")?;
            items
        } else {
            let name = self.parse_ident()?;
            if self.match_token(&TokenKind::As) {
                let alias = self.parse_ident()?;
                vec![ImportItem::Aliased { name, alias }]
            } else {
                vec![ImportItem::Named(name)]
            }
        };

        self.expect(&TokenKind::From, "from")?;
        let from = match self.current().clone() {
            TokenKind::String(s) => {
                self.advance();
                s
            }
            _ => {
                return Err(ParseError::unexpected_token(
                    "module path string",
                    self.current().clone(),
                    self.current_span(),
                ))
            }
        };

        let span = self.span_from(start);
        Ok(Spanned::new(Item::Import(ImportDecl { items, from }), span))
    }

    /// Parse export
    fn parse_export(&mut self) -> ParseResult<Spanned<Item>> {
        let start = self.current_span();
        self.expect(&TokenKind::Export, "export")?;

        let export = if self.check(&TokenKind::Let) || self.check(&TokenKind::Scale) || self.check(&TokenKind::Chord) {
            let item = self.parse_item()?;
            ExportDecl::Definition(Box::new(item.node))
        } else if self.match_token(&TokenKind::LBrace) {
            let mut names = Vec::new();
            loop {
                names.push(self.parse_ident()?);
                if !self.match_token(&TokenKind::Comma) {
                    break;
                }
            }
            self.expect(&TokenKind::RBrace, "}")?;

            if self.match_token(&TokenKind::From) {
                let from = match self.current().clone() {
                    TokenKind::String(s) => {
                        self.advance();
                        s
                    }
                    _ => {
                        return Err(ParseError::unexpected_token(
                            "module path string",
                            self.current().clone(),
                            self.current_span(),
                        ))
                    }
                };
                ExportDecl::ReExport { items: names, from }
            } else {
                ExportDecl::Named(names)
            }
        } else {
            let mut names = vec![self.parse_ident()?];
            while self.match_token(&TokenKind::Comma) {
                names.push(self.parse_ident()?);
            }
            ExportDecl::Named(names)
        };

        let span = self.span_from(start);
        Ok(Spanned::new(Item::Export(export), span))
    }

    /// Parse interval list
    pub fn parse_interval_list(&mut self) -> ParseResult<Vec<Spanned<IntervalLit>>> {
        let mut intervals = Vec::new();

        loop {
            let start = self.current_span();

            match self.current().clone() {
                TokenKind::Root => {
                    self.advance();
                    intervals.push(Spanned::new(
                        IntervalLit::new(relanote_lexer::token::IntervalQuality::Perfect, 1),
                        start,
                    ));
                }
                TokenKind::Interval(data) => {
                    self.advance();
                    intervals.push(Spanned::new(
                        IntervalLit {
                            quality: data.quality,
                            degree: data.degree,
                            accidentals: data.accidentals,
                        },
                        start,
                    ));
                }
                _ => break,
            }

            if !self.match_token(&TokenKind::Comma) {
                break;
            }
        }

        Ok(intervals)
    }
}
