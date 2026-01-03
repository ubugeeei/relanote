use relanote_ast::*;
use relanote_core::Spanned;

use crate::context::TypeContext;
use crate::error::TypeError;
use crate::types::Type;

impl TypeContext {
    /// Infer the type of an expression
    pub fn infer_expr(&mut self, expr: &Spanned<Expr>) -> Result<Type, TypeError> {
        match &expr.node {
            // Literals
            Expr::Integer(_) => Ok(Type::Int),
            Expr::Float(_) => Ok(Type::Float),
            Expr::String(_) => Ok(Type::String),
            Expr::Bool(_) => Ok(Type::Bool),
            Expr::Unit => Ok(Type::Unit),

            // Identifiers
            Expr::Ident(ident) => {
                if let Some(scheme) = self.lookup(&ident.name).cloned() {
                    Ok(self.instantiate(&scheme))
                } else {
                    Err(TypeError::UndefinedVariable {
                        name: ident.name.to_string(),
                        span: expr.span,
                    })
                }
            }

            // Music primitives
            Expr::Interval(_) => Ok(Type::Interval),
            Expr::AbsolutePitch(_) => Ok(Type::Interval),
            Expr::Root => Ok(Type::Interval),
            Expr::Articulation(_) => Ok(Type::Articulation),
            Expr::Block(_) => Ok(Type::Block),
            Expr::Tuplet(_) => Ok(Type::Block),
            Expr::Envelope(_) => Ok(Type::Envelope),
            Expr::Part(_) => Ok(Type::Part),
            Expr::Section(_) => Ok(Type::Section),
            Expr::Layer(_) => Ok(Type::Section),

            // Lambda
            Expr::Lambda(lambda) => {
                self.push_scope();

                let mut param_types = Vec::new();
                for param in &lambda.params {
                    let param_ty = self.fresh_var();
                    if let Pattern::Ident(ident) = &param.node {
                        self.bind_mono(ident.name, param_ty.clone());
                    }
                    param_types.push(param_ty);
                }

                let body_ty = self.infer_expr(&lambda.body)?;
                self.pop_scope();

                Ok(Type::function_n(param_types, body_ty))
            }

            // Application
            Expr::Application(app) => {
                let func_ty = self.infer_expr(&app.func)?;
                let mut result_ty = func_ty;

                for arg in &app.args {
                    let arg_ty = self.infer_expr(arg)?;
                    let ret_ty = self.fresh_var();

                    self.unify(
                        &result_ty,
                        &Type::function(arg_ty, ret_ty.clone()),
                        expr.span,
                    )?;

                    result_ty = self.apply(&ret_ty);
                }

                Ok(result_ty)
            }

            // Pipe
            Expr::Pipe(pipe) => {
                let arg_ty = self.infer_expr(&pipe.left)?;
                let func_ty = self.infer_expr(&pipe.right)?;
                let ret_ty = self.fresh_var();

                self.unify(&func_ty, &Type::function(arg_ty, ret_ty.clone()), expr.span)?;

                Ok(self.apply(&ret_ty))
            }

            // Binary operators
            Expr::Binary(binary) => {
                let left_ty = self.infer_expr(&binary.left)?;
                let right_ty = self.infer_expr(&binary.right)?;

                match binary.op {
                    BinaryOp::Add | BinaryOp::Sub => {
                        // Allow both Int and Interval arithmetic
                        let left_applied = self.apply(&left_ty);
                        let right_applied = self.apply(&right_ty);

                        // If either side is Interval, unify both to Interval
                        if matches!(left_applied, Type::Interval)
                            || matches!(right_applied, Type::Interval)
                        {
                            self.unify(&left_ty, &Type::Interval, expr.span)?;
                            self.unify(&right_ty, &Type::Interval, expr.span)?;
                            Ok(Type::Interval)
                        } else {
                            // Default to Int arithmetic
                            self.unify(&left_ty, &Type::Int, expr.span)?;
                            self.unify(&right_ty, &Type::Int, expr.span)?;
                            Ok(Type::Int)
                        }
                    }
                    BinaryOp::Mul | BinaryOp::Div => {
                        self.unify(&left_ty, &Type::Int, expr.span)?;
                        self.unify(&right_ty, &Type::Int, expr.span)?;
                        Ok(Type::Int)
                    }
                    BinaryOp::Eq
                    | BinaryOp::Ne
                    | BinaryOp::Lt
                    | BinaryOp::Le
                    | BinaryOp::Gt
                    | BinaryOp::Ge => {
                        self.unify(&left_ty, &right_ty, expr.span)?;
                        Ok(Type::Bool)
                    }
                    BinaryOp::And | BinaryOp::Or => {
                        self.unify(&left_ty, &Type::Bool, expr.span)?;
                        self.unify(&right_ty, &Type::Bool, expr.span)?;
                        Ok(Type::Bool)
                    }
                    BinaryOp::Concat => {
                        self.unify(&left_ty, &right_ty, expr.span)?;
                        Ok(left_ty)
                    }
                    BinaryOp::Mod => {
                        self.unify(&left_ty, &Type::Int, expr.span)?;
                        self.unify(&right_ty, &Type::Int, expr.span)?;
                        Ok(Type::Int)
                    }
                    BinaryOp::Compose => {
                        // Function composition: f >> g means \x -> g(f(x))
                        // If f: A -> B and g: B -> C, then f >> g: A -> C
                        let a = self.fresh_var();
                        let b = self.fresh_var();
                        let c = self.fresh_var();

                        let f_ty = Type::function(a.clone(), b.clone());
                        let g_ty = Type::function(b, c.clone());

                        self.unify(&left_ty, &f_ty, expr.span)?;
                        self.unify(&right_ty, &g_ty, expr.span)?;

                        Ok(Type::function(a, c))
                    }
                }
            }

            // Unary operators
            Expr::Unary(unary) => {
                let operand_ty = self.infer_expr(&unary.operand)?;

                match unary.op {
                    UnaryOp::Neg => {
                        self.unify(&operand_ty, &Type::Int, expr.span)?;
                        Ok(Type::Int)
                    }
                    UnaryOp::Not => {
                        self.unify(&operand_ty, &Type::Bool, expr.span)?;
                        Ok(Type::Bool)
                    }
                }
            }

            // Array
            Expr::Array(elements) => {
                let elem_ty = self.fresh_var();
                for elem in elements {
                    let ty = self.infer_expr(elem)?;
                    self.unify(&elem_ty, &ty, elem.span)?;
                }
                Ok(Type::array(self.apply(&elem_ty)))
            }

            // Tuple
            Expr::Tuple(elements) => {
                let types: Result<Vec<_>, _> =
                    elements.iter().map(|e| self.infer_expr(e)).collect();
                Ok(Type::Tuple(types?))
            }

            // Index
            Expr::Index(index) => {
                let base_ty = self.infer_expr(&index.base)?;
                let index_ty = self.infer_expr(&index.index)?;

                // Check if base is an array or a scale
                let elem_ty = self.fresh_var();

                // Try array indexing
                if let Type::Array(inner) = self.apply(&base_ty) {
                    self.unify(&index_ty, &Type::Int, expr.span)?;
                    return Ok((*inner).clone());
                }

                // Try scale indexing
                if let Type::Scale = self.apply(&base_ty) {
                    self.unify(&index_ty, &Type::Int, expr.span)?;
                    return Ok(Type::Interval);
                }

                // Generic case
                self.unify(&base_ty, &Type::array(elem_ty.clone()), expr.span)?;
                self.unify(&index_ty, &Type::Int, expr.span)?;
                Ok(self.apply(&elem_ty))
            }

            // If expression
            Expr::If(if_expr) => {
                let cond_ty = self.infer_expr(&if_expr.condition)?;
                self.unify(&cond_ty, &Type::Bool, if_expr.condition.span)?;

                let then_ty = self.infer_expr(&if_expr.then_branch)?;

                if let Some(else_branch) = &if_expr.else_branch {
                    let else_ty = self.infer_expr(else_branch)?;
                    self.unify(&then_ty, &else_ty, expr.span)?;
                }

                Ok(self.apply(&then_ty))
            }

            // Let expression
            Expr::Let(let_expr) => {
                let value_ty = self.infer_expr(&let_expr.value)?;

                self.push_scope();
                if let Pattern::Ident(ident) = &let_expr.pattern.node {
                    let scheme = self.generalize(&value_ty);
                    self.bind(ident.name, scheme);
                }

                let body_ty = self.infer_expr(&let_expr.body)?;
                self.pop_scope();

                Ok(body_ty)
            }

            // With expression
            Expr::With(with_expr) => {
                let base_ty = self.infer_expr(&with_expr.base)?;
                // With expressions return the same type as the base
                Ok(base_ty)
            }

            // Field access
            Expr::Field(_) => {
                // Simplified: return a fresh type variable
                Ok(self.fresh_var())
            }

            // Match expression
            Expr::Match(match_expr) => {
                let scrutinee_ty = self.infer_expr(&match_expr.scrutinee)?;
                let result_ty = self.fresh_var();

                for arm in &match_expr.arms {
                    // Check pattern matches scrutinee type
                    let pattern_ty = self.infer_pattern(&arm.pattern)?;
                    self.unify(&scrutinee_ty, &pattern_ty, arm.pattern.span)?;

                    // Check guard if present
                    if let Some(guard) = &arm.guard {
                        let guard_ty = self.infer_expr(guard)?;
                        self.unify(&guard_ty, &Type::Bool, guard.span)?;
                    }

                    // Infer body type
                    let body_ty = self.infer_expr(&arm.body)?;
                    self.unify(&result_ty, &body_ty, arm.body.span)?;
                }

                Ok(self.apply(&result_ty))
            }

            // Parenthesized or annotated
            Expr::Paren(inner) => self.infer_expr(inner),
            Expr::Annotated(inner, _) => self.infer_expr(inner),

            // In scale expression - returns a function Block -> Block
            Expr::InScale(in_scale) => {
                self.infer_expr(&in_scale.scale)?;
                // in Scale returns a function that transforms blocks
                Ok(Type::function(Type::Block, Type::Block))
            }

            // Error recovery
            Expr::Error => Ok(Type::Error),
        }
    }

