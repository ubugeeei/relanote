///|
fn log2_int(n : Int) -> Int {
  let mut x = n
  let mut k = 0
  while x > 1 {
    x = x >> 1
    k += 1
  }
  k
}
