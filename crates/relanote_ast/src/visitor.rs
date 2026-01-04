use relanote_core::Spanned;

use crate::expr::*;
use crate::item::*;
use crate::music::*;
use crate::pattern::*;
use crate::Program;

/// Visitor trait for traversing the AST
pub trait Visitor: Sized {
    /// Called before visiting children of an expression
    fn visit_expr(&mut self, expr: &Spanned<Expr>) {
        walk_expr(self, expr);
    }

    /// Called before visiting children of an item
    fn visit_item(&mut self, item: &Spanned<Item>) {
        walk_item(self, item);
    }

    /// Called before visiting children of a pattern
    fn visit_pattern(&mut self, pattern: &Spanned<Pattern>) {
        walk_pattern(self, pattern);
    }

    /// Visit a program
    fn visit_program(&mut self, program: &Program) {
        for item in &program.items {
            self.visit_item(item);
        }
    }

    /// Visit an identifier
    fn visit_ident(&mut self, _ident: &Ident) {}

    /// Visit a block
    fn visit_block(&mut self, block: &Block) {
        walk_block(self, block);
    }

    /// Visit a slot
    fn visit_slot(&mut self, slot: &Spanned<Slot>) {
        walk_slot(self, slot);
    }
}

/// Walk through expression children
pub fn walk_expr<V: Visitor>(visitor: &mut V, expr: &Spanned<Expr>) {
    match &expr.node {
        Expr::Integer(_) | Expr::Float(_) | Expr::String(_) | Expr::Bool(_) | Expr::Unit => {}

        Expr::Ident(ident) => visitor.visit_ident(ident),

        Expr::Interval(_) | Expr::AbsolutePitch(_) | Expr::Root | Expr::Articulation(_) => {}

        Expr::Block(block) => visitor.visit_block(block),

        Expr::Tuplet(tuplet) => {
            for slot in &tuplet.contents {
                visitor.visit_slot(slot);
            }
            visitor.visit_expr(&tuplet.target_beats);
        }

        Expr::Envelope(env) => {
            visitor.visit_expr(&env.from);
            visitor.visit_expr(&env.to);
            visitor.visit_expr(&env.duration);
        }

        Expr::Part(part) => {
            visitor.visit_expr(&part.instrument);
            if let Some(body) = &part.body {
                visitor.visit_expr(body);
            }
        }

        Expr::Section(section) => {
            visitor.visit_expr(&section.name);
            if let Some(ctx) = &section.context {
                if let Some(key) = &ctx.key {
                    visitor.visit_expr(key);
                }
                if let Some(scale) = &ctx.scale {
                    visitor.visit_expr(scale);
                }
                if let Some(tempo) = &ctx.tempo {
                    visitor.visit_expr(tempo);
                }
            }
            visitor.visit_expr(&section.body);
        }

        Expr::Layer(layer) => {
            for part in &layer.parts {
                visitor.visit_expr(part);
            }
        }

        Expr::Lambda(lambda) => {
            for param in &lambda.params {
                visitor.visit_pattern(param);
            }
            visitor.visit_expr(&lambda.body);
        }

        Expr::Application(app) => {
            visitor.visit_expr(&app.func);
            for arg in &app.args {
                visitor.visit_expr(arg);
            }
        }

        Expr::Pipe(pipe) => {
            visitor.visit_expr(&pipe.left);
            visitor.visit_expr(&pipe.right);
        }

        Expr::Array(elems) | Expr::Tuple(elems) => {
            for elem in elems {
                visitor.visit_expr(elem);
            }
        }

        Expr::Binary(binary) => {
            visitor.visit_expr(&binary.left);
            visitor.visit_expr(&binary.right);
        }

        Expr::Unary(unary) => {
            visitor.visit_expr(&unary.operand);
        }

        Expr::Index(index) => {
            visitor.visit_expr(&index.base);
            visitor.visit_expr(&index.index);
        }

        Expr::Field(field) => {
            visitor.visit_expr(&field.base);
            visitor.visit_ident(&field.field);
        }

        Expr::If(if_expr) => {
            visitor.visit_expr(&if_expr.condition);
            visitor.visit_expr(&if_expr.then_branch);
            if let Some(else_branch) = &if_expr.else_branch {
                visitor.visit_expr(else_branch);
            }
        }

        Expr::Match(match_expr) => {
            visitor.visit_expr(&match_expr.scrutinee);
            for arm in &match_expr.arms {
                visitor.visit_pattern(&arm.pattern);
                if let Some(guard) = &arm.guard {
                    visitor.visit_expr(guard);
                }
                visitor.visit_expr(&arm.body);
            }
        }

        Expr::Let(let_expr) => {
            visitor.visit_pattern(&let_expr.pattern);
            visitor.visit_expr(&let_expr.value);
            visitor.visit_expr(&let_expr.body);
        }

        Expr::With(with_expr) => {
            visitor.visit_expr(&with_expr.base);
            for mod_expr in &with_expr.modifications {
                visitor.visit_expr(mod_expr);
            }
        }

        Expr::InScale(in_scale_expr) => {
            visitor.visit_expr(&in_scale_expr.scale);
        }

        Expr::Annotated(expr, _) | Expr::Paren(expr) => {
            visitor.visit_expr(expr);
        }

        Expr::Error => {}
    }
}

