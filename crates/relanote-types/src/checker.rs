use relanote_ast::*;
use relanote_core::{intern, Diagnostic, Diagnostics};

use crate::context::TypeContext;
use crate::error::TypeError;
use crate::types::{Type, TypeScheme};

/// Type checker for relanote programs
pub struct TypeChecker {
    ctx: TypeContext,
    diagnostics: Diagnostics,
}

impl TypeChecker {
    pub fn new() -> Self {
        let mut checker = Self {
            ctx: TypeContext::new(),
            diagnostics: Diagnostics::new(),
        };
        checker.add_builtins();
        checker
    }

    /// Add built-in functions to the context
    fn add_builtins(&mut self) {
        // reverse : Block -> Block
        self.ctx.bind(
            intern("reverse"),
            TypeScheme::mono(Type::function(Type::Block, Type::Block)),
        );

        // transpose : Interval -> Block -> Block
        self.ctx.bind(
            intern("transpose"),
            TypeScheme::mono(Type::function_n(
                vec![Type::Interval, Type::Block],
                Type::Block,
            )),
        );

        // repeat : Int -> Block -> Block
        self.ctx.bind(
            intern("repeat"),
            TypeScheme::mono(Type::function_n(
                vec![Type::Int, Type::Block],
                Type::Block,
            )),
        );

        // map : (a -> b) -> [a] -> [b]
        let a = self.ctx.fresh_var();
        let b = self.ctx.fresh_var();
        self.ctx.bind(
            intern("map"),
            TypeScheme::mono(Type::function_n(
                vec![Type::function(a.clone(), b.clone()), Type::array(a)],
                Type::array(b),
            )),
        );

        // compose : [Section] -> Song
        self.ctx.bind(
            intern("compose"),
            TypeScheme::mono(Type::function(
                Type::array(Type::Section),
                Type::Song,
            )),
        );

        // play : Block -> Part -> Part
        self.ctx.bind(
            intern("play"),
            TypeScheme::mono(Type::function_n(
                vec![Type::Block, Type::Part],
                Type::Part,
            )),
        );

        // apply_env : Envelope -> Part -> Part
        self.ctx.bind(
            intern("apply_env"),
            TypeScheme::mono(Type::function_n(
                vec![Type::Envelope, Type::Part],
                Type::Part,
            )),
        );

        // render : Song -> () -> ()
        self.ctx.bind(
            intern("render"),
            TypeScheme::mono(Type::function_n(
                vec![Type::Song, Type::Unit],
                Type::Unit,
            )),
        );
    }

    /// Type check a program
    pub fn check_program(&mut self, program: &Program) -> Diagnostics {
        for item in &program.items {
            if let Err(err) = self.check_item(item) {
                self.diagnostics.add(Diagnostic::error(
                    err.to_string(),
                    err.span(),
                ));
            }
        }

        std::mem::take(&mut self.diagnostics)
    }

    /// Type check an item
    fn check_item(&mut self, item: &relanote_core::Spanned<Item>) -> Result<(), TypeError> {
        match &item.node {
            Item::ScaleDef(scale_def) => {
                self.ctx.bind(
                    scale_def.name.name,
                    TypeScheme::mono(Type::Scale),
                );
                Ok(())
            }

            Item::ChordDef(chord_def) => {
                self.ctx.bind(
                    chord_def.name.name,
                    TypeScheme::mono(Type::Chord),
                );
                Ok(())
            }

            Item::LetBinding(binding) => {
                let value_ty = self.ctx.infer_expr(&binding.value)?;
                let scheme = self.ctx.generalize(&value_ty);

                if let Pattern::Ident(ident) = &binding.pattern.node {
                    self.ctx.bind(ident.name, scheme);
                }

                Ok(())
            }

            Item::FunctionDef(func_def) => {
                self.ctx.push_scope();

                let mut param_types = Vec::new();
                for param in &func_def.params {
                    let param_ty = self.ctx.fresh_var();
                    if let Pattern::Ident(ident) = &param.node {
                        self.ctx.bind_mono(ident.name, param_ty.clone());
                    }
                    param_types.push(param_ty);
                }

                let body_ty = self.ctx.infer_expr(&func_def.body)?;
                self.ctx.pop_scope();

                let func_ty = Type::function_n(param_types, body_ty);
                let scheme = self.ctx.generalize(&func_ty);
                self.ctx.bind(func_def.name.name, scheme);

                Ok(())
            }

            Item::Import(_) => Ok(()),
            Item::Export(_) => Ok(()),

            Item::ExprStmt(expr) => {
                self.ctx.infer_expr(expr)?;
                Ok(())
            }
        }
    }
}

impl Default for TypeChecker {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use relanote_parser::parse;

    use super::*;

    #[test]
    fn test_check_let_binding() {
        let (program, parse_diags) = parse("let x = 42");
        assert!(!parse_diags.has_errors());

        let mut checker = TypeChecker::new();
        let type_diags = checker.check_program(&program);
        assert!(!type_diags.has_errors(), "Type errors: {:?}", type_diags);
    }

    #[test]
    fn test_check_lambda() {
        let (program, parse_diags) = parse("let f = \\x -> x");
        assert!(!parse_diags.has_errors());

        let mut checker = TypeChecker::new();
        let type_diags = checker.check_program(&program);
        assert!(!type_diags.has_errors(), "Type errors: {:?}", type_diags);
    }

    #[test]
    fn test_check_block() {
        let (program, parse_diags) = parse("let motif = | R M3 P5 |");
        assert!(!parse_diags.has_errors());

        let mut checker = TypeChecker::new();
        let type_diags = checker.check_program(&program);
        assert!(!type_diags.has_errors(), "Type errors: {:?}", type_diags);
    }
}
