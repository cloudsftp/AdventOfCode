import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/set
import gleam/string
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
    |> list.map(score)
    |> int.sum

  io.debug(result)
}

fn score(machine: Game) -> Int {
  let #(x, y) = machine.target
  let #(xa, ya) = machine.button_a
  let #(xb, yb) = machine.button_b

  let presses_x = possible_presses(xa, xb, x)
  let presses_y = possible_presses(ya, yb, y)
  let presses = set.intersection(presses_x, presses_y)

  case
    presses
    |> set.fold(option.None, fn(acc, presses) {
      case acc {
        option.None -> option.Some(#(presses, cost(presses)))
        option.Some(acc) -> {
          let #(_, previous_cost) = acc
          use <- bool.guard(previous_cost < cost(presses), option.Some(acc))
          option.Some(#(presses, cost(presses)))
        }
      }
    })
  {
    option.Some(#(presses, _)) -> cost(presses)
    option.None -> 0
  }
}

pub fn possible_presses(a: Int, b: Int, target: Int) -> set.Set(#(Int, Int)) {
  let max_presses_b = target / b

  list.range(0, max_presses_b)
  |> list.filter_map(fn(i) {
    use <- bool.guard({ target - i * b } % a != 0, Error(Nil))
    Ok(#({ target - i * b } / a, i))
  })
  |> set.from_list
}

fn position(machine: Game, presses: #(Int, Int)) -> #(Int, Int) {
  let #(a, b) = presses
  let #(xa, ya) = machine.button_a
  let #(xb, yb) = machine.button_b

  #(a * xa + b * xb, a * ya + b * yb)
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
