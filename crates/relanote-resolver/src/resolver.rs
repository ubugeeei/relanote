use std::collections::HashSet;
use std::path::PathBuf;

use indexmap::IndexMap;
use relanote_ast::Program;
use relanote_core::{Diagnostics, SourceId};
use relanote_parser::parse_file;

use crate::error::ResolveError;
use crate::loader::ModuleLoader;

/// Resolved module
pub struct ResolvedModule {
    pub source_id: SourceId,
    pub program: Program,
    pub diagnostics: Diagnostics,
    pub dependencies: Vec<String>,
}

/// Module resolver for handling imports and dependencies
pub struct ModuleResolver {
    loader: ModuleLoader,
    modules: IndexMap<String, ResolvedModule>,
    resolving: HashSet<String>,
}

impl ModuleResolver {
    pub fn new(root: PathBuf) -> Self {
        Self {
            loader: ModuleLoader::new(root),
            modules: IndexMap::new(),
            resolving: HashSet::new(),
        }
    }

    /// Resolve a module and its dependencies
    pub fn resolve(&mut self, module_path: &str) -> Result<&ResolvedModule, ResolveError> {
        // Check for circular dependency
        if self.resolving.contains(module_path) {
            return Err(ResolveError::CircularDependency {
                path: module_path.to_string(),
            });
        }

        // Return cached module if already resolved
        if self.modules.contains_key(module_path) {
            return Ok(&self.modules[module_path]);
        }

        // Resolve the module path
        let path = self
            .loader
            .resolve_path(module_path)
            .ok_or_else(|| ResolveError::ModuleNotFound {
                path: module_path.to_string(),
            })?;

        // Load and parse the source
        let source_id = self.loader.load(&path)?;
        let (program, diagnostics) = parse_file(self.loader.source_db(), source_id)
            .ok_or_else(|| ResolveError::ParseError {
                path: module_path.to_string(),
            })?;

        // Mark as resolving
        self.resolving.insert(module_path.to_string());

        // Collect dependencies from import statements
        let mut dependencies = Vec::new();
        for item in &program.items {
            if let relanote_ast::Item::Import(import) = &item.node {
                dependencies.push(import.from.clone());
            }
        }

        // Recursively resolve dependencies
        for dep in &dependencies {
            self.resolve(dep)?;
        }

        // Remove from resolving set
        self.resolving.remove(module_path);

        // Store resolved module
        let resolved = ResolvedModule {
            source_id,
            program,
            diagnostics,
            dependencies,
        };

        self.modules.insert(module_path.to_string(), resolved);
        Ok(&self.modules[module_path])
    }

    /// Get all resolved modules in dependency order
    pub fn modules(&self) -> impl Iterator<Item = &ResolvedModule> {
        self.modules.values()
    }
}
