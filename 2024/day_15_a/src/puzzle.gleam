import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/set
import gleam/string
import simplifile

type Movement {
  Up
  Right
  Down
  Left
}

pub fn main() {
  let assert Ok(content) = simplifile.read("input")
  let #(walls, boxes, robot, movements) = parse(content)

  let #(boxes, _) =
    movements
    |> list.fold(#(boxes, robot), fn(acc, movement) {
      let #(boxes, robot) = acc

      let moved_robot = robot |> move(movement)

      use <- bool.guard(walls |> set.contains(moved_robot), acc)
      use <- bool.guard(!{ boxes |> set.contains(moved_robot) }, #(
        boxes,
        moved_robot,
      ))

      let box = moved_robot

      case box |> move_boxes(boxes, walls, movement) {
        option.None -> acc
        option.Some(moved_box) -> #(
          boxes
            |> set.delete(moved_robot)
            |> set.insert(moved_box),
          moved_robot,
        )
      }
    })

  let result =
    boxes
    |> set.map(fn(box) {
      let #(i, j) = box
      100 * i + j
    })
    |> set.to_list
    |> int.sum

  io.debug(result)
}

fn move(position: #(Int, Int), movement: Movement) -> #(Int, Int) {
  let #(i, j) = position
  case movement {
    Up -> #(i - 1, j)
    Right -> #(i, j + 1)
    Down -> #(i + 1, j)
    Left -> #(i, j - 1)
  }
}

fn move_boxes(
  position: #(Int, Int),
  boxes: set.Set(#(Int, Int)),
  walls: set.Set(#(Int, Int)),
  movement: Movement,
) -> option.Option(#(Int, Int)) {
  let next_position = position |> move(movement)

  use <- bool.guard(walls |> set.contains(next_position), option.None)
  use <- bool.guard(
    !{ boxes |> set.contains(next_position) },
    option.Some(next_position),
  )

  next_position |> move_boxes(boxes, walls, movement)
}

fn parse(
  content: String,
) -> #(set.Set(#(Int, Int)), set.Set(#(Int, Int)), #(Int, Int), List(Movement)) {
  let assert Ok(#(field, movements)) = content |> string.split_once(on: "\n\n")

  let assert #(walls, boxes, option.Some(robot)) =
    field
    |> string.split(on: "\n")
    |> list.index_fold(#(set.new(), set.new(), option.None), fn(acc, line, i) {
      line
      |> string.to_graphemes
      |> list.index_fold(acc, fn(acc, char, j) {
        let #(walls, boxes, robot) = acc

        case char {
          "@" -> {
            use <- bool.lazy_guard(robot |> option.is_some, fn() { panic })
            #(walls, boxes, option.Some(#(i, j)))
          }
          "O" -> #(walls, boxes |> set.insert(#(i, j)), robot)
          "#" -> #(walls |> set.insert(#(i, j)), boxes, robot)
          _ -> acc
        }
      })
    })

  let movements =
    movements
    |> string.to_graphemes
    |> list.fold_right([], fn(movements, char) {
      case char {
        "^" -> [Up, ..movements]
        ">" -> [Right, ..movements]
        "v" -> [Down, ..movements]
        "<" -> [Left, ..movements]
        _ -> movements
      }
    })

  #(walls, boxes, robot, movements)
}
