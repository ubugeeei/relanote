//! Environment/scope management

use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;

use relanote_core::InternedStr;

use crate::value::Value;

/// Evaluation environment
#[derive(Clone, Debug)]
pub struct Env {
    bindings: HashMap<InternedStr, Value>,
    parent: Option<Rc<RefCell<Env>>>,
}

impl Env {
    pub fn new() -> Self {
        Self {
            bindings: HashMap::new(),
            parent: None,
        }
    }

    pub fn with_parent(parent: Rc<RefCell<Env>>) -> Self {
        Self {
            bindings: HashMap::new(),
            parent: Some(parent),
        }
    }

    pub fn lookup(&self, name: &InternedStr) -> Option<Value> {
        self.bindings
            .get(name)
            .cloned()
            .or_else(|| self.parent.as_ref().and_then(|p| p.borrow().lookup(name)))
    }

    pub fn bind(&mut self, name: InternedStr, value: Value) {
        self.bindings.insert(name, value);
    }
}

impl Default for Env {
    fn default() -> Self {
        Self::new()
    }
}
