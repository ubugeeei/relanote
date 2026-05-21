///|
test "events_json follows evaluated block rhythm" {
  let expected =
    #|[{"pitch":60,"start":0,"duration":1,"velocity":100},{"pitch":64,"start":1,"duration":1,"velocity":100},{"pitch":67,"start":3,"duration":1,"velocity":100}]
  inspect(events_json("| <1> <3> - <5> |:4"), content=expected)
}

///|
test "summary reports notes and total beats" {
  inspect(
    playground_summary("| <1> <3> - <5> |:4"),
    content="3 notes / 4 beats",
  )
}

///|
test "staff_html renders clef, guide lines, and playhead colors" {
  let svg = staff_html("| <1> <3> |:2", 0.25)
  assert_true(svg.contains("viewBox='0 0 520 170'"))
  assert_true(svg.contains("aria-label='Staff preview'"))
  assert_true(svg.contains("<text x='8' y='82'"))
  assert_true(svg.contains("fill='#ffd05a'"))
  assert_true(svg.contains("fill='#fff8ed'"))
  assert_true(svg.contains("stroke='#55616d'"))
}

///|
test "staff_html expands with longer phrases" {
  let svg = staff_html("| <1> <2> <3> <4> <5> |:10", 0.0)
  assert_true(svg.contains("viewBox='0 0 640 170'"))
}

///|
test "piano_html renders roll lanes and playhead colors" {
  let svg = piano_html("| <1> <3> |:2", 1.25)
  assert_true(svg.contains("viewBox='0 0 520 168'"))
  assert_true(svg.contains("aria-label='Piano roll preview'"))
  assert_true(svg.contains("fill='#22242c'"))
  assert_true(svg.contains("fill='#151820'"))
  assert_true(svg.contains("fill='#caff55'"))
  assert_true(svg.contains("fill='#ff4f7a'"))
}

///|
test "empty preview keeps scaffold without note glyphs" {
  inspect(events_json("let melody = | <1> <3> |"), content="[]")
  inspect(
    playground_summary("let melody = | <1> <3> |"),
    content="0 notes / 0 beats",
  )
  assert_false(staff_html("let melody = | <1> <3> |", 0.0).contains("<ellipse"))
  assert_false(piano_html("let melody = | <1> <3> |", 0.0).contains("rx='3'"))
}

///|
test "events_json covers scalar preview values and errors" {
  assert_true(events_json("R").contains("\"pitch\":60"))
  assert_true(events_json("M3").contains("\"pitch\":64"))
  assert_true(events_json("C4").contains("\"pitch\":60"))
  inspect(events_json("definitely_missing"), content="[]")
}

///|
test "preview hears concat chord and tuplet examples" {
  let src = "| [R, M3, P5] | ++ | { <1> <2> <3> }:2 |"
  assert_true(events_json(src).contains("\"pitch\":67"))
  inspect(playground_summary(src), content="6 notes / 3 beats")
}

///|
test "preview hears pipe-friendly partial builtins" {
  let src = "let m = | <1> <3> |\nm |> repeat(2)"
  inspect(playground_summary(src), content="4 notes / 2 beats")
}

///|
test "summary rounds floating point beat noise" {
  let src = "| <1> <2> <3> |:2 ++ | <5> |:4"
  inspect(playground_summary(src), content="4 notes / 6 beats")
}
