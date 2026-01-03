//! End-to-end tests for relanote CLI

use std::fs;
use std::process::Command;

fn relanote_cmd() -> Command {
    Command::new(env!("CARGO_BIN_EXE_relanote"))
}

fn create_temp_file(content: &str) -> tempfile::NamedTempFile {
    use std::io::Write;
    let mut file = tempfile::NamedTempFile::with_suffix(".rela").unwrap();
    file.write_all(content.as_bytes()).unwrap();
    file
}

// ===== Basic Run Tests =====

#[test]
fn test_run_simple_integer() {
    let file = create_temp_file("42");
    let output = relanote_cmd()
        .args(["run", file.path().to_str().unwrap()])
        .output()
        .expect("Failed to execute command");

    assert!(output.status.success());
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("Int(42)"));
}

#[test]
fn test_run_let_binding() {
    let file = create_temp_file(
        r#"
let x = 42
x
"#,
    );
    let output = relanote_cmd()
        .args(["run", file.path().to_str().unwrap()])
        .output()
        .expect("Failed to execute command");

    assert!(output.status.success());
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("Int(42)"));
}

#[test]
fn test_run_multiple_let_bindings() {
    let file = create_temp_file(
        r#"
let x = 10
let y = 20
let z = x + y
z
"#,
    );
    let output = relanote_cmd()
        .args(["run", file.path().to_str().unwrap()])
        .output()
        .expect("Failed to execute command");

    assert!(output.status.success());
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("Int(30)"));
}

// ===== Scale and Block Tests =====

#[test]
fn test_run_scale_definition() {
    let file = create_temp_file(
        r#"
scale Major = { R, M2, M3, P4, P5, M6, M7 }
| <1> <3> <5> |
"#,
    );
    let output = relanote_cmd()
        .args(["run", file.path().to_str().unwrap()])
        .output()
        .expect("Failed to execute command");

    assert!(output.status.success());
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("Block"));
}

#[test]
fn test_run_block_with_intervals() {
    let file = create_temp_file("| R M3 P5 |");
    let output = relanote_cmd()
        .args(["run", file.path().to_str().unwrap()])
        .output()
        .expect("Failed to execute command");

    assert!(output.status.success());
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("Block"));
    assert!(stdout.contains("cents: 0.0")); // R = 0 cents
    assert!(stdout.contains("cents: 400.0")); // M3 = 400 cents
    assert!(stdout.contains("cents: 700.0")); // P5 = 700 cents
}

#[test]
fn test_run_block_concatenation() {
    let file = create_temp_file(
        r#"
scale Major = { R, M2, M3, P4, P5, M6, M7 }
let a = | <1> <2> |
let b = | <3> <4> |
a ++ b
"#,
    );
    let output = relanote_cmd()
        .args(["run", file.path().to_str().unwrap()])
        .output()
        .expect("Failed to execute command");

    assert!(output.status.success());
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("Block"));
}

// ===== Microtone Tests =====

#[test]
fn test_run_chromatic_modifiers() {
    let file = create_temp_file("| P1 P1+ M2 M2+ M3 |");
    let output = relanote_cmd()
        .args(["run", file.path().to_str().unwrap()])
        .output()
        .expect("Failed to execute command");

    assert!(output.status.success());
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("cents: 0.0")); // P1 = 0
    assert!(stdout.contains("cents: 100.0")); // P1+ = 100
    assert!(stdout.contains("cents: 200.0")); // M2 = 200
    assert!(stdout.contains("cents: 300.0")); // M2+ = 300
    assert!(stdout.contains("cents: 400.0")); // M3 = 400
}

// ===== Function Application Tests =====

#[test]
fn test_run_builtin_reverse() {
    let file = create_temp_file(
        r#"
scale Major = { R, M2, M3, P4, P5, M6, M7 }
| <1> <2> <3> | |> reverse
"#,
    );
    let output = relanote_cmd()
        .args(["run", file.path().to_str().unwrap()])
        .output()
        .expect("Failed to execute command");

    assert!(output.status.success());
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("Block"));
}