/// Walk through item children
pub fn walk_item<V: Visitor>(visitor: &mut V, item: &Spanned<Item>) {
    match &item.node {
        Item::ScaleDef(scale_def) => {
            visitor.visit_ident(&scale_def.name);
            if let Some(base) = &scale_def.base {
                visitor.visit_expr(base);
            }
        }

        Item::ChordDef(chord_def) => {
            visitor.visit_ident(&chord_def.name);
        }

        Item::SynthDef(synth_def) => {
            visitor.visit_ident(&synth_def.name);
            for prop in &synth_def.properties {
                match &prop.node {
                    crate::music::SynthProperty::Oscillator(expr)
                    | crate::music::SynthProperty::Envelope(expr)
                    | crate::music::SynthProperty::Filter(expr)
                    | crate::music::SynthProperty::Detune(expr)
                    | crate::music::SynthProperty::PitchEnvelope(expr) => {
                        visitor.visit_expr(expr);
                    }
                }
            }
        }

        Item::LetBinding(binding) => {
            visitor.visit_pattern(&binding.pattern);
            visitor.visit_expr(&binding.value);
        }

        Item::SetBinding(binding) => {
            visitor.visit_ident(&binding.name);
            visitor.visit_expr(&binding.value);
        }

        Item::FunctionDef(func_def) => {
            visitor.visit_ident(&func_def.name);
            for param in &func_def.params {
                visitor.visit_pattern(param);
            }
            visitor.visit_expr(&func_def.body);
        }

        Item::Import(_) => {}

        Item::Export(export) => {
            if let ExportDecl::Definition(item) = export {
                let spanned = Spanned::dummy(item.as_ref().clone());
                visitor.visit_item(&spanned);
            }
        }

        Item::Mod(mod_decl) => {
            visitor.visit_ident(&mod_decl.name);
        }

        Item::Use(use_decl) => {
            for segment in &use_decl.path.segments {
                visitor.visit_ident(segment);
            }
            if let crate::item::UseKind::Group(items) = &use_decl.path.kind {
                for item in items {
                    visitor.visit_ident(&item.name);
                    if let Some(alias) = &item.alias {
                        visitor.visit_ident(alias);
                    }
                }
            }
        }

        Item::ExprStmt(expr) => {
            visitor.visit_expr(expr);
        }
    }
}

/// Walk through pattern children
pub fn walk_pattern<V: Visitor>(visitor: &mut V, pattern: &Spanned<Pattern>) {
    match &pattern.node {
        Pattern::Wildcard => {}

        Pattern::Ident(ident) => visitor.visit_ident(ident),

        Pattern::Literal(_) => {}

        Pattern::Tuple(patterns) => {
            for p in patterns {
                visitor.visit_pattern(p);
            }
        }

        Pattern::Array(arr) => {
            for p in &arr.elements {
                visitor.visit_pattern(p);
            }
            if let Some(rest) = &arr.rest {
                visitor.visit_pattern(rest);
            }
        }

        Pattern::Constructor { name, args } => {
            visitor.visit_ident(name);
            for arg in args {
                visitor.visit_pattern(arg);
            }
        }

        Pattern::Or(p1, p2) => {
            visitor.visit_pattern(p1);
            visitor.visit_pattern(p2);
        }

        Pattern::Annotated(p, _) => {
            visitor.visit_pattern(p);
        }
    }
}

/// Walk through block slots
pub fn walk_block<V: Visitor>(visitor: &mut V, block: &Block) {
    for slot in &block.slots {
        visitor.visit_slot(slot);
    }
}

