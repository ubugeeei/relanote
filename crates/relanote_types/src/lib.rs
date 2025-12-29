mod checker;
mod context;
mod error;
mod inference;
mod types;
mod unify;

pub use checker::TypeChecker;
pub use context::TypeContext;
pub use error::TypeError;
pub use types::{TyVar, Type, TypeScheme};
