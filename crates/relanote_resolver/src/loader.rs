use std::path::{Path, PathBuf};

use relanote_core::SourceDb;

use crate::error::ResolveError;

/// Module loader responsible for finding and loading source files
pub struct ModuleLoader {
    /// Root directory for module resolution
    #[allow(dead_code)]
    root: PathBuf,
    /// Search paths for modules
    search_paths: Vec<PathBuf>,
    /// Source database
    source_db: SourceDb,
}

impl ModuleLoader {
    pub fn new(root: PathBuf) -> Self {
        Self {
            root: root.clone(),
            search_paths: vec![root],
            source_db: SourceDb::new(),
        }
    }

    pub fn add_search_path(&mut self, path: PathBuf) {
        self.search_paths.push(path);
    }

    pub fn resolve_path(&self, module_path: &str) -> Option<PathBuf> {
        let file_name = format!(
            "{}.rela",
            module_path.replace('/', std::path::MAIN_SEPARATOR_STR)
        );

        for search_path in &self.search_paths {
            let full_path = search_path.join(&file_name);
            if full_path.exists() {
                return Some(full_path);
            }
        }

        None
    }

    pub fn load(&mut self, path: &Path) -> Result<relanote_core::SourceId, ResolveError> {
        self.source_db
            .add_file(path)
            .map_err(|e| ResolveError::IoError {
                path: path.to_path_buf(),
                source: e,
            })
    }

    pub fn source_db(&self) -> &SourceDb {
        &self.source_db
    }

    pub fn source_db_mut(&mut self) -> &mut SourceDb {
        &mut self.source_db
    }
}
