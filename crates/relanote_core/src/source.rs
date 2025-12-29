use std::path::{Path, PathBuf};

use indexmap::IndexMap;

use crate::span::Location;

/// Unique identifier for a source file
#[derive(Clone, Copy, Debug, PartialEq, Eq, Hash, Default)]
pub struct SourceId(u32);

impl SourceId {
    pub fn dummy() -> Self {
        Self(u32::MAX)
    }

    pub fn is_dummy(&self) -> bool {
        self.0 == u32::MAX
    }

    pub fn index(&self) -> usize {
        self.0 as usize
    }
}

/// A source file
#[derive(Clone, Debug)]
pub struct Source {
    pub id: SourceId,
    pub path: PathBuf,
    pub name: String,
    pub content: String,
    line_starts: Vec<usize>,
}

impl Source {
    pub fn new(id: SourceId, path: PathBuf, content: String) -> Self {
        let name = path
            .file_name()
            .map(|s| s.to_string_lossy().into_owned())
            .unwrap_or_else(|| "<unknown>".to_string());

        let line_starts = std::iter::once(0)
            .chain(content.match_indices('\n').map(|(i, _)| i + 1))
            .collect();

        Self {
            id,
            path,
            name,
            content,
            line_starts,
        }
    }

    pub fn from_string(name: impl Into<String>, content: String) -> Self {
        let name = name.into();
        Self::new(SourceId::dummy(), PathBuf::from(&name), content)
    }

    /// Get line and column from byte offset
    pub fn location(&self, offset: usize) -> Location {
        let line = self
            .line_starts
            .partition_point(|&start| start <= offset)
            .saturating_sub(1);
        let line_start = self.line_starts.get(line).copied().unwrap_or(0);
        let column = offset.saturating_sub(line_start) + 1;
        Location::new(line + 1, column)
    }

    /// Get the content of a specific line (1-based)
    pub fn line(&self, line: usize) -> Option<&str> {
        if line == 0 || line > self.line_starts.len() {
            return None;
        }
        let start = self.line_starts[line - 1];
        let end = self
            .line_starts
            .get(line)
            .copied()
            .unwrap_or(self.content.len());
        Some(self.content[start..end].trim_end_matches('\n'))
    }

    /// Get number of lines
    pub fn line_count(&self) -> usize {
        self.line_starts.len()
    }
}

/// Database of source files
#[derive(Default)]
pub struct SourceDb {
    sources: Vec<Source>,
    paths: IndexMap<PathBuf, SourceId>,
}

impl SourceDb {
    pub fn new() -> Self {
        Self::default()
    }

    /// Add a source file from a path
    pub fn add_file(&mut self, path: impl AsRef<Path>) -> std::io::Result<SourceId> {
        let path = path.as_ref().to_path_buf();

        if let Some(&id) = self.paths.get(&path) {
            return Ok(id);
        }

        let content = std::fs::read_to_string(&path)?;
        Ok(self.add_source(path, content))
    }

    /// Add a source from string content
    pub fn add_source(&mut self, path: PathBuf, content: String) -> SourceId {
        if let Some(&id) = self.paths.get(&path) {
            return id;
        }

        let id = SourceId(self.sources.len() as u32);
        let source = Source::new(id, path.clone(), content);
        self.sources.push(source);
        self.paths.insert(path, id);
        id
    }

    /// Add an anonymous source (for REPL, tests, etc.)
    pub fn add_anonymous(&mut self, name: impl Into<String>, content: String) -> SourceId {
        let name = name.into();
        let path = PathBuf::from(format!("<{}>", name));
        self.add_source(path, content)
    }

    /// Get a source by ID
    pub fn get(&self, id: SourceId) -> Option<&Source> {
        if id.is_dummy() {
            return None;
        }
        self.sources.get(id.index())
    }

    /// Get a source by path
    pub fn get_by_path(&self, path: &Path) -> Option<&Source> {
        self.paths.get(path).and_then(|&id| self.get(id))
    }

    /// Get location from source ID and byte offset
    pub fn location(&self, id: SourceId, offset: usize) -> Option<Location> {
        self.get(id).map(|s| s.location(offset))
    }

    /// Iterator over all sources
    pub fn iter(&self) -> impl Iterator<Item = &Source> {
        self.sources.iter()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_source_location() {
        let source = Source::from_string("test", "hello\nworld\n".to_string());

        assert_eq!(source.location(0), Location::new(1, 1)); // 'h'
        assert_eq!(source.location(5), Location::new(1, 6)); // '\n'
        assert_eq!(source.location(6), Location::new(2, 1)); // 'w'
        assert_eq!(source.location(11), Location::new(2, 6)); // '\n'
    }

    #[test]
    fn test_source_line() {
        let source = Source::from_string("test", "hello\nworld\nfoo".to_string());

        assert_eq!(source.line(1), Some("hello"));
        assert_eq!(source.line(2), Some("world"));
        assert_eq!(source.line(3), Some("foo"));
        assert_eq!(source.line(4), None);
        assert_eq!(source.line(0), None);
    }

    #[test]
    fn test_source_db() {
        let mut db = SourceDb::new();
        let id = db.add_anonymous("test", "hello world".to_string());

        assert!(!id.is_dummy());
        assert!(db.get(id).is_some());
        assert_eq!(db.get(id).unwrap().content, "hello world");
    }
}
