///|
/// Parse a primary expression followed by call / field / index postfixes,
/// including compact space application such as `mix 0.4`.
fn Parser::parse_postfix(self : Parser) -> @core.Spanned[@ast.Expr]? {
  let initial = self.parse_primary()
  match initial {
    None => None
    Some(first) => {
      let mut head = first
      while true {
        match self.peek_kind() {
          @lexer.LParen => {
            let _ = self.advance()
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
            let _ = self.advance()
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
            let _ = self.advance()
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
          kind if can_start_space_argument(kind) => {
            match self.parse_unary() {
              None => return None
              Some(arg) => {
                let span = head.span()
                head = @core.Spanned::new(
                  @ast.Application(@ast.Application::new(head, [arg])),
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
fn can_start_space_argument(kind : @lexer.TokenKind) -> Bool {
  match kind {
    @lexer.Integer(_)
    | @lexer.Float(_)
    | @lexer.StringLit(_)
    | @lexer.True
    | @lexer.False
    | @lexer.Ident(_)
    | @lexer.Interval(_)
    | @lexer.AbsolutePitch(_)
    | @lexer.Root
    | @lexer.LParen
    | @lexer.LBracket => true
    _ => false
  }
}

///|
fn Parser::parse_unary(self : Parser) -> @core.Spanned[@ast.Expr]? {
  let span = self.peek().span()
  match self.peek_kind() {
    @lexer.Minus => {
      let _ = self.advance()
      match self.parse_unary() {
        None => None
        Some(operand) => Some(@core.Spanned::new(
          @ast.Unary(@ast.Unary::new(@ast.Neg, operand)),
          span,
        ))
      }
    }
    @lexer.Bang => {
      let _ = self.advance()
      match self.parse_unary() {
        None => None
        Some(operand) => Some(@core.Spanned::new(
          @ast.Unary(@ast.Unary::new(@ast.Not, operand)),
          span,
        ))
      }
    }
    _ => self.parse_postfix()
  }
}

///|
fn Parser::parse_factor(self : Parser) -> @core.Spanned[@ast.Expr]? {
  let initial = self.parse_unary()
  match initial {
    None => None
    Some(first) => {
      let mut left = first
      while true {
        let op = match self.peek_kind() {
          @lexer.Star => Some(@ast.Mul)
          @lexer.Slash => Some(@ast.Div)
          @lexer.Percent => Some(@ast.Mod)
          _ => None
        }
        match op {
          None => break
          Some(binary_op) => {
            let _ = self.advance()
            self.skip_newlines()
            match self.parse_unary() {
              None => return None
              Some(right) => {
                let span = left.span()
                left = @core.Spanned::new(
                  @ast.Binary(@ast.Binary::new(binary_op, left, right)),
                  span,
                )
              }
            }
          }
        }
      }
      Some(left)
    }
  }
}

///|
fn Parser::parse_term(self : Parser) -> @core.Spanned[@ast.Expr]? {
  let initial = self.parse_factor()
  match initial {
    None => None
    Some(first) => {
      let mut left = first
      while true {
        let op = match self.peek_kind() {
          @lexer.Plus => Some(@ast.Add)
          @lexer.Minus => Some(@ast.Sub)
          _ => None
        }
        match op {
          None => break
          Some(binary_op) => {
            let _ = self.advance()
            self.skip_newlines()
            match self.parse_factor() {
              None => return None
              Some(right) => {
                let span = left.span()
                left = @core.Spanned::new(
                  @ast.Binary(@ast.Binary::new(binary_op, left, right)),
                  span,
                )
              }
            }
          }
        }
      }
      Some(left)
    }
  }
}
