//! Pretty printer for relanote AST

use relanote_ast::*;
use relanote_core::Spanned;

use crate::config::FormatConfig;

/// Formatter for relanote code
pub struct Formatter {
    config: FormatConfig,
    output: String,
    indent_level: usize,
    comments: Vec<Comment>,
    comment_idx: usize,
}

impl Formatter {
    pub fn new(config: FormatConfig) -> Self {
        Self {
            config,
            output: String::new(),
            indent_level: 0,
            comments: Vec::new(),
            comment_idx: 0,
        }
    }

    pub fn format_program(&mut self, program: &Program) -> String {
        // Sort comments by position
        self.comments = program.comments.clone();
        self.comments.sort_by_key(|c| c.span.start);

        for (i, item) in program.items.iter().enumerate() {
            // Print comments that come before this item
            self.print_comments_before(item.span.start);

            if i > 0 && !self.output.ends_with('\n') {
                self.output.push('\n');
            }
            self.format_item(item);
            self.output.push('\n');
        }

        // Print any remaining comments at the end
        while self.comment_idx < self.comments.len() {
            self.output.push_str(&self.comments[self.comment_idx].text);
            self.output.push('\n');
            self.comment_idx += 1;
        }

        std::mem::take(&mut self.output)
    }

    fn print_comments_before(&mut self, pos: usize) {
        while self.comment_idx < self.comments.len() {
            if self.comments[self.comment_idx].span.start < pos {
                let text = self.comments[self.comment_idx].text.clone();
                self.indent();
                self.output.push_str(&text);
                self.output.push('\n');
                self.comment_idx += 1;
            } else {
                break;
            }
        }
    }

    fn indent(&mut self) {
        for _ in 0..(self.indent_level * self.config.indent_size) {
            self.output.push(' ');
        }
    }

    fn format_item(&mut self, item: &Spanned<Item>) {
        self.indent();
        match &item.node {
            Item::ScaleDef(scale) => {
                self.output.push_str("scale ");
                self.output.push_str(scale.name.name.as_ref());
                self.output.push_str(" = ");

                if let Some(base) = &scale.base {
                    self.format_expr(base);
                    self.output.push_str(" with ");
                }

                self.output.push_str("{ ");
                for (i, interval) in scale.intervals.iter().enumerate() {
                    if i > 0 {
                        self.output.push_str(", ");
                    }
                    self.format_interval(&interval.node);
                }
                self.output.push_str(" }");
            }

            Item::ChordDef(chord) => {
                self.output.push_str("chord ");
                self.output.push_str(chord.name.name.as_ref());
                self.output.push_str(" = [ ");
                for (i, interval) in chord.intervals.iter().enumerate() {
                    if i > 0 {
                        self.output.push_str(", ");
                    }
                    self.format_interval(&interval.node);
                }
                self.output.push_str(" ]");
            }

            Item::SynthDef(synth) => {
                self.output.push_str("synth ");
                self.output.push_str(synth.name.name.as_ref());
                self.output.push_str(" = { ");
                for (i, prop) in synth.properties.iter().enumerate() {
                    if i > 0 {
                        self.output.push_str(", ");
                    }
                    match &prop.node {
                        relanote_ast::music::SynthProperty::Oscillator(expr) => {
                            self.output.push_str("osc: ");
                            self.format_expr(expr);
                        }
                        relanote_ast::music::SynthProperty::Envelope(expr) => {
                            self.output.push_str("env: ");
                            self.format_expr(expr);
                        }
                        relanote_ast::music::SynthProperty::Filter(expr) => {
                            self.output.push_str("filter: ");
                            self.format_expr(expr);
                        }
                        relanote_ast::music::SynthProperty::Detune(expr) => {
                            self.output.push_str("detune: ");
                            self.format_expr(expr);
                        }
                    }
                }
                self.output.push_str(" }");
            }

            Item::LetBinding(binding) => {
                self.output.push_str("let ");
                self.format_pattern(&binding.pattern);
                self.output.push_str(" = ");
                self.format_expr(&binding.value);
            }

            Item::SetBinding(binding) => {
                self.output.push_str("set ");
                self.output.push_str(binding.name.name.as_ref());
                self.output.push_str(" = ");
                self.format_expr(&binding.value);
            }

            Item::FunctionDef(func) => {
                self.output.push_str("let ");
                self.output.push_str(func.name.name.as_ref());
                for param in &func.params {
                    self.output.push(' ');
                    self.format_pattern(param);
                }
                self.output.push_str(" = ");
                self.format_expr(&func.body);
            }

            Item::Import(import) => {
                self.output.push_str("import ");
                for (i, item) in import.items.iter().enumerate() {
                    if i > 0 {
                        self.output.push_str(", ");
                    }
                    match item {
                        ImportItem::Named(ident) => {
                            self.output.push_str(ident.name.as_ref());
                        }
                        ImportItem::Aliased { name, alias } => {
                            self.output.push_str(name.name.as_ref());
                            self.output.push_str(" as ");
                            self.output.push_str(alias.name.as_ref());
                        }
                        ImportItem::All => {
                            self.output.push('*');
                        }
                        ImportItem::AllAliased(alias) => {
                            self.output.push_str("* as ");
                            self.output.push_str(alias.name.as_ref());
                        }
                    }
                }
                self.output.push_str(" from \"");
                self.output.push_str(&import.from);
                self.output.push('"');
            }

            Item::Export(_) => {
                self.output.push_str("export ...");
            }

            Item::Mod(mod_decl) => {
                self.output.push_str("mod ");
                self.output.push_str(mod_decl.name.name.as_ref());
            }

            Item::Use(use_decl) => {
                self.output.push_str("use ");
                for (i, segment) in use_decl.path.segments.iter().enumerate() {
                    if i > 0 {
                        self.output.push_str("::");
                    }
                    self.output.push_str(segment.name.as_ref());
                }
            }

            Item::ExprStmt(expr) => {
                self.format_expr(expr);
            }
        }
    }

