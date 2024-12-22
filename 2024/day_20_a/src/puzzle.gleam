import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/result
import gleam/set
import gleam/string
import gleamy/priority_queue as pq
import simplifile

type Position =
  #(Int, Int)

type Work {
  Item(
    position: Position,
    cost: Int,
    state: State,
    first_cheat: option.Option(Position),
    second_cheat: option.Option(Position),
  )
}

type State {
  NoShortcut
  StartedShortcut
  FinishedShortcut
}

const min_saved = 21

pub fn main() {
  let assert Ok(content) = simplifile.read("input.small")
  let #(blocks, start, end, height, width) = parse(content)

  let work =
    pq.new(fn(a: Work, b: Work) { a.cost |> int.compare(b.cost) })
    |> pq.push(Item(start, 0, NoShortcut, option.None, option.None))

  let normal_cost = walk_no_cheat(work, blocks, end, set.new())
  io.debug(normal_cost)
  let result = walk(work, blocks, end, normal_cost, width, height, set.new(), 0)

  io.debug(result)
}

fn walk(
  work: pq.Queue(Work),
  blocks: set.Set(Position),
  end: Position,
  normal_cost: Int,
  width: Int,
  height: Int,
  visited: set.Set(
    #(Position, option.Option(Position), option.Option(Position)),
  ),
  count: Int,
) -> Int {
  let assert Ok(#(
    Item(position, cost, state, cheated_first, cheated_second),
    work,
  )) = work |> pq.pop
  let saved_time = normal_cost - cost
  //io.println("\n################")
  //io.println(
  // "popped work item:\n  position: ("
  // <> position.0 |> int.to_string
  // <> ", "
  // <> position.1 |> int.to_string
  // <> "}\n  cost: "
  // <> cost |> int.to_string
  // <> "\n  state: "
  // <> case state {
  //   NoShortcut -> "no shortcut"
  //   StartedShortcut -> "started shortcut"
  //   FinishedShortcut -> "finished shortcut"
  // },
  // )

  let visited =
    visited |> set.insert(#(position, cheated_first, cheated_second))

  use <- bool.lazy_guard(position == end && saved_time < min_saved, fn() {
    count
  })

  let outside = fn(position) {
    let #(i, j) = position
    i < 0 || i >= height || j < 0 || j >= width
  }

  let cost = cost + 1

  let #(work, count) = {
    use <- bool.lazy_guard(position == end, fn() { #(work, count + 1) })

    let state = case state {
      NoShortcut -> NoShortcut
      StartedShortcut -> FinishedShortcut
      FinishedShortcut -> FinishedShortcut
    }

    #(
      next_positions(position)
        |> list.fold(work, fn(work, position) {
          use <- bool.guard(outside(position), work)
          use <- bool.guard(
            visited |> set.contains(#(position, cheated_first, cheated_second)),
            work,
          )
          use <- bool.guard(blocks |> set.contains(position), work)

          //io.println(
          //  "\npushing work item:\n  position: ("
          //  <> position.0 |> int.to_string
          //  <> ", "
          //  <> position.1 |> int.to_string
          //  <> "}\n  cost: "
          //  <> cost |> int.to_string
          //  <> "\n  state: "
          //  <> case state {
          //    NoShortcut -> "no shortcut"
          //    StartedShortcut -> "started shortcut"
          //    FinishedShortcut -> "finished shortcut"
          //  },
          // )

          work
          |> pq.push(Item(position, cost, state, cheated_first, cheated_second))
        }),
      count,
    )
  }

  let #(work, count) = {
    use <- bool.lazy_guard(position == end, fn() { #(work, count + 1) })
    use <- bool.guard(state == FinishedShortcut, #(work, count))

    let #(state, cheated_first, cheated_second) = case state {
      NoShortcut -> #(StartedShortcut, option.Some(position), cheated_second)
      StartedShortcut -> #(
        FinishedShortcut,
        cheated_first,
        option.Some(position),
      )
      FinishedShortcut -> panic
    }

    #(
      next_positions(position)
        |> list.fold(work, fn(work, position) {
          use <- bool.guard(outside(position), work)
          use <- bool.guard(!{ blocks |> set.contains(position) }, work)
          use <- bool.guard(
            visited |> set.contains(#(position, cheated_first, cheated_second)),
            work,
          )

          //io.println(
          //  "\npushing work item:\n  position: ("
          //  <> position.0 |> int.to_string
          //  <> ", "
          //  <> position.1 |> int.to_string
          //  <> "}\n  cost: "
          //  <> cost |> int.to_string
          //  <> "\n  state: "
          //  <> case state {
          //    NoShortcut -> "no shortcut"
          //    StartedShortcut -> "started shortcut"
          //    FinishedShortcut -> "finished shortcut"
          //  },
          // )
          work
          |> pq.push(Item(position, cost, state, cheated_first, cheated_second))
        }),
      count,
    )
  }

  walk(work, blocks, end, normal_cost, width, height, visited, count)
}

fn walk_no_cheat(
  work: pq.Queue(Work),
  blocks: set.Set(Position),
  end: Position,
  visited: set.Set(Position),
) -> Int {
  let assert Ok(#(Item(position, cost, _, _, _), work)) = work |> pq.pop

  use <- bool.guard(position == end, cost)

  let work =
    next_positions(position)
    |> list.fold(work, fn(work, position) {
      use <- bool.guard(blocks |> set.contains(position), work)
      use <- bool.guard(visited |> set.contains(position), work)

      work
      |> pq.push(Item(position, cost + 1, NoShortcut, option.None, option.None))
    })

  walk_no_cheat(work, blocks, end, visited |> set.insert(position))
}

fn next_positions(position: Position) -> List(Position) {
  let #(i, j) = position
  [#(i - 1, j), #(i, j + 1), #(i + 1, j), #(i, j - 1)]
}

fn parse(content: String) -> #(set.Set(Position), Position, Position, Int, Int) {
  let lines =
    content
    |> string.split(on: "\n")
    |> list.filter(fn(line) { !string.is_empty(line) })
  let height = lines |> list.length
  let assert Ok(width) = lines |> list.first |> result.map(string.length)

  let assert #(blocks, option.Some(start), option.Some(end)) =
    lines
    |> list.index_fold(#(set.new(), option.None, option.None), fn(acc, line, i) {
      line
      |> string.to_graphemes
      |> list.index_fold(acc, fn(acc, char, j) {
        let #(blocks, start, end) = acc

        case char {
          "S" -> #(blocks, option.Some(#(i, j)), end)
          "E" -> #(blocks, start, option.Some(#(i, j)))
          "#" -> #(blocks |> set.insert(#(i, j)), start, end)
          _ -> acc
        }
      })
    })

  #(blocks, start, end, height, width)
}
