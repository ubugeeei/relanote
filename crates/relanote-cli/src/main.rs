use std::fs;
use std::path::{Path, PathBuf};

use ariadne::{Color, Label, Report, ReportKind, Source};
use clap::{Parser, Subcommand};

use relanote_core::Source as RelaSource;
use relanote_eval::Evaluator;
use relanote_format::{format, FormatConfig};
use relanote_parser::parse_source;
use relanote_render::render_to_midi;
use relanote_types::TypeChecker;

#[derive(Parser)]
#[command(name = "relanote")]
#[command(about = "A pure functional music notation language", long_about = None)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Parse a relanote file and display the AST
    Parse {
        /// Input file
        file: PathBuf,
    },

    /// Type check a relanote file
    Check {
        /// Input file
        file: PathBuf,
    },

    /// Run/evaluate a relanote file
    Run {
        /// Input file
        file: PathBuf,
    },

    /// Format a relanote file
    Format {
        /// Input file
        file: PathBuf,
        /// Write output to file (in-place if same as input)
        #[arg(short, long)]
        output: Option<PathBuf>,
    },

    /// Render a relanote file to MIDI
    Render {
        /// Input file
        file: PathBuf,
        /// Output file
        #[arg(short, long)]
        output: PathBuf,
    },

    /// Start the LSP server
    Lsp,
}

fn main() {
    let cli = Cli::parse();

    match cli.command {
        Commands::Parse { file } => cmd_parse(&file),
        Commands::Check { file } => cmd_check(&file),
        Commands::Run { file } => cmd_run(&file),
        Commands::Format { file, output } => cmd_format(&file, output),
        Commands::Render { file, output } => cmd_render(&file, &output),
        Commands::Lsp => cmd_lsp(),
    }
}

fn cmd_parse(file: &PathBuf) {
    let content = match fs::read_to_string(file) {
        Ok(c) => c,
        Err(e) => {
            eprintln!("Error reading file: {}", e);
            std::process::exit(1);
        }
    };

    let source = RelaSource::from_string(file.display().to_string(), content.clone());
    let (program, diagnostics) = parse_source(&source);

    if diagnostics.has_errors() {
        print_diagnostics(file, &content, &diagnostics);
        std::process::exit(1);
    }

    println!("{:#?}", program);
}

fn cmd_check(file: &PathBuf) {
    let content = match fs::read_to_string(file) {
        Ok(c) => c,
        Err(e) => {
            eprintln!("Error reading file: {}", e);
            std::process::exit(1);
        }
    };

    let source = RelaSource::from_string(file.display().to_string(), content.clone());
    let (program, parse_diagnostics) = parse_source(&source);

    if parse_diagnostics.has_errors() {
        print_diagnostics(file, &content, &parse_diagnostics);
        std::process::exit(1);
    }

    let mut type_checker = TypeChecker::new();
    let type_diagnostics = type_checker.check_program(&program);

    if type_diagnostics.has_errors() {
        print_diagnostics(file, &content, &type_diagnostics);
        std::process::exit(1);
    }

    println!("No errors found.");
}

fn cmd_run(file: &PathBuf) {
    let content = match fs::read_to_string(file) {
        Ok(c) => c,
        Err(e) => {
            eprintln!("Error reading file: {}", e);
            std::process::exit(1);
        }
    };

    let source = RelaSource::from_string(file.display().to_string(), content.clone());
    let (program, parse_diagnostics) = parse_source(&source);

    if parse_diagnostics.has_errors() {
        print_diagnostics(file, &content, &parse_diagnostics);
        std::process::exit(1);
    }

    let mut type_checker = TypeChecker::new();
    let type_diagnostics = type_checker.check_program(&program);

    if type_diagnostics.has_errors() {
        print_diagnostics(file, &content, &type_diagnostics);
        std::process::exit(1);
    }

    let mut evaluator = Evaluator::new();
    match evaluator.eval_program(&program) {
        Ok(value) => {
            println!("{:?}", value);
        }
        Err(e) => {
            eprintln!("Runtime error: {}", e);
            std::process::exit(1);
        }
    }
}

fn cmd_format(file: &PathBuf, output: Option<PathBuf>) {
    let content = match fs::read_to_string(file) {
        Ok(c) => c,
        Err(e) => {
            eprintln!("Error reading file: {}", e);
            std::process::exit(1);
        }
    };

    let source = RelaSource::from_string(file.display().to_string(), content.clone());
    let (program, diagnostics) = parse_source(&source);

    if diagnostics.has_errors() {
        print_diagnostics(file, &content, &diagnostics);
        std::process::exit(1);
    }

    let config = FormatConfig::default();
    let formatted = format(&program, &config);

    match output {
        Some(output_path) => {
            if let Err(e) = fs::write(&output_path, &formatted) {
                eprintln!("Error writing file: {}", e);
                std::process::exit(1);
            }
            println!("Formatted output written to {}", output_path.display());
        }
        None => {
            print!("{}", formatted);
        }
    }
}

fn cmd_render(file: &PathBuf, output: &PathBuf) {
    let content = match fs::read_to_string(file) {
        Ok(c) => c,
        Err(e) => {
            eprintln!("Error reading file: {}", e);
            std::process::exit(1);
        }
    };

    let source = RelaSource::from_string(file.display().to_string(), content.clone());
    let (program, parse_diagnostics) = parse_source(&source);

    if parse_diagnostics.has_errors() {
        print_diagnostics(file, &content, &parse_diagnostics);
        std::process::exit(1);
    }

    let mut evaluator = Evaluator::new();
    match evaluator.eval_program(&program) {
        Ok(relanote_eval::Value::Song(song)) => {
            let midi_data = render_to_midi(&song);
            if let Err(e) = fs::write(output, &midi_data) {
                eprintln!("Error writing MIDI file: {}", e);
                std::process::exit(1);
            }
            println!("MIDI file written to {}", output.display());
        }
        Ok(_) => {
            eprintln!("Error: Program did not produce a Song value");
            std::process::exit(1);
        }
        Err(e) => {
            eprintln!("Runtime error: {}", e);
            std::process::exit(1);
        }
    }
}

fn cmd_lsp() {
    let rt = tokio::runtime::Runtime::new().unwrap();
    rt.block_on(relanote_lsp::run_server());
}

fn print_diagnostics(file: &Path, content: &str, diagnostics: &relanote_core::Diagnostics) {
    let filename = file.display().to_string();

    for diag in diagnostics.iter() {
        let report = Report::build(ReportKind::Error, &filename, diag.span.start)
            .with_message(&diag.message)
            .with_label(
                Label::new((&filename, diag.span.start..diag.span.end))
                    .with_message(&diag.message)
                    .with_color(Color::Red),
            );

        let report = diag.notes.iter().fold(report, |r, note| r.with_note(note));

        report
            .finish()
            .print((&filename, Source::from(content)))
            .unwrap();
    }
}