    fn format_expr(&mut self, expr: &Spanned<Expr>) {
        match &expr.node {
            Expr::Integer(n) => {
                self.output.push_str(&n.to_string());
            }
            Expr::Float(n) => {
                self.output.push_str(&n.to_string());
            }
            Expr::String(s) => {
                self.output.push('"');
                self.output.push_str(s);
                self.output.push('"');
            }
            Expr::Bool(b) => {
                self.output.push_str(if *b { "true" } else { "false" });
            }
            Expr::Unit => {
                self.output.push_str("()");
            }
            Expr::Ident(ident) => {
                self.output.push_str(ident.name.as_ref());
            }
            Expr::Interval(interval) => {
                self.format_interval(interval);
            }
            Expr::AbsolutePitch(pitch) => {
                self.output.push(pitch.note);
                match pitch.accidental {
                    1 => self.output.push('#'),
                    -1 => self.output.push('b'),
                    _ => {}
                }
                self.output.push_str(&pitch.octave.to_string());
            }
            Expr::Root => {
                self.output.push('R');
            }
            Expr::Block(block) => {
                self.output.push_str("| ");
                for (i, slot) in block.slots.iter().enumerate() {
                    if i > 0 {
                        self.output.push(' ');
                    }
                    self.format_slot(slot);
                }
                self.output.push_str(" |");
            }
            Expr::Lambda(lambda) => {
                self.output.push('\\');
                for (i, param) in lambda.params.iter().enumerate() {
                    if i > 0 {
                        self.output.push(' ');
                    }
                    self.format_pattern(param);
                }
                self.output.push_str(" -> ");
                self.format_expr(&lambda.body);
            }
            Expr::Application(app) => {
                self.format_expr(&app.func);
                self.output.push('(');
                for (i, arg) in app.args.iter().enumerate() {
                    if i > 0 {
                        self.output.push_str(", ");
                    }
                    self.format_expr(arg);
                }
                self.output.push(')');
            }
            Expr::Pipe(pipe) => {
                self.format_expr(&pipe.left);
                self.output.push_str(" |> ");
                self.format_expr(&pipe.right);
            }
            Expr::Array(elements) => {
                self.output.push('[');
                for (i, elem) in elements.iter().enumerate() {
                    if i > 0 {
                        self.output.push_str(", ");
                    }
                    self.format_expr(elem);
                }
                self.output.push(']');
            }
            _ => {
                self.output.push_str("...");
            }
        }
    }

