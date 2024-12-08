import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

type Data {
  Equation(target: Int, values: List(Int))
}

pub fn main() {
  use content <- result.try(
    simplifile.read("input")
    |> result.replace_error(Nil),
  )

  let lines =
    content
    |> string.split(on: "\n")
    |> list.filter(fn(line) { !string.is_empty(line) })

  use equations <- result.map(
    lines
    |> parse_input,
  )

  let result =
    equations
    |> list.filter(is_valid)
    |> list.map(fn(equation) { equation.target })
    |> int.sum

  io.debug(result)
}

fn is_valid(equation: Data) -> Bool {
  let assert [left, ..values] = equation.values

  is_valid_recurse(values, equation.target, left)
}

fn is_valid_recurse(values: List(Int), target: Int, left: Int) -> Bool {
  case values {
    [right, ..values] -> {
      is_valid_recurse(values, target, left + right)
      || is_valid_recurse(values, target, left * right)
    }
    [] -> left == target
  }
}

fn parse_input(lines: List(String)) -> Result(List(Data), Nil) {
  lines
  |> list.map(fn(line) {
    use #(left, right) <- result.try(string.split_once(line, on: ":"))

    use target <- result.try(
      left
      |> string.trim
      |> int.parse,
    )

    use values <- result.map(
      right
      |> string.trim
      |> string.split(on: " ")
      |> list.map(fn(part) {
        part
        |> int.parse
      })
      |> result.all,
    )

    Equation(target, values)
  })
  |> result.all
}
