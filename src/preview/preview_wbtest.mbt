///|
test "events_json follows evaluated block rhythm" {
  let expected =
    #|[{"pitch":60,"start":0,"duration":1,"velocity":100},{"pitch":64,"start":1,"duration":1,"velocity":100},{"pitch":67,"start":3,"duration":1,"velocity":100}]
  inspect(
    events_json("| <1> <3> - <5> |:4"),
    content=expected,
  )
}

///|
test "summary reports notes and total beats" {
  inspect(playground_summary("| <1> <3> - <5> |:4"), content="3 notes / 4 beats")
}