    fn format_interval(&mut self, interval: &IntervalLit) {
        let quality = match interval.quality {
            relanote_lexer::token::IntervalQuality::Major => "M",
            relanote_lexer::token::IntervalQuality::Minor => "m",
            relanote_lexer::token::IntervalQuality::Perfect => "P",
            relanote_lexer::token::IntervalQuality::Diminished => "d",
            relanote_lexer::token::IntervalQuality::Augmented => "A",
        };
        self.output.push_str(quality);
        self.output.push_str(&interval.degree.to_string());
        for acc in &interval.accidentals {
            match acc {
                relanote_lexer::token::Accidental::Sharp => self.output.push('+'),
                relanote_lexer::token::Accidental::Flat => self.output.push('-'),
            }
        }
    }

    fn format_slot(&mut self, slot: &Spanned<Slot>) {
        match &slot.node {
            Slot::Note {
                pitch,
                articulations,
                duration,
            } => {
                self.format_pitch(&pitch.node);
                for art in articulations {
                    match art {
                        Articulation::Staccato => self.output.push('*'),
                        Articulation::Accent => self.output.push('^'),
                        Articulation::Portamento => self.output.push('~'),
                    }
                }
                if let Some(d) = duration {
                    self.output.push(':');
                    self.output.push_str(&d.to_string());
                }
            }
            Slot::Rest { duration } => {
                self.output.push('-');
                if let Some(d) = duration {
                    self.output.push(':');
                    self.output.push_str(&d.to_string());
                }
            }
            Slot::Chord {
                pitches,
                articulations,
                duration,
            } => {
                self.output.push('[');
                for (i, pitch) in pitches.iter().enumerate() {
                    if i > 0 {
                        self.output.push(' ');
                    }
                    self.format_pitch(&pitch.node);
                }
                self.output.push(']');
                for art in articulations {
                    match art {
                        Articulation::Staccato => self.output.push('*'),
                        Articulation::Accent => self.output.push('^'),
                        Articulation::Portamento => self.output.push('~'),
                    }
                }
                if let Some(d) = duration {
                    self.output.push(':');
                    self.output.push_str(&d.to_string());
                }
            }
            Slot::Tuplet(tuplet) => {
                self.output.push_str("{ ");
                for (i, s) in tuplet.contents.iter().enumerate() {
                    if i > 0 {
                        self.output.push(' ');
                    }
                    self.format_slot(s);
                }
                self.output.push_str(" }:");
                self.format_expr(&tuplet.target_beats);
            }
        }
    }

    fn format_pitch(&mut self, pitch: &Pitch) {
        match pitch {
            Pitch::Interval(interval) => self.format_interval(interval),
            Pitch::Root => self.output.push('R'),
            Pitch::ScaleIndex(idx) => {
                self.output.push('<');
                self.output.push_str(&idx.to_string());
                self.output.push('>');
            }
            Pitch::ScaleIndexMod(idx, accs) => {
                self.output.push('<');
                self.output.push_str(&idx.to_string());
                for acc in accs {
                    match acc {
                        relanote_lexer::token::Accidental::Sharp => self.output.push('+'),
                        relanote_lexer::token::Accidental::Flat => self.output.push('-'),
                    }
                }
                self.output.push('>');
            }
        }
    }

    fn format_pattern(&mut self, pattern: &Spanned<Pattern>) {
        match &pattern.node {
            Pattern::Wildcard => self.output.push('_'),
            Pattern::Ident(ident) => self.output.push_str(ident.name.as_ref()),
            Pattern::Literal(lit) => match lit {
                LiteralPattern::Integer(n) => self.output.push_str(&n.to_string()),
                LiteralPattern::Float(n) => self.output.push_str(&n.to_string()),
                LiteralPattern::String(s) => {
                    self.output.push('"');
                    self.output.push_str(s);
                    self.output.push('"');
                }
                LiteralPattern::Bool(b) => {
                    self.output.push_str(if *b { "true" } else { "false" });
                }
                LiteralPattern::Unit => self.output.push_str("()"),
            },
            Pattern::Tuple(patterns) => {
                self.output.push('(');
                for (i, p) in patterns.iter().enumerate() {
                    if i > 0 {
                        self.output.push_str(", ");
                    }
                    self.format_pattern(p);
                }
                self.output.push(')');
            }
            _ => self.output.push_str("..."),
        }
    }
}
