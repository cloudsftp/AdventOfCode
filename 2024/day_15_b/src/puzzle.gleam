import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/result
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
  let #(height, width, walls, boxes, robot, movements) = parse(content)

  let #(boxes, robot) =
    movements
    |> list.fold(#(boxes, robot), fn(acc, movement) {
      let #(boxes, robot) = acc
      //print_field(walls, boxes, robot, height, width, movement)
      //process.sleep(1000)

      let moved_robot = robot |> move(movement)

      use <- bool.guard(walls |> set.contains(moved_robot), acc)

      case moved_robot |> robot_collides_with_box(boxes) {
        option.None -> {
          #(boxes, moved_robot)
        }
        option.Some(box) -> {
          case box |> move_boxes(boxes, walls, movement) {
            option.None -> acc
            option.Some(#(to_delete, to_insert)) -> #(
              boxes
                |> set.difference(to_delete)
                |> set.union(to_insert),
              moved_robot,
            )
          }
        }
      }
    })
  print_field(walls, boxes, robot, height, width, Down)

  let result =
    boxes
    |> set.to_list
    |> list.map(fn(box) {
      let #(i, j) = box
      100 * i + j
    })
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
) -> option.Option(#(set.Set(#(Int, Int)), set.Set(#(Int, Int)))) {
  move_boxes_rec(position, boxes, walls, movement, set.new(), set.new())
}

fn move_boxes_rec(
  position: #(Int, Int),
  boxes: set.Set(#(Int, Int)),
  walls: set.Set(#(Int, Int)),
  movement: Movement,
  to_delete: set.Set(#(Int, Int)),
  to_insert: set.Set(#(Int, Int)),
) -> option.Option(#(set.Set(#(Int, Int)), set.Set(#(Int, Int)))) {
  let next_position = position |> move(movement)

  use <- bool.guard(next_position |> box_collides_with_wall(walls), option.None)

  let to_delete = to_delete |> set.insert(position)
  let to_insert = to_insert |> set.insert(next_position)

  let collisions = position |> box_collides_with_box(boxes, movement)

  collisions
  |> list.fold(option.Some(#(to_delete, to_insert)), fn(acc, collision) {
    use <- bool.guard(acc |> option.is_none, option.None)

    let recursion =
      move_boxes_rec(collision, boxes, walls, movement, to_delete, to_insert)

    use <- bool.guard(recursion |> option.is_none, option.None)

    let assert option.Some(#(to_delete_old, to_insert_old)) = acc
    let assert option.Some(#(to_delete_new, to_insert_new)) = recursion

    option.Some(#(
      to_delete_old |> set.union(to_delete_new),
      to_insert_old |> set.union(to_insert_new),
    ))
  })
}

fn box_collides_with_wall(box: #(Int, Int), walls: set.Set(#(Int, Int))) -> Bool {
  let #(i, j) = box
  walls |> set.contains(#(i, j)) || walls |> set.contains(#(i, j + 1))
}

fn box_collides_with_box(
  box: #(Int, Int),
  boxes: set.Set(#(Int, Int)),
  movement: Movement,
) -> List(#(Int, Int)) {
  let boxes = boxes |> set.delete(box)
  let moved_box = box |> move(movement)

  let #(i, j) = moved_box
  let left = #(i, j - 1)
  let middle = #(i, j)
  let right = #(i, j + 1)

  let assert [contains_left, contains_middle, contains_right] =
    [left, middle, right]
    |> list.map(fn(position) { boxes |> set.contains(position) })
  case contains_left, contains_middle, contains_right {
    True, False, True -> [left, right]
    False, True, False -> [middle]
    True, False, False -> [left]
    False, False, True -> [right]
    False, False, False -> []
    _, _, _ -> panic
  }
}

fn robot_collides_with_box(
  position: #(Int, Int),
  boxes: set.Set(#(Int, Int)),
) -> option.Option(#(Int, Int)) {
  use <- bool.guard(boxes |> set.contains(position), option.Some(position))

  let #(i, j) = position
  use <- bool.guard(
    boxes |> set.contains(#(i, j - 1)),
    option.Some(#(i, j - 1)),
  )

  option.None
}

fn parse(
  content: String,
) -> #(
  Int,
  Int,
  set.Set(#(Int, Int)),
  set.Set(#(Int, Int)),
  #(Int, Int),
  List(Movement),
) {
  let assert Ok(#(field, movements)) = content |> string.split_once(on: "\n\n")

  let field = field |> string.split(on: "\n")
  let height = field |> list.length
  let assert Ok(width) =
    field
    |> list.first
    |> result.map(fn(first_line) { 2 * { first_line |> string.length } })

  let assert #(walls, boxes, option.Some(robot)) =
    field
    |> list.index_fold(#(set.new(), set.new(), option.None), fn(acc, line, i) {
      line
      |> string.to_graphemes
      |> list.index_fold(acc, fn(acc, char, j) {
        let #(walls, boxes, robot) = acc

        case char {
          "@" -> {
            use <- bool.lazy_guard(robot |> option.is_some, fn() { panic })
            #(walls, boxes, option.Some(#(i, 2 * j)))
          }
          "O" -> #(walls, boxes |> set.insert(#(i, 2 * j)), robot)
          "#" -> #(
            walls |> set.insert(#(i, 2 * j)) |> set.insert(#(i, 2 * j + 1)),
            boxes,
            robot,
          )
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

  #(height, width, walls, boxes, robot, movements)
}

fn print_field(
  walls: set.Set(#(Int, Int)),
  boxes: set.Set(#(Int, Int)),
  robot: #(Int, Int),
  height: Int,
  width: Int,
  movement: Movement,
) {
  io.print("\n")
  list.range(0, height - 1)
  |> list.each(fn(i) {
    list.range(0, width - 1)
    |> list.each(fn(j) {
      use <- bool.lazy_guard(walls |> set.contains(#(i, j)), fn() {
        io.print("#")
      })
      use <- bool.lazy_guard(boxes |> set.contains(#(i, j)), fn() {
        io.print("[")
      })
      use <- bool.lazy_guard(boxes |> set.contains(#(i, j - 1)), fn() {
        io.print("]")
      })
      use <- bool.lazy_guard(robot == #(i, j), fn() {
        io.print(case movement {
          Up -> "^"
          Right -> ">"
          Down -> "v"
          Left -> "<"
        })
      })

      io.print(".")
    })
    io.print("\n")
  })
  io.print("\n")
}
