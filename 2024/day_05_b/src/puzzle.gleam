import gleam/bool
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
  dict.Dict(Int, set.Set(Int))

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

  use #(before, after, updates) <- result.try(parse_input(lines))

  let unordered_updates =
    updates
    |> list.filter(fn(update) { !is_update_in_order(update, after) })

  use middle_values <- result.map(
    unordered_updates
    |> list.map(fn(update) {
      use middle_index <- result.try(middle_index(update))

      pop_head(update, before, middle_index)
    })
    |> result.all,
  )

  let result =
    middle_values
    |> int.sum

  io.debug(result)
}

fn pop_head(update: List(Int), before: Rules, times: Int) -> Result(Int, Nil) {
  let head_index =
    update
    |> find_index(fn(value) {
      case
        before
        |> dict.get(value)
      {
        Error(Nil) -> True
        Ok(before) ->
          !{
            update
            |> list.any(fn(value) {
              before
              |> set.contains(value)
            })
          }
      }
    })

  use <- bool.guard(
    times == 0,
    update
      |> list.drop(head_index)
      |> list.first,
  )

  let update =
    list.append(
      update |> list.take(head_index),
      update |> list.drop(head_index + 1),
    )

  pop_head(update, before, times - 1)
}

fn find_index(list: List(t), pred: fn(t) -> Bool) -> Int {
  list
  |> list.fold_until(0, fn(index, element) {
    case pred(element) {
      True -> list.Stop(index)
      False -> list.Continue(index + 1)
    }
  })
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
            |> set.to_list
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

fn middle_index(update: List(Int)) -> Result(Int, Nil) {
  let len =
    update
    |> list.length

  use middle_index <- result.map(
    { len - 1 }
    |> int.divide(2),
  )

  middle_index
}

fn parse_input(lines: List(String)) -> Result(#(Rules, Rules, Updates), Nil) {
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
      |> set.from_list
    })

  let before =
    rules
    |> list.group(fn(rule) {
      rule
      |> pair.second
    })
    |> dict.map_values(fn(_, rules) {
      rules
      |> list.map(fn(rule) {
        rule
        |> pair.first
      })
      |> set.from_list
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

  #(before, after, updates)
}
