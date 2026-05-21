///|
/// Parse left-associative block concatenation. This intentionally keeps
/// the first binary tier narrow: `++` is the operator the docs preview
/// needs for audible phrase examples.
fn Parser::parse_concat(self : Parser) -> @core.Spanned[@ast.Expr]? {
  let initial = self.parse_postfix()
  match initial {
    None => None
    Some(first) => {
      let mut left = first
      while self.peek_kind() == @lexer.PlusPlus {
        let _ = self.advance()
        match self.parse_postfix() {
          None => return None
          Some(right) => {
            let span = left.span()
            let binary = @ast.Binary::new(@ast.Concat, left, right)
            left = @core.Spanned::new(@ast.Binary(binary), span)
          }
        }
      }
      Some(left)
    }
  }
}
