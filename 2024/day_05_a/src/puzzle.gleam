import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/result
import gleam/set
import gleam/string
import simplifile

type Rules =
  dict.Dict(Int, List(Int))

type Updates =
  List(List(Int))

pub fn main() {
  use content <- result.try(
    simplifile.read("input")
    |> result.replace_error(Nil),
  )
  let lines =
    content
    |> string.split(on: "\n")

  use #(after, updates) <- result.try(parse_input(lines))

  use result <- result.map(
    updates
    |> list.filter(fn(update) { is_update_in_order(update, after) })
    |> list.map(io.debug)
    |> list.map(middle)
    |> result.all
    |> result.map(int.sum),
  )

  io.debug(result)
}

fn is_update_in_order(update: List(Int), after: Rules) -> Bool {
  let #(_, is_in_order) =
    update
    |> list.fold_until(#(set.new(), True), fn(acc, value) {
      let #(encountered, is_in_order) = acc

      let encountered =
        encountered
        |> set.insert(value)

      case
        after
        |> dict.get(value)
      {
        // No rules
        Error(Nil) -> list.Continue(#(encountered, is_in_order))
        // Check all rules that apply
        Ok(after) ->
          case
            after
            |> list.any(fn(value) {
              encountered
              |> set.contains(value)
            })
          {
            True -> list.Stop(#(encountered, False))
            False -> list.Continue(#(encountered, is_in_order))
          }
      }
    })

  is_in_order
}

fn middle(update: List(Int)) -> Result(Int, Nil) {
  let len =
    update
    |> list.length

  use middle_index <- result.try(
    { len - 1 }
    |> int.divide(2),
  )

  use middle_value <- result.map(
    update
    |> list.drop(middle_index)
    |> list.first,
  )

  middle_value
}

fn parse_input(lines: List(String)) -> Result(#(Rules, Updates), Nil) {
  let rule_lines =
    lines
    |> list.take_while(fn(line) { !string.is_empty(line) })

  use rules <- result.try(
    rule_lines
    |> list.map(fn(line) {
      use #(left, right) <- result.try(
        line
        |> string.split_once(on: "|"),
      )

      use left <- result.try(int.parse(left))
      use right <- result.map(int.parse(right))
      #(left, right)
    })
    |> result.all,
  )

  let after =
    rules
    |> list.group(fn(rule) {
      rule
      |> pair.first
    })
    |> dict.map_values(fn(_, rules) {
      rules
      |> list.map(fn(rule) {
        rule
        |> pair.second
      })
    })

  let update_lines =
    lines
    |> list.drop(list.length(rule_lines))
    |> list.filter(fn(line) { !string.is_empty(line) })

  use updates <- result.map(
    update_lines
    |> list.map(fn(line) {
      line
      |> string.split(on: ",")
      |> list.map(int.parse)
      |> result.all
    })
    |> result.all,
  )

  #(after, updates)
}
