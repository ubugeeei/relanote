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
let USAGE : String =
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
fn run_parse(args : Array[String]) -> Unit {
  match require_file(args) {
    None => ()
    Some(path) => {
      let (program, diagnostics) = @parser.parse_string(path, read_source(path))
      let _ = program
      for d in diagnostics.items() {
        println("[" + d.kind().to_display_string() + "] " + d.message())
      }
    }
  }
}

///|
fn run_check(args : Array[String]) -> Unit {
  match require_file(args) {
    None => ()
    Some(path) => {
      // Type-check skeleton: just parse and report parser diagnostics.
      let (_, diagnostics) = @parser.parse_string(path, read_source(path))
      for d in diagnostics.items() {
        println("[" + d.kind().to_display_string() + "] " + d.message())
      }
    }
  }
}

///|
fn run_fmt(args : Array[String]) -> Unit {
  match require_file(args) {
    None => ()
    Some(path) => {
      let (program, _) = @parser.parse_string(path, read_source(path))
      print(@format.format(program, @format.FormatConfig::default()))
    }
  }
}

///|
fn run_run(args : Array[String]) -> Unit {
  match require_file(args) {
    None => ()
    Some(path) => {
      let (program, _) = @parser.parse_string(path, read_source(path))
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
      let (program, _) = @parser.parse_string(path, read_source(path))
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
