//! Integration tests for the parser

use relanote_ast::*;
use relanote_core::Source;
use relanote_parser::Parser;

fn parse(input: &str) -> Program {
    let source = Source::from_string("test", input.to_string());
    let parser = Parser::new(&source);
    let (program, diagnostics) = parser.parse_program();
    if diagnostics.has_errors() {
        panic!("Parse errors: {:?}", diagnostics.iter().collect::<Vec<_>>());
    }
    program
}

fn parse_with_errors(input: &str) -> (Program, bool) {
    let source = Source::from_string("test", input.to_string());
    let parser = Parser::new(&source);
    let (program, diagnostics) = parser.parse_program();
    (program, diagnostics.has_errors())
}

// ===== Basic Expression Tests =====

#[test]
fn test_parse_integer() {
    let program = parse("42");
    assert_eq!(program.items.len(), 1);
    match &program.items[0].node {
        Item::ExprStmt(expr) => match &expr.node {
            Expr::Integer(n) => assert_eq!(*n, 42),
            _ => panic!("Expected Integer"),
        },
        _ => panic!("Expected ExprStmt"),
    }
}

#[test]
fn test_parse_float() {
    let program = parse("3.14");
    assert_eq!(program.items.len(), 1);
    match &program.items[0].node {
        Item::ExprStmt(expr) => match &expr.node {
            Expr::Float(n) => assert!((n - 3.14).abs() < 0.001),
            _ => panic!("Expected Float"),
        },
        _ => panic!("Expected ExprStmt"),
    }
}