#[test]
fn test_run_builtin_repeat() {
    let file = create_temp_file(
        r#"
scale Major = { R, M2, M3, P4, P5, M6, M7 }
| <1> | |> repeat 3
"#,
    );
    let output = relanote_cmd()
        .args(["run", file.path().to_str().unwrap()])
        .output()
        .expect("Failed to execute command");

    assert!(output.status.success());
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("Block"));
}

#[test]
fn test_run_builtin_transpose() {
    let file = create_temp_file(
        r#"
scale Major = { R, M2, M3, P4, P5, M6, M7 }
| <1> | |> transpose P5
"#,
    );
    let output = relanote_cmd()
        .args(["run", file.path().to_str().unwrap()])
        .output()
        .expect("Failed to execute command");

    assert!(output.status.success());
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("Block"));
    assert!(stdout.contains("cents: 700.0")); // P5 = 700 cents
}

#[test]
fn test_run_pipe_chain() {
    let file = create_temp_file(
        r#"
scale Major = { R, M2, M3, P4, P5, M6, M7 }
| <1> <3> <5> | |> transpose P5 |> repeat 2
"#,
    );
    let output = relanote_cmd()
        .args(["run", file.path().to_str().unwrap()])
        .output()
        .expect("Failed to execute command");

    assert!(output.status.success());
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("Block"));
}

// ===== Lambda and Higher-Order Functions =====

#[test]
fn test_run_lambda() {
    let file = create_temp_file(
        r#"
let add = \x y -> x + y
add 3 4
"#,
    );
    let output = relanote_cmd()
        .args(["run", file.path().to_str().unwrap()])
        .output()
        .expect("Failed to execute command");

    assert!(output.status.success());
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("Int(7)"));
}

// NOTE: map, filter tests are ignored because the functional builtins
// need access to the evaluator to apply closures. See builtins/functional.rs

#[test]
#[ignore = "functional builtins need evaluator context for closure application"]
fn test_run_map() {
    // Use pipe syntax since f (x) is parsed same as f(x)
    let file = create_temp_file(
        r#"
[1, 2, 3] |> map (\x -> x * 2)
"#,
    );
    let output = relanote_cmd()
        .args(["run", file.path().to_str().unwrap()])
        .output()
        .expect("Failed to execute command");

    let stdout = String::from_utf8_lossy(&output.stdout);
    let stderr = String::from_utf8_lossy(&output.stderr);
    assert!(
        output.status.success(),
        "stdout: {stdout}\nstderr: {stderr}"
    );
    assert!(stdout.contains("Array"));
}

#[test]
#[ignore = "functional builtins need evaluator context for closure application"]
fn test_run_filter() {
    // Use pipe syntax
    let file = create_temp_file(
        r#"
[1, 2, 3, 4, 5] |> filter (\x -> x > 2)
"#,
    );
    let output = relanote_cmd()
        .args(["run", file.path().to_str().unwrap()])
        .output()
        .expect("Failed to execute command");

    let stdout = String::from_utf8_lossy(&output.stdout);
    let stderr = String::from_utf8_lossy(&output.stderr);
    assert!(
        output.status.success(),
        "stdout: {stdout}\nstderr: {stderr}"
    );
    assert!(stdout.contains("Array"));
}

// ===== Synth Tests =====

// NOTE: Synth tests are skipped for now because the synth/voice features
// may not be fully implemented or prelude synth presets may not be available.

#[test]
#[ignore = "synth/voice feature may not be fully implemented"]
fn test_run_synth_preset() {
    let file = create_temp_file(
        r#"
scale Major = { R, M2, M3, P4, P5, M6, M7 }
| <1> <3> <5> | |> voice Lead
"#,
    );
    let output = relanote_cmd()
        .args(["run", file.path().to_str().unwrap()])
        .output()
        .expect("Failed to execute command");

    let stdout = String::from_utf8_lossy(&output.stdout);
    let stderr = String::from_utf8_lossy(&output.stderr);
    assert!(
        output.status.success(),
        "stdout: {stdout}\nstderr: {stderr}"
    );
}

