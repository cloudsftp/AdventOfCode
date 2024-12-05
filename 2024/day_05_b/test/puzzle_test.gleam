import gleam/io
import gleam/list
import gleam/option
import gleam/regexp
import gleam/result
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

pub fn regex_test() {
  let test_cases = [
    #("\\d{1,3}", "a", []),
    #("\\d{1,3}", "1", ["1"]),
    #("\\d{1,3}", "1,2", ["1", "2"]),
    #("(\\d{1,3})", "1,2", ["1", "2"]),
    #("\\(\\d{1,3}\\)", "1,2", []),
    #("\\(\\d{1,3}\\)", "(1),(2)", ["(1)", "(2)"]),
  ]

  use #(pattern, content, expected) <- list.each(test_cases)

  let result = {
    use regex <- result.map(
      pattern
      |> regexp.compile(regexp.Options(False, True))
      |> result.map_error(fn(err) {
        io.debug(err)
        Nil
      }),
    )

    regexp.scan(regex, content)
    |> list.map(fn(match) { match.content })
  }

  result
  |> should.be_ok
  |> should.equal(expected)
}

pub fn regex_group_test() {
  let pattern = "mul\\((\\d{1,3}),(\\d{1,3})\\)"
  let regex =
    pattern
    |> regexp.compile(regexp.Options(False, True))
    |> should.be_ok

  let test_cases = [
    #("a", []),
    #("mul(1,1)", [["1", "1"]]),
    #("a", []),
    #("a", []),
    #("a", []),
    #("a", []),
    #("a", []),
  ]

  use #(content, expected) <- list.each(test_cases)

  regexp.scan(regex, content)
  |> list.map(fn(match) { option.all(match.submatches) })
  |> option.all
  |> should.be_some
  |> should.equal(expected)
}
