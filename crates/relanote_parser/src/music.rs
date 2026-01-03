//! Music-specific parsing

use relanote_ast::*;
use relanote_core::Spanned;
use relanote_lexer::TokenKind;

use crate::error::{ParseError, ParseResult};
use crate::parser::Parser;

impl Parser {
    /// Parse a block: | slot slot slot | or | slot slot slot |:n
    pub fn parse_block(&mut self) -> ParseResult<Spanned<Expr>> {
        let start = self.current_span();
        self.expect(&TokenKind::Pipe, "|")?;

        let mut slots = Vec::new();

        // Skip initial newlines/comments inside block
        self.skip_comments_and_newlines();

        while !self.check(&TokenKind::Pipe) && !self.is_at_end() {
            slots.push(self.parse_slot()?);
            // Skip newlines/comments between slots
            self.skip_comments_and_newlines();
        }

        self.expect(&TokenKind::Pipe, "|")?;

        // Check for optional duration: |...|:n
        let block = if self.check(&TokenKind::Colon) {
            self.advance(); // consume ':'
            match self.current().clone() {
                TokenKind::Integer(n) => {
                    self.advance();
                    Block::with_beats(slots, n as f64)
                }
                TokenKind::Float(f) => {
                    self.advance();
                    Block::with_beats(slots, f)
                }
                _ => {
                    return Err(ParseError::UnexpectedToken {
                        expected: "number for block duration".to_string(),
                        found: self.current().clone(),
                        span: self.current_span(),
                    });
                }
            }
        } else {
            Block::new(slots)
        };

        let span = self.span_from(start);
        Ok(Spanned::new(Expr::Block(block), span))
    }

    /// Parse a single slot
    pub fn parse_slot(&mut self) -> ParseResult<Spanned<Slot>> {
        let start = self.current_span();

        match self.current().clone() {
            TokenKind::Minus => {
                self.advance();
                let duration = self.parse_slot_duration();
                let span = self.span_from(start);
                Ok(Spanned::new(Slot::Rest { duration }, span))
            }

            TokenKind::Root => {
                self.advance();
                let articulations = self.parse_articulations();
                let duration = self.parse_slot_duration();
                let span = self.span_from(start);
                Ok(Spanned::new(
                    Slot::Note {
                        pitch: Spanned::new(Pitch::Root, span),
                        articulations,
                        duration,
                    },
                    span,
                ))
            }

            TokenKind::Interval(data) => {
                self.advance();
                let articulations = self.parse_articulations();
                let duration = self.parse_slot_duration();
                let span = self.span_from(start);
                let interval = IntervalLit {
                    quality: data.quality,
                    degree: data.degree,
                    accidentals: data.accidentals,
                };
                Ok(Spanned::new(
                    Slot::Note {
                        pitch: Spanned::new(Pitch::Interval(interval), span),
                        articulations,
                        duration,
                    },
                    span,
                ))
            }

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
                    let articulations = self.parse_articulations();
                    let duration = self.parse_slot_duration();
                    let span = self.span_from(start);

                    let pitch = if accidentals.is_empty() {
                        Pitch::ScaleIndex(n as u8)
                    } else {
                        Pitch::ScaleIndexMod(n as u8, accidentals)
                    };

                    Ok(Spanned::new(
                        Slot::Note {
                            pitch: Spanned::new(pitch, span),
                            articulations,
                            duration,
                        },
                        span,
                    ))
                } else {
                    Err(ParseError::custom("expected integer in scale index", start))
                }
            }

            TokenKind::LBrace => {
                self.advance();
                let mut contents = Vec::new();

                while !self.check(&TokenKind::RBrace) && !self.is_at_end() {
                    contents.push(self.parse_slot()?);
                }

                self.expect(&TokenKind::RBrace, "}")?;
                self.expect(&TokenKind::Colon, ":")?;

                // Parse target_beats as primary expression only to avoid
                // consuming subsequent slots as part of a comparison expression
                let target_beats = self.parse_primary_expr()?;
                let span = self.span_from(start);

                Ok(Spanned::new(
                    Slot::Tuplet(Tuplet {
                        contents,
                        target_beats: Box::new(target_beats),
                    }),
                    span,
                ))
            }

            TokenKind::LBracket => {
                self.advance();
                let mut pitches = Vec::new();

                while !self.check(&TokenKind::RBracket) && !self.is_at_end() {
                    let pitch_start = self.current_span();
                    let pitch = match self.current().clone() {
                        TokenKind::Root => {
                            self.advance();
                            Pitch::Root
                        }
                        TokenKind::Interval(data) => {
                            self.advance();
                            Pitch::Interval(IntervalLit {
                                quality: data.quality,
                                degree: data.degree,
                                accidentals: data.accidentals,
                            })
                        }
                        _ => {
                            return Err(ParseError::custom("expected pitch in chord", pitch_start))
                        }
                    };
                    pitches.push(Spanned::new(pitch, pitch_start));

                    if !self.check(&TokenKind::RBracket) {
                        self.match_token(&TokenKind::Comma);
                    }
                }

                self.expect(&TokenKind::RBracket, "]")?;
                let articulations = self.parse_articulations();
                let duration = self.parse_slot_duration();
                let span = self.span_from(start);

                Ok(Spanned::new(
                    Slot::Chord {
                        pitches,
                        articulations,
                        duration,
                    },
                    span,
                ))
            }