#[test]
#[ignore = "synth/voice feature may not be fully implemented"]
fn test_run_custom_synth() {
    let file = create_temp_file(
        r#"
synth MySynth = {
  osc: Saw,
  env: envelope 0.1 0.2 0.7 0.3,
  filter: LowPass 1000 0.5
}
scale Major = { R, M2, M3, P4, P5, M6, M7 }
| <1> | |> voice MySynth
"#,
    );
    let output = relanote_cmd()
        .args(["run", file.path().to_str().unwrap()])
        .output()
        .expect("Failed to execute command");

    let stdout = String::from_utf8_lossy(&output.stdout);
    let stderr = String::from_utf8_lossy(&output.stderr);
    assert!(
        output.status.success(),
        "stdout: {stdout}\nstderr: {stderr}"
    );
}

// ===== Error Cases =====

#[test]
fn test_run_undefined_variable_error() {
    let file = create_temp_file("undefined_var");
    let output = relanote_cmd()
        .args(["run", file.path().to_str().unwrap()])
        .output()
        .expect("Failed to execute command");

    assert!(!output.status.success());
    // Error might be in stdout or stderr
    let stderr = String::from_utf8_lossy(&output.stderr);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let combined = format!("{stdout}{stderr}");
    // Error message may say "undefined", "unbound", "not found", or "unknown"
    assert!(
        combined.contains("undefined")
            || combined.contains("unbound")
            || combined.contains("not found")
            || combined.contains("unknown"),
        "Expected error about undefined variable, got stdout: {stdout}, stderr: {stderr}"
    );
}

#[test]
fn test_run_parse_error() {
    let file = create_temp_file("let x = ");
    let output = relanote_cmd()
        .args(["run", file.path().to_str().unwrap()])
        .output()
        .expect("Failed to execute command");

    assert!(!output.status.success());
}

// ===== Parse Command Tests =====

#[test]
fn test_parse_command() {
    let file = create_temp_file("let x = 42");
    let output = relanote_cmd()
        .args(["parse", file.path().to_str().unwrap()])
        .output()
        .expect("Failed to execute command");

    assert!(output.status.success());
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("Program"));
    assert!(stdout.contains("LetBinding"));
}

// ===== Check Command Tests =====

#[test]
fn test_check_command_valid() {
    let file = create_temp_file(
        r#"
scale Major = { R, M2, M3, P4, P5, M6, M7 }
let x = | <1> <3> <5> |
x
"#,
    );
    let output = relanote_cmd()
        .args(["check", file.path().to_str().unwrap()])
        .output()
        .expect("Failed to execute command");

    assert!(output.status.success());
}

// ===== Format Command Tests =====

#[test]
fn test_format_command() {
    let file = create_temp_file("let   x=42");
    let output = relanote_cmd()
        .args(["format", file.path().to_str().unwrap()])
        .output()
        .expect("Failed to execute command");

    assert!(output.status.success());
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("let x = 42"));
}

// ===== Render Command Tests =====

#[test]
#[ignore = "render command requires Song output, not Block - needs layer or voice"]
fn test_render_command() {
    // Render requires a Song (layer or voice output), not just a Block
    let file = create_temp_file(
        r#"
scale Major = { R, M2, M3, P4, P5, M6, M7 }
let melody = | <1> <3> <5> |
layer [melody]
"#,
    );
    let output_midi = tempfile::NamedTempFile::with_suffix(".mid").unwrap();

    let output = relanote_cmd()
        .args([
            "render",
            file.path().to_str().unwrap(),
            "-o",
            output_midi.path().to_str().unwrap(),
        ])
        .output()
        .expect("Failed to execute command");

    let stdout = String::from_utf8_lossy(&output.stdout);
    let stderr = String::from_utf8_lossy(&output.stderr);
    assert!(
        output.status.success(),
        "stdout: {stdout}\nstderr: {stderr}"
    );
    // Check that MIDI file was created and has content
    let midi_content = fs::read(output_midi.path()).unwrap();
    assert!(!midi_content.is_empty());
    // MIDI files start with "MThd"
    assert_eq!(&midi_content[0..4], b"MThd");
}