    /// Infer the type of a pattern
    fn infer_pattern(&mut self, pattern: &Spanned<Pattern>) -> Result<Type, TypeError> {
        match &pattern.node {
            Pattern::Wildcard => Ok(self.fresh_var()),
            Pattern::Ident(ident) => {
                let ty = self.fresh_var();
                self.bind_mono(ident.name, ty.clone());
                Ok(ty)
            }
            Pattern::Literal(lit) => match lit {
                LiteralPattern::Integer(_) => Ok(Type::Int),
                LiteralPattern::Float(_) => Ok(Type::Float),
                LiteralPattern::String(_) => Ok(Type::String),
                LiteralPattern::Bool(_) => Ok(Type::Bool),
                LiteralPattern::Unit => Ok(Type::Unit),
            },
            Pattern::Tuple(patterns) => {
                let types: Result<Vec<_>, _> =
                    patterns.iter().map(|p| self.infer_pattern(p)).collect();
                Ok(Type::Tuple(types?))
            }
            Pattern::Array(arr) => {
                let elem_ty = self.fresh_var();
                for p in &arr.elements {
                    let ty = self.infer_pattern(p)?;
                    self.unify(&elem_ty, &ty, p.span)?;
                }
                Ok(Type::array(self.apply(&elem_ty)))
            }
            Pattern::Constructor { .. } => {
                // Simplified: return a fresh type variable
                Ok(self.fresh_var())
            }
            Pattern::Or(p1, _) => self.infer_pattern(p1),
            Pattern::Annotated(p, _) => self.infer_pattern(p),
        }
    }
}