#[test]
fn test_parse_string() {
    let program = parse(r#""hello""#);
    assert_eq!(program.items.len(), 1);
    match &program.items[0].node {
        Item::ExprStmt(expr) => match &expr.node {
            Expr::String(s) => assert_eq!(s, "hello"),
            _ => panic!("Expected String"),
        },
        _ => panic!("Expected ExprStmt"),
    }
}

#[test]
fn test_parse_boolean() {
    let program = parse("true");
    match &program.items[0].node {
        Item::ExprStmt(expr) => match &expr.node {
            Expr::Bool(b) => assert!(*b),
            _ => panic!("Expected Bool"),
        },
        _ => panic!("Expected ExprStmt"),
    }

    let program = parse("false");
    match &program.items[0].node {
        Item::ExprStmt(expr) => match &expr.node {
            Expr::Bool(b) => assert!(!*b),
            _ => panic!("Expected Bool"),
        },
        _ => panic!("Expected ExprStmt"),
    }
}

// ===== Let Binding Tests =====

#[test]
fn test_parse_let_binding() {
    let program = parse("let x = 42");
    assert_eq!(program.items.len(), 1);
    match &program.items[0].node {
        Item::LetBinding(binding) => {
            match &binding.pattern.node {
                Pattern::Ident(ident) => assert_eq!(ident.name.as_str(), "x"),
                _ => panic!("Expected Ident pattern"),
            }
            match &binding.value.node {
                Expr::Integer(n) => assert_eq!(*n, 42),
                _ => panic!("Expected Integer value"),
            }
        }
        _ => panic!("Expected LetBinding"),
    }
}

#[test]
fn test_parse_multiple_let_bindings() {
    let program = parse(
        r#"
let x = 1
let y = 2
let z = 3
"#,
    );
    assert_eq!(program.items.len(), 3);
    for item in &program.items {
        assert!(matches!(item.node, Item::LetBinding(_)));
    }
}

#[test]
fn test_parse_let_with_reference() {
    let program = parse(
        r#"
let x = 42
x
"#,
    );
    assert_eq!(program.items.len(), 2);
    match &program.items[0].node {
        Item::LetBinding(_) => {}
        _ => panic!("Expected LetBinding"),
    }
    match &program.items[1].node {
        Item::ExprStmt(expr) => match &expr.node {
            Expr::Ident(ident) => assert_eq!(ident.name.as_str(), "x"),
            _ => panic!("Expected Ident"),
        },
        _ => panic!("Expected ExprStmt"),
    }
}

// ===== Scale Definition Tests =====

#[test]
fn test_parse_scale_definition() {
    let program = parse("scale Major = { R, M2, M3, P4, P5, M6, M7 }");
    assert_eq!(program.items.len(), 1);
    match &program.items[0].node {
        Item::ScaleDef(scale) => {
            assert_eq!(scale.name.name.as_str(), "Major");
            assert_eq!(scale.intervals.len(), 7);
        }
        _ => panic!("Expected ScaleDef"),
    }
}

// ===== Chord Definition Tests =====

#[test]
fn test_parse_chord_definition() {
    let program = parse("chord MajorTriad = [ R, M3, P5 ]");
    assert_eq!(program.items.len(), 1);
    match &program.items[0].node {
        Item::ChordDef(chord) => {
            assert_eq!(chord.name.name.as_str(), "MajorTriad");
            assert_eq!(chord.intervals.len(), 3);
        }
        _ => panic!("Expected ChordDef"),
    }
}

// ===== Block Tests =====

#[test]
fn test_parse_block_with_intervals() {
    let program = parse("| R M3 P5 |");
    assert_eq!(program.items.len(), 1);
    match &program.items[0].node {
        Item::ExprStmt(expr) => match &expr.node {
            Expr::Block(block) => {
                assert_eq!(block.slots.len(), 3);
            }
            _ => panic!("Expected Block"),
        },
        _ => panic!("Expected ExprStmt"),
    }
}

#[test]
fn test_parse_block_with_scale_degrees() {
    let program = parse("| <1> <3> <5> |");
    assert_eq!(program.items.len(), 1);
    match &program.items[0].node {
        Item::ExprStmt(expr) => match &expr.node {
            Expr::Block(block) => {
                assert_eq!(block.slots.len(), 3);
            }
            _ => panic!("Expected Block"),
        },
        _ => panic!("Expected ExprStmt"),
    }
}

#[test]
fn test_parse_block_with_rest() {
    let program = parse("| R - M3 |");
    assert_eq!(program.items.len(), 1);
    match &program.items[0].node {
        Item::ExprStmt(expr) => match &expr.node {
            Expr::Block(block) => {
                assert_eq!(block.slots.len(), 3);
                assert!(matches!(block.slots[1].node, Slot::Rest { .. }));
            }
            _ => panic!("Expected Block"),
        },
        _ => panic!("Expected ExprStmt"),
    }
}

#[test]
fn test_parse_block_with_duration() {
    let program = parse("| R:2 M3:4 |");
    assert_eq!(program.items.len(), 1);
    match &program.items[0].node {
        Item::ExprStmt(expr) => match &expr.node {
            Expr::Block(block) => {
                assert_eq!(block.slots.len(), 2);
            }
            _ => panic!("Expected Block"),
        },
        _ => panic!("Expected ExprStmt"),
    }
}

#[test]
fn test_parse_multiline_block() {
    let program = parse(
        r#"|
  R M3 P5
  P4 M3 R
|"#,
    );
    assert_eq!(program.items.len(), 1);
    match &program.items[0].node {
        Item::ExprStmt(expr) => match &expr.node {
            Expr::Block(block) => {
                assert_eq!(block.slots.len(), 6);
            }
            _ => panic!("Expected Block"),
        },
        _ => panic!("Expected ExprStmt"),
    }
}

// ===== Binary Operation Tests =====

#[test]
fn test_parse_addition() {
    let program = parse("1 + 2");
    match &program.items[0].node {
        Item::ExprStmt(expr) => match &expr.node {
            Expr::Binary(binary) => {
                assert!(matches!(binary.op, BinaryOp::Add));
            }
            _ => panic!("Expected Binary"),
        },
        _ => panic!("Expected ExprStmt"),
    }
}

#[test]
fn test_parse_concatenation() {
    let program = parse("a ++ b");
    match &program.items[0].node {
        Item::ExprStmt(expr) => match &expr.node {
            Expr::Binary(binary) => {
                assert!(matches!(binary.op, BinaryOp::Concat));
            }
            _ => panic!("Expected Binary"),
        },
        _ => panic!("Expected ExprStmt"),
    }
}

#[test]
fn test_parse_pipe() {
    let program = parse("x |> f");
    match &program.items[0].node {
        Item::ExprStmt(expr) => match &expr.node {
            Expr::Pipe(_) => {
                // Pipe is a separate expression type, not a BinaryOp
            }
            _ => panic!("Expected Pipe"),
        },
        _ => panic!("Expected ExprStmt"),
    }
}

// ===== Lambda Tests =====

#[test]
fn test_parse_lambda() {
    let program = parse(r"\x -> x");
    match &program.items[0].node {
        Item::ExprStmt(expr) => match &expr.node {
            Expr::Lambda(lambda) => {
                assert_eq!(lambda.params.len(), 1);
            }
            _ => panic!("Expected Lambda"),
        },
        _ => panic!("Expected ExprStmt"),
    }
}

#[test]
fn test_parse_lambda_multiple_params() {
    let program = parse(r"\x y z -> x + y + z");
    match &program.items[0].node {
        Item::ExprStmt(expr) => match &expr.node {
            Expr::Lambda(lambda) => {
                assert_eq!(lambda.params.len(), 3);
            }
            _ => panic!("Expected Lambda"),
        },
        _ => panic!("Expected ExprStmt"),
    }
}

// ===== Function Application Tests =====

#[test]
fn test_parse_function_call_parens() {
    let program = parse("f(x)");
    match &program.items[0].node {
        Item::ExprStmt(expr) => match &expr.node {
            Expr::Application(app) => {
                assert_eq!(app.args.len(), 1);
            }
            _ => panic!("Expected Application"),
        },
        _ => panic!("Expected ExprStmt"),
    }
}

#[test]
fn test_parse_haskell_style_application() {
    let program = parse("f x y z");
    match &program.items[0].node {
        Item::ExprStmt(expr) => match &expr.node {
            Expr::Application(app) => {
                assert_eq!(app.args.len(), 3);
            }
            _ => panic!("Expected Application"),
        },
        _ => panic!("Expected ExprStmt"),
    }
}

#[test]
fn test_parse_haskell_style_no_cross_line() {
    // f and x should be separate statements due to newline
    let program = parse("f\nx");
    assert_eq!(program.items.len(), 2);
    match &program.items[0].node {
        Item::ExprStmt(expr) => match &expr.node {
            Expr::Ident(ident) => assert_eq!(ident.name.as_str(), "f"),
            _ => panic!("Expected Ident"),
        },
        _ => panic!("Expected ExprStmt"),
    }
    match &program.items[1].node {
        Item::ExprStmt(expr) => match &expr.node {
            Expr::Ident(ident) => assert_eq!(ident.name.as_str(), "x"),
            _ => panic!("Expected Ident"),
        },
        _ => panic!("Expected ExprStmt"),
    }
}

// ===== If Expression Tests =====

#[test]
fn test_parse_if_expression() {
    let program = parse("if true then 1 else 2");
    match &program.items[0].node {
        Item::ExprStmt(expr) => match &expr.node {
            Expr::If(if_expr) => {
                assert!(matches!(if_expr.condition.node, Expr::Bool(true)));
            }
            _ => panic!("Expected If"),
        },
        _ => panic!("Expected ExprStmt"),
    }
}

// ===== Synth Definition Tests =====

#[test]
fn test_parse_synth_definition() {
    let program = parse(
        r#"synth Lead = {
  osc: Saw,
  env: envelope 0.1 0.2 0.7 0.3
}"#,
    );
    match &program.items[0].node {
        Item::SynthDef(synth) => {
            assert_eq!(synth.name.name.as_str(), "Lead");
        }
        _ => panic!("Expected SynthDef"),
    }
}

