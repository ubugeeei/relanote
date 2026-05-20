///|
fn Parser::parse_match_expr(
  self : Parser,
  start : @core.Span,
) -> @core.Spanned[@ast.Expr]? {
  let _ = self.advance() // `match`
  let scrutinee = match self.parse_expr() {
    None => return None
    Some(s) => s
  }
  if !self.eat(@lexer.LBrace) {
    self.error("expected `{` after match scrutinee")
    return None
  }
  let arms : Array[@ast.MatchArm] = []
  while self.peek_kind() != @lexer.RBrace && !self.at_eof() {
    let pattern = match self.parse_pattern() {
      None => return None
      Some(p) => p
    }
    let guard_expr = if self.peek_kind() == @lexer.If {
      let _ = self.advance()
      match self.parse_expr() {
        None => return None
        Some(g) => Some(g)
      }
    } else {
      None
    }
    if !self.eat(@lexer.Arrow) {
      self.error("expected `->` in match arm")
      return None
    }
    let body = match self.parse_expr() {
      None => return None
      Some(b) => b
    }
    arms.push(@ast.MatchArm::new(pattern, guard_expr, body))
    if !self.eat(@lexer.Comma) {
      break
    }
  }
  if !self.eat(@lexer.RBrace) {
    self.error("expected `}` to close match")
    return None
  }
  Some(
    @core.Spanned::new(@ast.Match(@ast.MatchExpr::new(scrutinee, arms)), start),
  )
}

///|
/// Parse `let pat = value in body` — the expression form, distinct
/// from the top-level `let pat = value` binding (which doesn't have
/// an `in` body).
fn Parser::parse_let_expr(
  self : Parser,
  start : @core.Span,
) -> @core.Spanned[@ast.Expr]? {
  let _ = self.advance() // `let`
  let pattern = match self.parse_pattern() {
    None => return None
    Some(p) => p
  }
  if !self.eat(@lexer.Equals) {
    self.error("expected `=` in let expression")
    return None
  }
  let value = match self.parse_expr() {
    None => return None
    Some(v) => v
  }
  if !self.eat(@lexer.In) {
    self.error("expected `in` in let expression")
    return None
  }
  let body = match self.parse_expr() {
    None => return None
    Some(b) => b
  }
  Some(
    @core.Spanned::new(
      @ast.Let(@ast.LetExpr::new(pattern, None, value, body)),
      start,
    ),
  )
}

///|
/// Parse `if cond then a` or `if cond then a else b`.
/// `else` is optional in the AST so the parser also accepts the
/// bare form (matching the legacy implementation).
fn Parser::parse_if_expr(
  self : Parser,
  start : @core.Span,
) -> @core.Spanned[@ast.Expr]? {
  let _ = self.advance() // `if`
  let cond = match self.parse_expr() {
    None => return None
    Some(c) => c
  }
  if !self.eat(@lexer.Then) {
    self.error("expected `then` after if condition")
    return None
  }
  let then_branch = match self.parse_expr() {
    None => return None
    Some(t) => t
  }
  let else_branch = if self.peek_kind() == @lexer.Else {
    let _ = self.advance()
    match self.parse_expr() {
      None => return None
      Some(e) => Some(e)
    }
  } else {
    None
  }
  Some(
    @core.Spanned::new(
      @ast.If(@ast.IfExpr::new(cond, then_branch, else_branch)),
      start,
    ),
  )
}

///|
/// Parse a lambda literal — `\pat -> expr` or `\p1 p2 -> expr`.
fn Parser::parse_lambda_expr(
  self : Parser,
  start : @core.Span,
) -> @core.Spanned[@ast.Expr]? {
  let _ = self.advance() // `\`
  let params : Array[@core.Spanned[@ast.Pattern]] = []
  while self.peek_kind() != @lexer.Arrow && !self.at_eof() {
    match self.parse_pattern() {
      None => return None
      Some(p) => params.push(p)
    }
  }
  if !self.eat(@lexer.Arrow) {
    self.error("expected `->` in lambda")
    return None
  }
  if params.length() == 0 {
    self.error("lambda needs at least one parameter")
    return None
  }
  match self.parse_expr() {
    None => None
    Some(body) =>
      Some(
        @core.Spanned::new(@ast.Lambda(@ast.Lambda::new(params, body)), start),
      )
  }
}

///|
/// Parse `| slot slot ... |` and an optional `:n` beats annotation.
fn Parser::parse_block_expr(
  self : Parser,
  start : @core.Span,
) -> @core.Spanned[@ast.Expr]? {
  let _ = self.advance() // opening `|`
  let slots : Array[@core.Spanned[@ast.Slot]] = []
  while self.peek_kind() != @lexer.Pipe && !self.at_eof() {
    match self.parse_slot() {
      Some(slot) => slots.push(slot)
      None => break
    }
  }
  if !self.eat(@lexer.Pipe) {
    self.error("expected closing `|`")
    return None
  }
  // Optional `:n` beats annotation.
  let block = if self.eat(@lexer.Colon) {
    match self.peek_kind() {
      @lexer.Integer(n) => {
        let _ = self.advance()
        @ast.Block::with_beats(slots, n.to_double())
      }
      @lexer.Float(f) => {
        let _ = self.advance()
        @ast.Block::with_beats(slots, f)
      }
      _ => {
        self.error("expected a beat count after `:`")
        @ast.Block::new(slots)
      }
    }
  } else {
    @ast.Block::new(slots)
  }
  Some(@core.Spanned::new(@ast.Block(block), start))
}

///|
