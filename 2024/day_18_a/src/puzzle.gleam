import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/set
import gleam/string
import gleamy/priority_queue as pq
import simplifile

type Position =
  #(Int, Int)

const max = 70

const fallen = 1024

type Work {
  Item(position: Position, cost: Int)
}

pub fn main() {
  let assert Ok(content) = simplifile.read("input")
  let blocks = parse(content)

  io.debug(blocks)
  print_map(blocks)

  let assert option.Some(result) =
    walk(
      pq.new(fn(a: Work, b: Work) { int.compare(a.cost, b.cost) })
        |> pq.push(Item(#(0, 0), 0)),
      blocks,
      set.new(),
    )

  io.debug(result)
}

fn walk(
  work: pq.Queue(Work),
  blocks: set.Set(Position),
  seen: set.Set(Position),
) -> option.Option(Int) {
  use <- bool.guard(work |> pq.is_empty, option.None)

  let assert Ok(#(item, work)) = work |> pq.pop
  let Item(position, cost) = item
  let #(x, y) = position
  //print_map_position(position, blocks, seen)

  use <- bool.lazy_guard(x == max && y == max, fn() { option.Some(cost) })

  let #(work, seen) = case blocks |> set.contains(position) {
    True -> #(work, seen)
    False ->
      [#(x + 1, y), #(x, y + 1), #(x - 1, y), #(x, y - 1)]
      |> list.fold(#(work, seen), fn(acc, position) {
        let #(work, seen) = acc
        let #(x, y) = position

        use <- bool.guard(
          seen |> set.contains(position) || x < 0 || y < 0 || x > max || y > max,
          #(work, seen),
        )

        #(
          work |> pq.push(Item(position, cost + 1)),
          seen |> set.insert(position),
        )
      })
  }

  walk(work, blocks, seen)
}

fn parse(content: String) -> set.Set(Position) {
  content
  |> string.split(on: "\n")
  |> list.filter(fn(line) { !string.is_empty(line) })
  |> list.take(fallen)
  |> list.map(fn(line) {
    let assert Ok(#(x, y)) = line |> string.split_once(",")

    let assert Ok(x) = x |> int.parse
    let assert Ok(y) = y |> int.parse

    #(x, y)
  })
  |> set.from_list
}

fn print_map(blocks: set.Set(Position)) {
  list.each(list.range(0, max), fn(y) {
    list.each(list.range(0, max), fn(x) {
      io.print(case blocks |> set.contains(#(x, y)) {
        True -> "#"
        False -> "."
      })
    })
    io.print("\n")
  })
  io.print("\n")
}

fn print_map_position(
  position: Position,
  blocks: set.Set(Position),
  seen: set.Set(Position),
) {
  list.each(list.range(0, max), fn(y) {
    list.each(list.range(0, max), fn(x) {
      io.print({
        use <- bool.guard(x == position.0 && y == position.1, "O")
        use <- bool.guard(blocks |> set.contains(#(x, y)), "#")
        use <- bool.guard(seen |> set.contains(#(x, y)), ".")

        " "
      })
    })
    io.print("\n")
  })
  io.print("\n")
}
