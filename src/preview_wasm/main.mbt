///|
fn main {
  ()
}

///|
pub fn events_json(source : String) -> String {
  @preview.events_json(source)
}

///|
pub fn playground_summary(source : String) -> String {
  @preview.playground_summary(source)
}

///|
pub fn staff_html(source : String, beat : Double) -> String {
  @preview.staff_html(source, beat)
}

///|
pub fn piano_html(source : String, beat : Double) -> String {
  @preview.piano_html(source, beat)
}
