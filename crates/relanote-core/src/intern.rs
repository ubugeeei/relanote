use internment::Intern;

/// Interned string for efficient comparison and storage
pub type InternedStr = Intern<String>;

/// Intern a string
pub fn intern(s: &str) -> InternedStr {
    Intern::new(s.to_owned())
}

/// Intern a String (takes ownership)
pub fn intern_string(s: String) -> InternedStr {
    Intern::new(s)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_intern() {
        let a = intern("hello");
        let b = intern("hello");
        let c = intern("world");

        assert_eq!(a, b);
        assert_ne!(a, c);

        // Same pointer for equal strings
        assert!(std::ptr::eq(a.as_ref(), b.as_ref()));
    }
}
