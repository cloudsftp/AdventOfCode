import day_02_b
import gleam/list
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

// gleeunit test functions end in `_test`
pub fn hello_world_test() {
  let tests = [
    #([], True),
    #([1, 2, 3], True),
    #([4, 4, 3, 0], True),
    #([8, 4, 4, 3, 0], False),
    #([48, 44, 44, 43, 40], False),
    #([], True),
    #([], True),
    #([], True),
    #([], True),
    #([], True),
    #([], True),
  ]

  tests
  |> list.each(fn(test_case) {
    let #(levels, result) = test_case

    day_02_b.is_safe(levels)
    |> should.equal(result)
  })
}