            _ => Err(ParseError::custom("expected slot", start)),
        }
    }

    /// Parse optional slot duration (:n)
    fn parse_slot_duration(&mut self) -> Option<u32> {
        if self.check(&TokenKind::Colon) {
            self.advance(); // consume ':'
            if let TokenKind::Integer(n) = self.current().clone() {
                self.advance();
                return Some(n as u32);
            }
        }
        None
    }

    /// Parse tuplet as expression
    pub fn parse_tuplet_expr(&mut self) -> ParseResult<Spanned<Expr>> {
        let start = self.current_span();
        self.expect(&TokenKind::LBrace, "{")?;

        let mut contents = Vec::new();
        while !self.check(&TokenKind::RBrace) && !self.is_at_end() {
            contents.push(self.parse_slot()?);
        }

        self.expect(&TokenKind::RBrace, "}")?;
        self.expect(&TokenKind::Colon, ":")?;
        // Parse target_beats as primary expression only to avoid
        // consuming subsequent slots as part of a comparison expression
        let target_beats = self.parse_primary_expr()?;
        let span = self.span_from(start);

        Ok(Spanned::new(
            Expr::Tuplet(Tuplet {
                contents,
                target_beats: Box::new(target_beats),
            }),
            span,
        ))
    }

    /// Parse section
    /// Supports: section "name" body or section "name" { body }
    pub fn parse_section(&mut self) -> ParseResult<Spanned<Expr>> {
        let start = self.current_span();
        self.expect(&TokenKind::Section, "section")?;

        let name = self.parse_primary_expr()?;

        let context = if self.match_token(&TokenKind::With) {
            let mut key = None;
            let mut scale = None;
            let mut tempo = None;

            loop {
                if self.check(&TokenKind::Ident("key".to_string())) || self.check(&TokenKind::Key) {
                    self.advance();
                    self.expect(&TokenKind::Colon, ":")?;
                    key = Some(self.parse_expression()?);
                } else if self.check(&TokenKind::Ident("scale".to_string()))
                    || self.check(&TokenKind::Scale)
                {
                    self.advance();
                    self.expect(&TokenKind::Colon, ":")?;
                    scale = Some(self.parse_expression()?);
                } else if self.check(&TokenKind::Ident("tempo".to_string())) {
                    self.advance();
                    self.expect(&TokenKind::Colon, ":")?;
                    tempo = Some(self.parse_expression()?);
                } else {
                    break;
                }

                if !self.match_token(&TokenKind::Comma) {
                    break;
                }
            }

            Some(SectionContext { key, scale, tempo })
        } else {
            None
        };

        // Support both `section "name" { body }` and `section "name" body`
        let body = if self.match_token(&TokenKind::LBrace) {
            let body = self.parse_expression()?;
            self.expect(&TokenKind::RBrace, "}")?;
            body
        } else {
            self.parse_expression()?
        };

        let span = self.span_from(start);
        Ok(Spanned::new(
            Expr::Section(Box::new(SectionExpr {
                name,
                context,
                body,
            })),
            span,
        ))
    }

    /// Parse layer
    pub fn parse_layer(&mut self) -> ParseResult<Spanned<Expr>> {
        let start = self.current_span();
        self.expect(&TokenKind::Layer, "layer")?;
        self.expect(&TokenKind::LBracket, "[")?;

        let parts = self.parse_list(&TokenKind::RBracket, |p| p.parse_expression())?;

        self.expect(&TokenKind::RBracket, "]")?;
        let span = self.span_from(start);

        Ok(Spanned::new(Expr::Layer(LayerExpr { parts }), span))
    }

    /// Parse part: part "instrument" body or part "instrument" { body }
    /// Also supports: part "instrument" (no body, will get body through pipe)
    pub fn parse_part(&mut self) -> ParseResult<Spanned<Expr>> {
        let start = self.current_span();
        self.expect(&TokenKind::Part, "part")?;

        let instrument = self.parse_primary_expr()?;

        // Check for body: { body }, or expression body, or no body
        let body = if self.match_token(&TokenKind::LBrace) {
            let body_expr = self.parse_expression()?;
            self.expect(&TokenKind::RBrace, "}")?;
            Some(Box::new(body_expr))
        } else if self.can_start_argument() {
            // Support `part "Piano" melody` style (body without braces)
            Some(Box::new(self.parse_primary_expr()?))
        } else {
            None
        };

        let span = self.span_from(start);

        Ok(Spanned::new(
            Expr::Part(PartExpr {
                instrument: Box::new(instrument),
                body,
            }),
            span,
        ))
    }

    /// Parse envelope
    pub fn parse_envelope(&mut self) -> ParseResult<Spanned<Expr>> {
        let start = self.current_span();
        self.expect(&TokenKind::Env, "env")?;
        self.expect(&TokenKind::LParen, "(")?;

        let from = self.parse_expression()?;
        self.expect(&TokenKind::Comma, ",")?;
        let to = self.parse_expression()?;
        self.expect(&TokenKind::Comma, ",")?;
        let duration = self.parse_expression()?;

        self.expect(&TokenKind::RParen, ")")?;
        let span = self.span_from(start);

        Ok(Spanned::new(
            Expr::Envelope(EnvelopeLit {
                from: Box::new(from),
                to: Box::new(to),
                duration: Box::new(duration),
            }),
            span,
        ))
    }

    /// Parse articulation markers
    pub fn parse_articulations(&mut self) -> Vec<Articulation> {
        let mut articulations = Vec::new();

        loop {
            if self.match_token(&TokenKind::Staccato) {
                articulations.push(Articulation::Staccato);
            } else if self.match_token(&TokenKind::Accent) {
                articulations.push(Articulation::Accent);
            } else if self.match_token(&TokenKind::Portamento) {
                articulations.push(Articulation::Portamento);
            } else {
                break;
            }
        }

        articulations
    }
}
