import gleam/bool
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/set
import gleam/string
import simplifile

type Gate {
  And(a: String, b: String, out: String)
  Xor(a: String, b: String, out: String)
  Or(a: String, b: String, out: String)
}

pub fn main() {
  let assert Ok(content) = simplifile.read("input")
  let #(state, gates) = parse(content)

  let state = solve(state, gates)

  io.debug(state)

  let result = get_output(state)
  io.debug(result)
}

fn get_output(state: dict.Dict(String, Bool)) -> Int {
  state
  |> dict.fold(0, fn(sum, name, value) {
    sum
    + case name {
      "z" <> i if value -> {
        let assert Ok(i) = int.parse(i)
        1 |> int.bitwise_shift_left(i)
      }
      _ -> 0
    }
  })
}

fn solve(
  state: dict.Dict(String, Bool),
  gates: List(Gate),
) -> dict.Dict(String, Bool) {
  let new_state = step(state, gates)

  use <- bool.guard(new_state == state, state)

  solve(new_state, gates)
}

fn step(
  state: dict.Dict(String, Bool),
  gates: List(Gate),
) -> dict.Dict(String, Bool) {
  gates
  |> list.fold(state, fn(state, gate) {
    state
    |> dict.upsert(gate.out, fn(_) {
      let assert Ok(a) = state |> dict.get(gate.a)
      let assert Ok(b) = state |> dict.get(gate.b)
      case gate {
        And(_, _, _) -> bool.and(a, b)
        Xor(_, _, _) -> bool.exclusive_or(a, b)
        Or(_, _, _) -> bool.or(a, b)
      }
    })
  })
}

fn parse(content: String) -> #(dict.Dict(String, Bool), List(Gate)) {
  let assert Ok(#(state, gates)) = string.split_once(content, on: "\n\n")

  let state =
    state
    |> string.split(on: "\n")
    |> list.filter(fn(line) { !string.is_empty(line) })
    |> list.fold(dict.new(), fn(state, line) {
      let assert Ok(#(name, value)) = string.split_once(line, on: ": ")
      let assert Ok(value) = int.parse(value)
      let value = case value {
        0 -> False
        1 -> True
        _ -> panic
      }

      state
      |> dict.insert(name, value)
    })

  let #(variables, gates) =
    gates
    |> string.split(on: "\n")
    |> list.filter(fn(line) { !string.is_empty(line) })
    |> list.fold(#(set.new(), []), fn(acc, line) {
      let #(variables, gates) = acc
      let gate = parse_gate(line)

      #(
        variables
          |> set.insert(gate.a)
          |> set.insert(gate.b)
          |> set.insert(gate.out),
        [gate, ..gates],
      )
    })

  let state =
    variables
    |> set.fold(state, fn(state, variable) {
      state
      |> dict.upsert(variable, fn(value) {
        case value {
          option.None -> False
          option.Some(value) -> value
        }
      })
    })

  #(state, gates)
}

fn parse_gate(line: String) -> Gate {
  case line |> string.split(on: " ") {
    [a, "AND", b, "->", out] -> And(a, b, out)
    [a, "XOR", b, "->", out] -> Xor(a, b, out)
    [a, "OR", b, "->", out] -> Or(a, b, out)
    _ -> {
      io.println_error("could not parse gate from line: " <> line)
      panic
    }
  }
}
