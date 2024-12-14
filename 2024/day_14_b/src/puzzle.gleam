import gleam/bool
import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/list
import gleam/set
import gleam/string
import simplifile

const height = 103

const width = 101

pub fn main() {
  let assert Ok(content) = simplifile.read("input")
  let #(start_positions, velocities) = parse_robots(content)

  let first_score = safety_score(start_positions)

  let #(_, min_time) =
    list.range(0, height * width - 1)
    |> list.map(fn(time) {
      let positions = walk_n(start_positions, velocities, time)

      safety_score(positions)
    })
    |> list.index_fold(#(first_score, 0), fn(acc, score, time) {
      let #(min_score, _) = acc
      use <- bool.guard(score > min_score, acc)
      #(score, time)
    })

  io.debug(min_time)

  print_field(walk_n(start_positions, velocities, min_time), min_time)
}

fn walk_n(
  positions: List(#(Int, Int)),
  velocities: List(#(Int, Int)),
  n: Int,
) -> List(#(Int, Int)) {
  let #(positions, _) =
    positions
    |> list.zip(velocities)
    |> list.map(fn(robot) {
      let normalize = fn(value, maximum) {
        let value = value % maximum

        use <- bool.guard(value >= 0, value)
        value + maximum
      }

      let #(#(x, y), #(dx, dy)) = robot
      #(#(normalize(x + n * dx, width), normalize(y + n * dy, height)), #(
        dx,
        dy,
      ))
    })
    |> list.unzip

  positions
}

fn safety_score(positions: List(#(Int, Int))) -> Int {
  let #(q1, q2, q3, q4) =
    positions
    |> list.fold(#(0, 0, 0, 0), fn(acc, position) {
      let #(q1, q2, q3, q4) = acc
      case position {
        #(x, y) if y < height / 2 && x < width / 2 -> #(q1 + 1, q2, q3, q4)
        #(x, y) if y < height / 2 && x > width / 2 -> #(q1, q2 + 1, q3, q4)
        #(x, y) if y > height / 2 && x < width / 2 -> #(q1, q2, q3 + 1, q4)
        #(x, y) if y > height / 2 && x > width / 2 -> #(q1, q2, q3, q4 + 1)
        _ -> acc
      }
    })

  q1 * q2 * q3 * q4
}

fn step_forever(
  positions: List(#(Int, Int)),
  velocities: List(#(Int, Int)),
  time: Int,
) {
  let #(positions, _) =
    positions
    |> list.zip(velocities)
    |> list.map(fn(robot) {
      let normalize = fn(value, maximum) {
        let value = value % maximum

        use <- bool.guard(value >= 0, value)
        value + maximum
      }

      let #(#(x, y), #(dx, dy)) = robot
      #(#(normalize(x + dx, width), normalize(y + dy, height)), #(dx, dy))
    })
    |> list.unzip

  process.sleep(50)
  step_forever(positions, velocities, time + 1)
}

fn print_field(positions: List(#(Int, Int)), time: Int) {
  io.println("t = " <> time |> int.to_string)
  let fields = set.from_list(positions)
  list.range(0, height - 1)
  |> list.each(fn(y) {
    list.range(0, width - 1)
    |> list.each(fn(x) {
      case fields |> set.contains(#(x, y)) {
        True -> io.print("#")
        False -> io.print(" ")
      }
    })

    io.print("\n")
  })
  io.print("\n")
}

fn parse_robots(content: String) -> #(List(#(Int, Int)), List(#(Int, Int))) {
  content
  |> string.split(on: "\n")
  |> list.filter(fn(line) { !string.is_empty(line) })
  |> list.map(fn(line) {
    let extract_tuple = fn(part) {
      let assert Ok(#(x, y)) =
        part
        |> string.drop_start(2)
        |> string.split_once(",")

      let assert Ok(x) = x |> int.parse
      let assert Ok(y) = y |> int.parse

      #(x, y)
    }

    let assert Ok(#(position, velocity)) = line |> string.split_once(on: " ")
    #(extract_tuple(position), extract_tuple(velocity))
  })
  |> list.unzip
}
