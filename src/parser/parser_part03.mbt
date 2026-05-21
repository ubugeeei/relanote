///|
fn Parser::parse_expr(self : Parser) -> @core.Spanned[@ast.Expr]? {
  // Pipe (`|>`) is the lowest-precedence operator wired today. Each
  // pipe segment is `parse_concat`, which handles block concatenation
  // over postfix calls so `a ++ b |> reverse` parses naturally.
  // application calls so `arg |> f(x)` parses naturally.
  let initial = self.parse_concat()
  match initial {
    None => None
    Some(first) => {
      let mut left = first
      while self.peek_kind() == @lexer.PipeOp {
        let _ = self.advance()
        self.skip_newlines()
        match self.parse_concat() {
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
    @lexer.Layer => self.parse_layer_expr(span)
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
