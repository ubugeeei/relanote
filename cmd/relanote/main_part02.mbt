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
          let bytes = @render.render_to_midi(value)
          write_midi(output_path(args, path), bytes)
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
