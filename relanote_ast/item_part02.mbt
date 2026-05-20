///|
pub struct UseItem {
  name : Ident
  as_name : Ident?
}

///|
pub fn UseItem::new(name : Ident, as_name : Ident?) -> UseItem {
  { name, as_name }
}

///|
pub fn UseItem::name(self : UseItem) -> Ident {
  self.name
}

///|
pub fn UseItem::as_name(self : UseItem) -> Ident? {
  self.as_name
}