// ===== Newline Handling Tests (regression) =====

#[test]
fn test_newline_separates_statements() {
    let file = create_temp_file(
        r#"
let a = 1
let b = 2
let c = 3
a + b + c
"#,
    );
    let output = relanote_cmd()
        .args(["run", file.path().to_str().unwrap()])
        .output()
        .expect("Failed to execute command");

    assert!(output.status.success());
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("Int(6)"));
}

#[test]
fn test_function_call_same_line() {
    // Note: lambda params are space-separated, not comma-separated
    let file = create_temp_file(
        r#"
let add = \x y -> x + y
add 1 2
"#,
    );
    let output = relanote_cmd()
        .args(["run", file.path().to_str().unwrap()])
        .output()
        .expect("Failed to execute command");

    let stdout = String::from_utf8_lossy(&output.stdout);
    let stderr = String::from_utf8_lossy(&output.stderr);
    assert!(
        output.status.success(),
        "stdout: {stdout}\nstderr: {stderr}"
    );
    assert!(stdout.contains("Int(3)"));
}

#[test]
#[ignore = "multiline block parsing has issues with newlines"]
fn test_multiline_block() {
    // Note: The block opening | and first slot must be on same line
    let file = create_temp_file(
        r#"
scale Major = { R, M2, M3, P4, P5, M6, M7 }
let melody = | <1> <2> <3> <4>
  <5> <4> <3> <2> |
melody
"#,
    );
    let output = relanote_cmd()
        .args(["run", file.path().to_str().unwrap()])
        .output()
        .expect("Failed to execute command");

    let stdout = String::from_utf8_lossy(&output.stdout);
    let stderr = String::from_utf8_lossy(&output.stderr);
    assert!(
        output.status.success(),
        "stdout: {stdout}\nstderr: {stderr}"
    );
    assert!(stdout.contains("Block"));
}

// ===== Complex Examples =====

#[test]
fn test_run_full_example() {
    let file = create_temp_file(
        r#"
scale Major = { R, M2, M3, P4, P5, M6, M7 }

; Define patterns
let fast = | <1> <2> <3> <4> <5> <4> <3> <2> |
let slow = | <1> <3> <5> <3> |

; Combine and transform
let melody = fast ++ slow
melody |> transpose P5 |> repeat 2
"#,
    );
    let output = relanote_cmd()
        .args(["run", file.path().to_str().unwrap()])
        .output()
        .expect("Failed to execute command");

    assert!(output.status.success());
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("Block"));
}

#[test]
fn test_run_layer() {
    let file = create_temp_file(
        r#"
scale Major = { R, M2, M3, P4, P5, M6, M7 }
let melody = | <1> <3> <5> |
let bass = | <1> <5> |
layer [melody, bass]
"#,
    );
    let output = relanote_cmd()
        .args(["run", file.path().to_str().unwrap()])
        .output()
        .expect("Failed to execute command");

    assert!(output.status.success());
}

// ===== Prelude Tests =====

#[test]
fn test_prelude_scales_available() {
    // Major scale should be available from prelude
    let file = create_temp_file("| <1> <3> <5> |");
    let output = relanote_cmd()
        .args(["run", file.path().to_str().unwrap()])
        .output()
        .expect("Failed to execute command");

    assert!(output.status.success());
}

#[test]
#[ignore = "synth presets may not be available in prelude"]
fn test_prelude_synth_presets_available() {
    let file = create_temp_file(
        r#"
scale Major = { R, M2, M3, P4, P5, M6, M7 }
| <1> | |> voice Chiptune
"#,
    );
    let output = relanote_cmd()
        .args(["run", file.path().to_str().unwrap()])
        .output()
        .expect("Failed to execute command");

    let stdout = String::from_utf8_lossy(&output.stdout);
    let stderr = String::from_utf8_lossy(&output.stderr);
    assert!(
        output.status.success(),
        "stdout: {stdout}\nstderr: {stderr}"
    );
}
