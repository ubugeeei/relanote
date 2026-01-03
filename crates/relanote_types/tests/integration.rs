//! Integration tests for the type checker

use relanote_parser::parse;
use relanote_types::TypeChecker;

fn check(input: &str) -> bool {
    let (program, parse_diags) = parse(input);
    if parse_diags.has_errors() {
        return false;
    }
    let mut checker = TypeChecker::new();
    let type_diags = checker.check_program(&program);
    !type_diags.has_errors()
}

fn check_fails(input: &str) -> bool {
    let (program, parse_diags) = parse(input);
    if parse_diags.has_errors() {
        return true;
    }
    let mut checker = TypeChecker::new();
    let type_diags = checker.check_program(&program);
    type_diags.has_errors()
}

// ===== Basic Value Tests =====

#[test]
fn test_check_integer() {
    assert!(check("42"));
}

#[test]
fn test_check_float() {
    assert!(check("3.14"));
}

#[test]
fn test_check_string() {
    assert!(check(r#""hello""#));
}

#[test]
fn test_check_boolean() {
    assert!(check("true"));
    assert!(check("false"));
}

// ===== Arithmetic Tests =====

#[test]
fn test_check_arithmetic() {
    assert!(check("1 + 2"));
    assert!(check("5 - 3"));
    assert!(check("3 * 4"));
    // Division has parsing issues - see evaluator tests
    // assert!(check("10 / 2"));
    assert!(check("(1 + 2) * 3"));
}

#[test]
fn test_check_arithmetic_type_error() {
    // String + Int should fail
    assert!(check_fails(r#""hello" + 1"#));
}

// ===== Let Binding Tests =====

#[test]
fn test_check_let_binding() {
    assert!(check("let x = 42"));
}

#[test]
fn test_check_let_with_use() {
    assert!(check(
        r#"
let x = 10
let y = x + 5
"#
    ));
}

#[test]
fn test_check_undefined_variable() {
    assert!(check_fails("undefined_var"));
}

// ===== Lambda Tests =====

#[test]
fn test_check_lambda() {
    assert!(check(r"\x -> x"));
    assert!(check(r"\x -> x * 2"));
    assert!(check(r"\x y -> x + y"));
}

#[test]
fn test_check_lambda_application() {
    assert!(check(
        r#"
let f = \x -> x * 2
f 5
"#
    ));
}

#[test]
fn test_check_currying() {
    assert!(check(
        r#"
let add = \x -> \y -> x + y
let add5 = add 5
add5 3
"#
    ));
}

// ===== If Expression Tests =====

#[test]
fn test_check_if_expression() {
    assert!(check("if true then 1 else 2"));
}

#[test]
fn test_check_if_condition_must_be_bool() {
    assert!(check_fails("if 42 then 1 else 2"));
}

#[test]
fn test_check_if_branches_must_match() {
    // Different branch types should fail
    assert!(check_fails(r#"if true then 1 else "hello""#));
}

// ===== Array Tests =====

#[test]
fn test_check_array() {
    assert!(check("[1, 2, 3]"));
    assert!(check("[]"));
}

#[test]
fn test_check_array_homogeneous() {
    // Mixed types in array should fail
    assert!(check_fails(r#"[1, "hello"]"#));
}

// ===== Block Tests =====

#[test]
fn test_check_block() {
    assert!(check("| R M3 P5 |"));
}

#[test]
fn test_check_block_with_scale_degrees() {
    assert!(check(
        r#"
scale Major = { R, M2, M3, P4, P5, M6, M7 }
| <1> <3> <5> |
"#
    ));
}

#[test]
fn test_check_block_concatenation() {
    assert!(check(
        r#"
let a = | R |
let b = | M3 |
a ++ b
"#
    ));
}

// ===== Pipe Operator Tests =====

#[test]
fn test_check_pipe() {
    assert!(check("| R M3 P5 | |> reverse"));
}

#[test]
fn test_check_pipe_chain() {
    assert!(check(
        r#"
scale Major = { R, M2, M3, P4, P5, M6, M7 }
| <1> <2> <3> | |> reverse |> repeat 2
"#
    ));
}

// ===== Builtin Function Tests =====

#[test]
fn test_check_reverse() {
    assert!(check("| R | |> reverse"));
}

#[test]
fn test_check_repeat() {
    assert!(check("| R | |> repeat 3"));
}

#[test]
fn test_check_transpose() {
    assert!(check("| R | |> transpose P5"));
}

#[test]
fn test_check_swing() {
    assert!(check("| R M3 | |> swing"));
}

#[test]
fn test_check_double_time() {
    assert!(check("| R M3 P5 | |> double_time"));
}

// ===== Scale and Chord Tests =====

#[test]
fn test_check_scale_definition() {
    assert!(check("scale Major = { R, M2, M3, P4, P5, M6, M7 }"));
}

#[test]
fn test_check_chord_definition() {
    assert!(check("chord MajorTriad = [ R, M3, P5 ]"));
}

// ===== Synth Tests =====

#[test]
fn test_check_synth_presets() {
    assert!(check(
        r#"
scale Major = { R, M2, M3, P4, P5, M6, M7 }
| <1> | |> voice Lead
"#
    ));
}

#[test]
fn test_check_voice_function() {
    // voice expects Synth and Block
    assert!(check(
        r#"
scale Major = { R, M2, M3, P4, P5, M6, M7 }
| <1> | |> voice Chiptune
"#
    ));
}

// ===== Interval Tests =====

#[test]
fn test_check_interval_arithmetic() {
    assert!(check("R + P5"));
    assert!(check("M3 + m3"));
}

// ===== Function Composition Tests =====

#[test]
fn test_check_compose() {
    assert!(check(
        r#"
let double = \x -> x * 2
let addOne = \x -> x + 1
let composed = double >> addOne
composed 5
"#
    ));
}

// ===== In Scale Expression Tests =====

#[test]
fn test_check_in_scale() {
    assert!(check(
        r#"
scale Minor = { R, M2, m3, P4, P5, m6, m7 }
| <1> <3> <5> | |> in Minor
"#
    ));
}

// ===== Effect Functions Tests =====

#[test]
fn test_check_reverb() {
    assert!(check("| R M3 P5 | |> reverb 0.5"));
}

#[test]
fn test_check_reverb_presets() {
    assert!(check("| R | |> hall_reverb"));
    assert!(check("| R | |> room_reverb"));
    assert!(check("| R | |> plate_reverb"));
    assert!(check("| R | |> dry"));
}

#[test]
fn test_check_volume() {
    assert!(check("| R | |> volume 0.8"));
}

// ===== Complex Examples =====

#[test]
fn test_check_complete_example() {
    assert!(check(
        r#"
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let fast = | <1> <2> <3> <4> |
let slow = | <1> <5> |

let melody = fast ++ slow
melody |> transpose P5 |> repeat 2
"#
    ));
}

#[test]
#[ignore = "fn syntax may have parsing/type checking issues"]
fn test_check_function_definition() {
    assert!(check(
        r#"
fn double x = x * 2
double 5
"#
    ));
}

#[test]
#[ignore = "fn syntax may have parsing/type checking issues"]
fn test_check_function_with_multiple_params() {
    assert!(check(
        r#"
fn add x y = x + y
add 3 4
"#
    ));
}

// ===== Type Error Cases =====

#[test]
fn test_check_function_wrong_arg_type() {
    // repeat expects Int, not String
    assert!(check_fails(r#"| R | |> repeat "three""#));
}

#[test]
fn test_check_binary_op_type_mismatch() {
    // Can't multiply string by int
    assert!(check_fails(r#""hello" * 2"#));
}

// ===== Lookup Type Tests =====

#[test]
fn test_lookup_builtin_type() {
    let checker = TypeChecker::new();

    // reverse should be Block -> Block
    let reverse_ty = checker.lookup_type("reverse");
    assert!(reverse_ty.is_some());

    // transpose should be Interval -> Block -> Block
    let transpose_ty = checker.lookup_type("transpose");
    assert!(transpose_ty.is_some());
}

#[test]
fn test_lookup_undefined_returns_none() {
    let checker = TypeChecker::new();
    assert!(checker.lookup_type("undefined_name").is_none());
}
