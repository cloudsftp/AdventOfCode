import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/result
import gleam/set
import gleam/string
import gleam/yielder
import gleam_community/maths/arithmetics
import simplifile

type Position =
  #(Int, Int)

type Game {
  Machine(button_a: Position, button_b: Position, target: Position)
}

pub fn main() {
  let assert Ok(content) = simplifile.read("input.small")
  let machines =
    content
    |> string.split(on: "\n")
    |> list.fold([[]], fn(acc, line) {
      let assert [current, ..rest] = acc

      case line |> string.is_empty {
        False -> {
          let current = [line, ..current]
          [current, ..rest]
        }
        True -> [[], ..acc]
      }
    })
    |> list.filter(fn(element) { !{ element |> list.is_empty } })
    |> list.map(parse_machine)

  let result =
    machines
    |> list.map(fn(machine) {
      let Machine(button_a, button_b, #(x, y)) = machine
      Machine(button_a, button_b, target: #(
        10_000_000_000_000 + x,
        10_000_000_000_000 + y,
      ))
    })
    |> list.map(score)
    |> int.sum

  io.debug(result)
}

fn score(machine: Game) -> Int {
  let #(x, y) = machine.target
  let #(adx, ady) = machine.button_a
  let #(bdx, bdy) = machine.button_b

  let max_b_presses = int.max(x / bdx, y / bdy)

  yielder.range(max_b_presses, 0)
  |> yielder.find(fn(b) { { x - b * bdx } % adx == 0 })
  |> result.map(fn(b) {
    let a = { x - b * bdx } / adx

    let l = arithmetics.lcm(adx, bdx)
    let p = l / adx
    let q = l / ady

    min_cost_rec(a, b, p, q, option.None)
  })
  |> result.unwrap(0)
}

fn min_cost_rec(a: Int, b: Int, p: Int, q: Int, min: option.Option(Int)) -> Int {
  io.debug(#(a, b))
  use <- bool.guard(b < 0, min |> option.unwrap(0))
  case min {
    option.None -> min_cost_rec(a + p, b - q, p, q, option.Some(cost(#(a, b))))
    option.Some(min) -> {
      let min = int.min(cost(#(a, b)), min)
      min_cost_rec(a + p, b - q, p, q, option.Some(min))
    }
  }
}

fn cost(presses: #(Int, Int)) -> Int {
  let #(presses_a, presses_b) = presses
  3 * presses_a + presses_b
}

fn parse_machine(lines: List(String)) -> Game {
  let assert [line3, line2, line1] = lines
  Machine(
    button_a: parse_button(line1),
    button_b: parse_button(line2),
    target: parse_target(line3),
  )
}

fn parse_button(line: String) -> Position {
  let assert [_, _, x_part, y_part] =
    line
    |> string.replace(",", "")
    |> string.split(on: " ")

  let extract_number = fn(part) {
    let assert Ok(#(_, number)) = part |> string.split_once(on: "+")
    let assert Ok(number) = number |> int.parse
    number
  }

  #(extract_number(x_part), extract_number(y_part))
}

fn parse_target(line: String) -> Position {
  let assert [_, x_part, y_part] =
    line
    |> string.replace(",", "")
    |> string.split(on: " ")

  let extract_number = fn(part) {
    let assert Ok(#(_, number)) = part |> string.split_once(on: "=")
    let assert Ok(number) = number |> int.parse
    number
  }

  #(extract_number(x_part), extract_number(y_part))
}
