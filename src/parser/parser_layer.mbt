///|
fn Parser::parse_layer_expr(
  self : Parser,
  span : @core.Span,
) -> @core.Spanned[@ast.Expr]? {
  let _ = self.advance()
  if !self.eat(@lexer.LBracket) {
    self.error("expected `[` after `layer`")
    return None
  }
  self.skip_newlines()
  let parts : Array[@core.Spanned[@ast.Expr]] = []
  if self.peek_kind() != @lexer.RBracket {
    while true {
      match self.parse_expr() {
        None => return None
        Some(part) => parts.push(part)
      }
      self.skip_newlines()
      if !self.eat(@lexer.Comma) {
        break
      }
      self.skip_newlines()
    }
  }
  if !self.eat(@lexer.RBracket) {
    self.error("expected `]` to close layer")
    return None
  }
  Some(@core.Spanned::new(@ast.Layer(@ast.LayerExpr::new(parts)), span))
}
