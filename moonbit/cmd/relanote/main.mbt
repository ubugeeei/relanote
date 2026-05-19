///|
/// Entry point for the MoonBit port of `relanote_cli`. The Rust CLI is
/// built on `clap`; this port hand-rolls argument parsing because clap
/// has no MoonBit equivalent. The skeleton wires up each subcommand to
/// its corresponding library entry point so the downstream library ports
/// have a real consumer.
///
/// Subcommands match the Rust CLI:
///   parse <file>     — parse a `.rela` file and report diagnostics
///   check <file>     — type-check a `.rela` file (currently no-op)
///   fmt   <file>     — format and print to stdout
///   run   <file>     — evaluate the program (skeleton returns Unit)
///   render <file>    — render to MIDI bytes (skeleton emits nothing)
///   lsp              — start the LSP server (skeleton is a no-op)
///
/// Tracked in #13.
fn main {
  let args = @env.args()
  if args.length() < 2 {
    println(USAGE)
    return
  }
  match args[1] {
    "parse" => run_parse(args)
    "check" => run_check(args)
    "fmt" => run_fmt(args)
    "run" => run_run(args)
    "render" => run_render(args)
    "lsp" => run_lsp()
    "--help" | "-h" | "help" => println(USAGE)
    other => {
      println("unknown subcommand: " + other)
      println(USAGE)
    }
  }
}

///|
const USAGE : String =
  #|relanote — A pure functional music notation language
  #|
  #|USAGE:
  #|    relanote <SUBCOMMAND> [ARGS...]
  #|
  #|SUBCOMMANDS:
  #|    parse <FILE>     Parse a .rela file and display the AST
  #|    check <FILE>     Type-check a .rela file
  #|    fmt   <FILE>     Format the file and print to stdout
  #|    run   <FILE>     Evaluate the program
  #|    render <FILE>    Render to MIDI on stdout
  #|    lsp              Start the LSP server on stdio
  #|    help             Show this message

///|
fn require_file(args : Array[String]) -> String? {
  if args.length() < 3 {
    println("missing input file")
    println(USAGE)
    return None
  }
  Some(args[2])
}

///|
fn read_source(path : String) -> String {
  // TODO(#13): platform-specific fs read once a uniform IO backend lands.
  let _ = path
  ""
}

///|
/// Build a `@core.Source` from the on-disk file and print every
/// diagnostic against that source through the ariadne-style reporter.
fn print_diagnostics(
  source : @core.Source,
  diagnostics : @core.Diagnostics,
) -> Unit {
  for d in diagnostics.items() {
    println(@core.render_diagnostic(d, source))
  }
}

///|
/// Same shape as `print_diagnostics`, but for the type checker which
/// hands back a plain `Array[TypeError]` rather than a `Diagnostics`.
fn print_type_errors(
  source : @core.Source,
  errors : Array[@types.TypeError],
) -> Unit {
  for err in errors {
    let d = @core.Diagnostic::error(err.message(), err.span())
    println(@core.render_diagnostic(d, source))
  }
}

///|
/// Test-only helper that builds an empty source and runs the type
/// checker, returning the error array. Kept here so the wbtest
/// suite can keep its old signature.
fn run_type_check_for_test(program : @ast.Program) -> Array[@types.TypeError] {
  let source = @core.Source::from_string("<test>", "")
  run_type_check(source, program)
}

///|
/// Run a relanote source string through the parse → type-check →
/// evaluate pipeline and return its final value. Returns
/// `Err(message)` when any phase fails, so integration tests can
/// assert on either side of the pipeline.
fn pipeline_for_test(source : String) -> Result[@eval.Value, String] {
  let src = @core.Source::from_string("<test>", source)
  let (program, parse_diags) = @parser.parse_source(src)
  if parse_diags.has_errors() {
    return Err("parse error")
  }
  let checker = @types.TypeChecker::new()
  if checker.check_program(program).length() > 0 {
    return Err("type error")
  }
  let evaluator = @eval.Evaluator::new()
  match evaluator.eval_program(program) {
    Ok(v) => Ok(v)
    Err(e) => Err("runtime error: " + e.message())
  }
}

///|
fn run_parse(args : Array[String]) -> Unit {
  match require_file(args) {
    None => ()
    Some(path) => {
      let source = @core.Source::from_string(path, read_source(path))
      let (program, diagnostics) = @parser.parse_source(source)
      let _ = program
      print_diagnostics(source, diagnostics)
    }
  }
}

///|
fn run_check(args : Array[String]) -> Unit {
  match require_file(args) {
    None => ()
    Some(path) => {
      let source = @core.Source::from_string(path, read_source(path))
      let (program, parse_diags) = @parser.parse_source(source)
      let had_parse_errors = parse_diags.has_errors()
      print_diagnostics(source, parse_diags)
      if had_parse_errors {
        return
      }
      let type_errors = run_type_check(source, program)
      if type_errors.length() == 0 && !had_parse_errors {
        println("No errors found.")
      }
    }
  }
}

///|
/// Run the type checker over `program` and print any errors using
/// the ariadne-style reporter. Returns the error list so callers can
/// decide whether to short-circuit downstream phases.
fn run_type_check(
  source : @core.Source,
  program : @ast.Program,
) -> Array[@types.TypeError] {
  let checker = @types.TypeChecker::new()
  let errors = checker.check_program(program)
  print_type_errors(source, errors)
  errors
}

///|
fn run_fmt(args : Array[String]) -> Unit {
  match require_file(args) {
    None => ()
    Some(path) => {
      let source = @core.Source::from_string(path, read_source(path))
      let (program, _) = @parser.parse_source(source)
      println(@format.format(program, @format.FormatConfig::default()))
    }
  }
}

///|
fn run_run(args : Array[String]) -> Unit {
  match require_file(args) {
    None => ()
    Some(path) => {
      let source = @core.Source::from_string(path, read_source(path))
      let (program, parse_diags) = @parser.parse_source(source)
      if parse_diags.has_errors() {
        print_diagnostics(source, parse_diags)
        return
      }
      let type_errors = run_type_check(source, program)
      if type_errors.length() > 0 {
        return
      }
      let evaluator = @eval.Evaluator::new()
      match evaluator.eval_program(program) {
        Ok(_) => ()
        Err(err) => println("eval error: " + err.message())
      }
    }
  }
}

///|
fn run_render(args : Array[String]) -> Unit {
  match require_file(args) {
    None => ()
    Some(path) => {
      let source = @core.Source::from_string(path, read_source(path))
      let (program, parse_diags) = @parser.parse_source(source)
      if parse_diags.has_errors() {
        print_diagnostics(source, parse_diags)
        return
      }
      let type_errors = run_type_check(source, program)
      if type_errors.length() > 0 {
        return
      }
      let evaluator = @eval.Evaluator::new()
      match evaluator.eval_program(program) {
        Ok(value) => {
          let _ = @render.render_to_midi(value)
          ()
        }
        Err(err) => println("eval error: " + err.message())
      }
    }
  }
}

///|
fn run_lsp() -> Unit {
  @lsp.run_server()
}
