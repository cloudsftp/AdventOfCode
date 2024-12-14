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
  let assert Ok(content) = simplifile.read("input")
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
    //    |> list.map(fn(machine) {
    //      let Machine(button_a, button_b, #(x, y)) = machine
    //      Machine(button_a, button_b, target: #(
    //        10_000_000_000_000 + x,
    //        10_000_000_000_000 + y,
    //      ))
    //    })
    |> list.map(score)
    |> int.sum

  io.debug(result)
}

fn score(machine: Game) -> Int {
  let #(x, y) = machine.target
  let #(adx, ady) = machine.button_a
  let #(bdx, bdy) = machine.button_b

  io.debug(#(x / bdx, y / bdy))
  let max_b_presses = int.max(x / bdx, y / bdy)

  let #(_, result) =
    yielder.range(max_b_presses, 0)
    |> yielder.fold_until(#(set.new(), option.None), fn(acc, b) {
      let #(seen, min_cost) = acc
      let l = { x - b * bdx } / adx
      let k = { y - b * bdy } / ady

      let rx = { x - b * bdx } % adx
      let ry = { y - b * bdy } % ady

      use <- bool.guard(
        seen |> set.contains(#(rx, ry)),
        list.Stop(#(seen, min_cost)),
      )

      case rx == 0 && ry == 0 && l == k {
        True -> list.Stop(#(seen, option.Some(cost(#(l, b)))))
        False -> list.Continue(#(seen |> set.insert(#(rx, ry)), min_cost))
      }
    })

  result |> option.unwrap(0)
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
