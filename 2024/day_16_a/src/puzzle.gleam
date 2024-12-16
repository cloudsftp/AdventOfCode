import gleam/bool
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/result
import gleam/set
import gleam/string
import gleamy/priority_queue as pq
import simplifile

pub fn main() {
  let assert Ok(content) = simplifile.read("input")
  let #(start, end, walls) = parse(content)

  let result = find_shortest_path(start, end, walls)

  io.debug(result)
}

type Direction {
  North
  East
  South
  West
}

type Work {
  Item(position: #(Int, Int), direction: Direction, score: Int)
}

fn find_shortest_path(
  start: #(Int, Int),
  end: #(Int, Int),
  walls: set.Set(#(Int, Int)),
) -> Int {
  let work =
    pq.new(fn(a: Work, b: Work) { int.compare(a.score, b.score) })
    |> pq.push(Item(start, East, 0))

  find_shortest_path_rec(work, end, walls, dict.new())
}

fn find_shortest_path_rec(
  work: pq.Queue(Work),
  end: #(Int, Int),
  walls: set.Set(#(Int, Int)),
  min_cost: dict.Dict(#(#(Int, Int), Direction), Int),
) -> Int {
  let assert Ok(#(Item(position, direction, score), work)) = work |> pq.pop

  use <- bool.guard(position == end, score)

  let add_item = fn(
    work: pq.Queue(Work),
    min_cost: dict.Dict(#(#(Int, Int), Direction), Int),
    item: Work,
  ) -> #(pq.Queue(Work), dict.Dict(#(#(Int, Int), Direction), Int)) {
    let min_cost_access = min_cost |> dict.get(#(item.position, item.direction))

    use <- bool.guard(
      result.is_ok(min_cost_access)
        && {
        let assert Ok(min_cost_value) = min_cost_access
        min_cost_value < item.score
      },
      #(work, min_cost),
    )

    #(
      work
        |> pq.push(item),
      min_cost
        |> dict.upsert(#(item.position, item.direction), fn(_) { item.score }),
    )
  }

  let #(work, min_cost) = case walls |> set.contains(position) {
    True -> #(work, min_cost)
    False -> {
      let #(work, min_cost) =
        add_item(
          work,
          min_cost,
          Item(position |> walk(direction), direction, score + 1),
        )
      let #(work, min_cost) =
        add_item(
          work,
          min_cost,
          Item(position, direction |> turn_left, score + 1000),
        )
      add_item(
        work,
        min_cost,
        Item(position, direction |> turn_right, score + 1000),
      )
    }
  }

  find_shortest_path_rec(work, end, walls, min_cost)
}

fn walk(position: #(Int, Int), direction: Direction) -> #(Int, Int) {
  let #(i, j) = position
  case direction {
    North -> #(i - 1, j)
    East -> #(i, j + 1)
    South -> #(i + 1, j)
    West -> #(i, j - 1)
  }
}

fn turn_right(direction: Direction) -> Direction {
  case direction {
    North -> East
    East -> South
    South -> West
    West -> North
  }
}

fn turn_left(direction: Direction) -> Direction {
  case direction {
    North -> West
    East -> North
    South -> East
    West -> South
  }
}

fn parse(content: String) -> #(#(Int, Int), #(Int, Int), set.Set(#(Int, Int))) {
  let assert #(option.Some(start), option.Some(end), walls) =
    content
    |> string.split(on: "\n")
    |> list.filter(fn(line) { !string.is_empty(line) })
    |> list.index_fold(#(option.None, option.None, set.new()), fn(acc, line, i) {
      line
      |> string.to_graphemes
      |> list.index_fold(acc, fn(acc, char, j) {
        let #(start, end, walls) = acc

        case char {
          "S" -> {
            use <- bool.lazy_guard(option.is_some(start), fn() { panic })
            #(option.Some(#(i, j)), end, walls)
          }
          "E" -> {
            use <- bool.lazy_guard(option.is_some(end), fn() { panic })
            #(start, option.Some(#(i, j)), walls)
          }
          "#" -> #(start, end, walls |> set.insert(#(i, j)))
          _ -> acc
        }
      })
    })

  #(start, end, walls)
}
