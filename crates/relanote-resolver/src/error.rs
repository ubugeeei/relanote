use std::path::PathBuf;
use thiserror::Error;

#[derive(Debug, Error)]
pub enum ResolveError {
    #[error("module not found: {path}")]
    ModuleNotFound { path: String },

    #[error("circular dependency detected: {path}")]
    CircularDependency { path: String },

    #[error("failed to read file: {path}")]
    IoError {
        path: PathBuf,
        #[source]
        source: std::io::Error,
    },

    #[error("parse error in module: {path}")]
    ParseError { path: String },
}
