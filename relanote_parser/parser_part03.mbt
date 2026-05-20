///|
fn Parser::parse_expr(self : Parser) -> @core.Spanned[@ast.Expr]? {
  // Pipe (`|>`) is the lowest-precedence operator wired today. Each
  // pipe segment is `parse_postfix`, which handles `expr(args)`
  // application calls so `arg |> f(x)` parses naturally.
  let initial = self.parse_postfix()
  match initial {
    None => None
    Some(first) => {
      let mut left = first
      while self.peek_kind() == @lexer.PipeOp {
        let _ = self.advance()
        match self.parse_postfix() {
          None => return None
          Some(right) => {
            let span = left.span()
            let pipe = @ast.Pipe::new(left, right)
            left = @core.Spanned::new(@ast.Pipe(pipe), span)
          }
        }
      }
      Some(left)
    }
  }
}

///|
/// Parse a primary expression followed by zero or more postfix call
/// applications `expr(args, ...)`. Mirrors `parse_postfix_expr` in the
/// legacy implementation — the Haskell-style space-separated form lands in a
/// follow-up because it needs the full `can_start_argument` analysis.
fn Parser::parse_postfix(self : Parser) -> @core.Spanned[@ast.Expr]? {
  let initial = self.parse_primary()
  match initial {
    None => None
    Some(first) => {
      let mut head = first
      while true {
        match self.peek_kind() {
          @lexer.LParen => {
            let _ = self.advance() // `(`
            let args : Array[@core.Spanned[@ast.Expr]] = []
            if self.peek_kind() != @lexer.RParen {
              while true {
                match self.parse_expr() {
                  None => return None
                  Some(arg) => args.push(arg)
                }
                if !self.eat(@lexer.Comma) {
                  break
                }
              }
            }
            if !self.eat(@lexer.RParen) {
              self.error("expected `)` to close call arguments")
              return None
            }
            let span = head.span()
            head = @core.Spanned::new(
              @ast.Application(@ast.Application::new(head, args)),
              span,
            )
          }
          @lexer.Dot => {
            let _ = self.advance() // `.`
            match self.parse_ident_token() {
              None => {
                self.error("expected an identifier after `.`")
                return None
              }
              Some(field_name) => {
                let span = head.span()
                head = @core.Spanned::new(
                  @ast.Field(@ast.Field::new(head, field_name)),
                  span,
                )
              }
            }
          }
          @lexer.LBracket => {
            let _ = self.advance() // `[`
            match self.parse_expr() {
              None => return None
              Some(index) => {
                if !self.eat(@lexer.RBracket) {
                  self.error("expected `]` to close index expression")
                  return None
                }
                let span = head.span()
                head = @core.Spanned::new(
                  @ast.Index(@ast.Index::new(head, index)),
                  span,
                )
              }
            }
          }
          _ => break
        }
      }
      Some(head)
    }
  }
}

///|
fn Parser::parse_primary(self : Parser) -> @core.Spanned[@ast.Expr]? {
  let span = self.peek().span()
  match self.peek_kind() {
    @lexer.Integer(n) => {
      let _ = self.advance()
      Some(@core.Spanned::new(@ast.Integer(n.to_int64()), span))
    }
    @lexer.Float(f) => {
      let _ = self.advance()
      Some(@core.Spanned::new(@ast.Float(f), span))
    }
    @lexer.StringLit(s) => {
      let _ = self.advance()
      Some(@core.Spanned::new(@ast.StringLit(s), span))
    }
    @lexer.True => {
      let _ = self.advance()
      Some(@core.Spanned::new(@ast.BoolLit(true), span))
    }
    @lexer.False => {
      let _ = self.advance()
      Some(@core.Spanned::new(@ast.BoolLit(false), span))
    }
    @lexer.Ident(name) => {
      let _ = self.advance()
      Some(@core.Spanned::new(@ast.Ident(@ast.Ident::new(name)), span))
    }
    @lexer.Interval(data) => {
      let _ = self.advance()
      let iv = @ast.IntervalLit::new(data.quality(), data.degree()).with_accidentals(
        data.accidentals(),
      )
      Some(@core.Spanned::new(@ast.Interval(iv), span))
    }
    @lexer.AbsolutePitch(data) => {
      let _ = self.advance()
      let ap = @ast.AbsolutePitchLit::from_data(data)
      Some(@core.Spanned::new(@ast.AbsolutePitch(ap), span))
    }
    @lexer.Root => {
      let _ = self.advance()
      Some(@core.Spanned::new(@ast.Root, span))
    }
    @lexer.LParen => {
      let _ = self.advance()
      if self.peek_kind() == @lexer.RParen {
        let _ = self.advance()
        Some(@core.Spanned::new(@ast.UnitLit, span))
      } else {
        match self.parse_expr() {
          None => None
          Some(first) =>
            if self.eat(@lexer.Comma) {
              // `(a, b, ...)` → tuple literal.
              let elements : Array[@core.Spanned[@ast.Expr]] = [first]
              while self.peek_kind() != @lexer.RParen && !self.at_eof() {
                match self.parse_expr() {
                  None => return None
                  Some(elem) => elements.push(elem)
                }
                if !self.eat(@lexer.Comma) {
                  break
                }
              }
              if !self.eat(@lexer.RParen) {
                self.error("expected `)` to close tuple")
              }
              Some(@core.Spanned::new(@ast.Tuple(elements), span))
            } else {
              if !self.eat(@lexer.RParen) {
                self.error("expected `)`")
              }
              Some(@core.Spanned::new(@ast.Paren(first), span))
            }
        }
      }
    }
    @lexer.LBracket => {
      let _ = self.advance()
      let elements : Array[@core.Spanned[@ast.Expr]] = []
      if self.peek_kind() != @lexer.RBracket {
        while true {
          match self.parse_expr() {
            None => return None
            Some(elem) => elements.push(elem)
          }
          if !self.eat(@lexer.Comma) {
            break
          }
        }
      }
      if !self.eat(@lexer.RBracket) {
        self.error("expected `]` to close array literal")
        return None
      }
      Some(@core.Spanned::new(@ast.Array(elements), span))
    }
    @lexer.Pipe => self.parse_block_expr(span)
    @lexer.Lambda => self.parse_lambda_expr(span)
    @lexer.If => self.parse_if_expr(span)
    @lexer.Let => self.parse_let_expr(span)
    @lexer.Match => self.parse_match_expr(span)
    _ => {
      self.error("expected an expression")
      None
    }
  }
}

///|
/// Parse `match scrutinee { pat -> body, pat -> body }`. Each arm
/// supports an optional guard: `pat if cond -> body`. The body
/// expression is parsed via the top-level `parse_expr`, so a body
/// containing commas needs to be parenthesised.
