///|
/// Evaluation errors. Mirrors `eval::error::EvalError` — every
/// variant and field name is kept identical so future ports of the
/// evaluator can match patterns verbatim.
pub(all) enum EvalError {
  UndefinedVariable(name~ : String, span~ : @core.Span)
  TypeError(expected~ : String, found~ : String, span~ : @core.Span)
  DivisionByZero(span~ : @core.Span)
  IndexOutOfBounds(index~ : Int64, len~ : Int, span~ : @core.Span)
  NotAFunction(span~ : @core.Span)
  WrongArity(expected~ : Int, got~ : Int, span~ : @core.Span)
  ModuleNotFound(module_name~ : String, path~ : String, reason~ : String)
  CircularModuleDependency(module_name~ : String)
  Custom(message~ : String, span~ : @core.Span)
}

///|
pub fn EvalError::span(self : EvalError) -> @core.Span? {
  match self {
    UndefinedVariable(span~, ..) => Some(span)
    TypeError(span~, ..) => Some(span)
    DivisionByZero(span~) => Some(span)
    IndexOutOfBounds(span~, ..) => Some(span)
    NotAFunction(span~) => Some(span)
    WrongArity(span~, ..) => Some(span)
    ModuleNotFound(_) => None
    CircularModuleDependency(_) => None
    Custom(span~, ..) => Some(span)
  }
}

///|
pub fn EvalError::message(self : EvalError) -> String {
  match self {
    UndefinedVariable(name~, ..) => "undefined variable: " + name
    TypeError(expected~, found~, ..) =>
      "type error: expected " + expected + ", found " + found
    DivisionByZero(_) => "division by zero"
    IndexOutOfBounds(index~, len~, ..) =>
      "index out of bounds: " +
      index.to_string() +
      " in array of length " +
      len.to_string()
    NotAFunction(_) => "not a function"
    WrongArity(expected~, got~, ..) =>
      "wrong number of arguments: expected " +
      expected.to_string() +
      ", got " +
      got.to_string()
    ModuleNotFound(module_name~, path~, reason~) =>
      "module not found: " + module_name + " at " + path + ": " + reason
    CircularModuleDependency(module_name~) =>
      "circular module dependency: " + module_name
    Custom(message~, ..) => message
  }
}