/// Walk through slot contents
pub fn walk_slot<V: Visitor>(visitor: &mut V, slot: &Spanned<Slot>) {
    match &slot.node {
        Slot::Note { .. } | Slot::Rest { .. } | Slot::Chord { .. } => {}
        Slot::Tuplet(tuplet) => {
            for s in &tuplet.contents {
                visitor.visit_slot(s);
            }
            visitor.visit_expr(&tuplet.target_beats);
        }
    }
}

/// Mutable visitor trait for transforming the AST
pub trait MutVisitor: Sized {
    fn visit_expr_mut(&mut self, expr: &mut Spanned<Expr>) {
        walk_expr_mut(self, expr);
    }

    fn visit_item_mut(&mut self, item: &mut Spanned<Item>) {
        walk_item_mut(self, item);
    }

    fn visit_pattern_mut(&mut self, pattern: &mut Spanned<Pattern>) {
        walk_pattern_mut(self, pattern);
    }

    fn visit_program_mut(&mut self, program: &mut Program) {
        for item in &mut program.items {
            self.visit_item_mut(item);
        }
    }
}

pub fn walk_expr_mut<V: MutVisitor>(visitor: &mut V, expr: &mut Spanned<Expr>) {
    match &mut expr.node {
        Expr::Lambda(lambda) => {
            for param in &mut lambda.params {
                visitor.visit_pattern_mut(param);
            }
            visitor.visit_expr_mut(&mut lambda.body);
        }
        Expr::Application(app) => {
            visitor.visit_expr_mut(&mut app.func);
            for arg in &mut app.args {
                visitor.visit_expr_mut(arg);
            }
        }
        Expr::Pipe(pipe) => {
            visitor.visit_expr_mut(&mut pipe.left);
            visitor.visit_expr_mut(&mut pipe.right);
        }
        Expr::Binary(binary) => {
            visitor.visit_expr_mut(&mut binary.left);
            visitor.visit_expr_mut(&mut binary.right);
        }
        Expr::Unary(unary) => {
            visitor.visit_expr_mut(&mut unary.operand);
        }
        Expr::If(if_expr) => {
            visitor.visit_expr_mut(&mut if_expr.condition);
            visitor.visit_expr_mut(&mut if_expr.then_branch);
            if let Some(else_branch) = &mut if_expr.else_branch {
                visitor.visit_expr_mut(else_branch);
            }
        }
        Expr::Let(let_expr) => {
            visitor.visit_pattern_mut(&mut let_expr.pattern);
            visitor.visit_expr_mut(&mut let_expr.value);
            visitor.visit_expr_mut(&mut let_expr.body);
        }
        Expr::Array(elems) | Expr::Tuple(elems) => {
            for elem in elems {
                visitor.visit_expr_mut(elem);
            }
        }
        Expr::Annotated(inner, _) | Expr::Paren(inner) => {
            visitor.visit_expr_mut(inner);
        }
        Expr::InScale(in_scale) => {
            visitor.visit_expr_mut(&mut in_scale.scale);
        }
        // Other cases don't need mutable traversal
        _ => {}
    }
}

pub fn walk_item_mut<V: MutVisitor>(visitor: &mut V, item: &mut Spanned<Item>) {
    match &mut item.node {
        Item::LetBinding(binding) => {
            visitor.visit_pattern_mut(&mut binding.pattern);
            visitor.visit_expr_mut(&mut binding.value);
        }
        Item::FunctionDef(func_def) => {
            for param in &mut func_def.params {
                visitor.visit_pattern_mut(param);
            }
            visitor.visit_expr_mut(&mut func_def.body);
        }
        Item::ExprStmt(expr) => {
            visitor.visit_expr_mut(expr);
        }
        _ => {}
    }
}

pub fn walk_pattern_mut<V: MutVisitor>(visitor: &mut V, pattern: &mut Spanned<Pattern>) {
    match &mut pattern.node {
        Pattern::Tuple(patterns) => {
            for p in patterns {
                visitor.visit_pattern_mut(p);
            }
        }
        Pattern::Array(arr) => {
            for p in &mut arr.elements {
                visitor.visit_pattern_mut(p);
            }
            if let Some(rest) = &mut arr.rest {
                visitor.visit_pattern_mut(rest);
            }
        }
        Pattern::Constructor { args, .. } => {
            for arg in args {
                visitor.visit_pattern_mut(arg);
            }
        }
        Pattern::Or(p1, p2) => {
            visitor.visit_pattern_mut(p1);
            visitor.visit_pattern_mut(p2);
        }
        Pattern::Annotated(p, _) => {
            visitor.visit_pattern_mut(p);
        }
        _ => {}
    }
}