// ===== Array Tests =====

#[test]
fn test_parse_array() {
    let program = parse("[1, 2, 3]");
    match &program.items[0].node {
        Item::ExprStmt(expr) => match &expr.node {
            Expr::Array(arr) => {
                assert_eq!(arr.len(), 3);
            }
            _ => panic!("Expected Array"),
        },
        _ => panic!("Expected ExprStmt"),
    }
}

// ===== Comment Tests =====

#[test]
fn test_parse_with_comments() {
    let program = parse(
        r#"
; This is a comment
let x = 42 ; inline comment
x
"#,
    );
    assert_eq!(program.items.len(), 2);
}

// ===== Error Case Tests =====

#[test]
fn test_parse_error_unclosed_block() {
    let (_, has_errors) = parse_with_errors("| R M3");
    assert!(has_errors);
}

#[test]
fn test_parse_error_unclosed_paren() {
    let (_, has_errors) = parse_with_errors("f(x");
    assert!(has_errors);
}

#[test]
fn test_parse_error_missing_expression() {
    let (_, has_errors) = parse_with_errors("let x =");
    assert!(has_errors);
}

// ===== Complex Expression Tests =====

#[test]
fn test_parse_pipe_chain() {
    let program = parse("x |> f |> g |> h");
    match &program.items[0].node {
        Item::ExprStmt(expr) => {
            // Pipe is its own AST node, not a Binary operator
            // Should be left-associative: ((x |> f) |> g) |> h
            assert!(matches!(expr.node, Expr::Pipe(_)));
        }
        _ => panic!("Expected ExprStmt"),
    }
}

#[test]
fn test_parse_complex_block_expression() {
    let program = parse(
        r#"
scale Major = { R, M2, M3, P4, P5, M6, M7 }
let melody = | <1> <3> <5> |
melody |> transpose P5 |> repeat 2
"#,
    );
    assert_eq!(program.items.len(), 3);
}

// ===== Set Binding Tests =====

#[test]
fn test_parse_set_key() {
    let program = parse("set key = C4");
    match &program.items[0].node {
        Item::SetBinding(binding) => {
            assert_eq!(binding.name.name.as_str(), "key");
        }
        _ => panic!("Expected SetBinding"),
    }
}

#[test]
fn test_parse_set_tempo() {
    let program = parse("set tempo = 120");
    match &program.items[0].node {
        Item::SetBinding(binding) => {
            assert_eq!(binding.name.name.as_str(), "tempo");
        }
        _ => panic!("Expected SetBinding"),
    }
}

// ===== Layer Tests =====

#[test]
fn test_parse_layer() {
    let program = parse("layer [a, b, c]");
    match &program.items[0].node {
        Item::ExprStmt(expr) => match &expr.node {
            Expr::Layer(layer) => {
                assert_eq!(layer.parts.len(), 3);
            }
            _ => panic!("Expected Layer"),
        },
        _ => panic!("Expected ExprStmt"),
    }
}
