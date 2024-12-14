import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/set
import gleam/string
import simplifile

const height = 103

const width = 101

type Player {
  Robot(start: #(Int, Int), velocity: #(Int, Int))
}

pub fn main() {
  let assert Ok(content) = simplifile.read("input")
  let robots = parse_robots(content)

  let positions = robots |> walk100

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

  io.debug(q1 * q2 * q3 * q4)
}

fn walk100(robots: List(Player)) -> List(#(Int, Int)) {
  robots
  |> list.map(fn(robot) {
    let #(x, y) = robot.start
    let #(dx, dy) = robot.velocity

    let x = x + 100 * dx
    let y = y + 100 * dy

    let normalize = fn(value, maximum) {
      let value = value % maximum

      use <- bool.guard(value >= 0, value)
      value + maximum
    }

    let x = normalize(x, width)
    let y = normalize(y, height)

    #(x, y)
  })
}

fn parse_robots(content: String) -> List(Player) {
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
    Robot(extract_tuple(position), extract_tuple(velocity))
  })
}
