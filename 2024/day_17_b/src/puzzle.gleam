import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import glearray
import simplifile

type Operator {
  DivideA
  XorB
  Mod8B
  JumpNonZeroA
  XorBC
  Out
  DivideAB
  DivideAC
}

type Machine {
  Computer(a: Int, b: Int, c: Int, pc: Int, out: List(Int))
}

pub fn main() {
  let assert Ok(content) = simplifile.read("input")
  let #(computer, program, code) = parse(content)

  print_program(program)
  io.println("")

  let a = compute_a(code, program, computer)

  let Computer(_, b, c, pc, out) = computer
  let output = evaluate(program, Computer(a, b, c, pc, out))
  let result =
    output
    |> list.fold_right("", fn(acc, value) {
      use <- bool.guard(acc |> string.is_empty, value |> int.to_string)
      value |> int.to_string <> "," <> acc
    })
  io.println(a |> int.to_string <> ": " <> result)
}

fn compute_a(
  code: List(Int),
  program: glearray.Array(#(Operator, Int)),
  computer: Machine,
) -> Int {
  code
  |> list.fold_right(0, fn(a, expected_first) {
    io.debug(a)
    let a = a |> int.bitwise_shift_left(3)

    let assert Ok(a) =
      list.range(a, a + 8)
      |> list.find(fn(a) {
        let Computer(_, b, c, pc, out) = computer
        let assert [first, ..] =
          io.debug(evaluate(program, Computer(a, b, c, pc, out)))

        first == expected_first
      })

    a
  })
}

fn combo(operand: Int, a: Int, b: Int, c: Int) -> Int {
  case operand {
    operand if 0 <= operand && operand < 4 -> operand
    4 -> a
    5 -> b
    6 -> c
    _ -> {
      io.println("encountered illegal literal: " <> operand |> int.to_string)
      panic
    }
  }
}

fn divide(operand: Int, a: Int, b: Int, c: Int) -> Int {
  a |> int.bitwise_shift_right(operand |> combo(a, b, c))
}

fn evaluate(
  program: glearray.Array(#(Operator, Int)),
  computer: Machine,
) -> List(Int) {
  use <- bool.guard(
    computer.pc < 0 || program |> glearray.length <= computer.pc,
    computer.out |> list.reverse,
  )

  let assert Ok(#(operator, operand)) = program |> glearray.get(computer.pc)

  //print_instruction(#(operator, operand), computer)

  let Computer(a, b, c, pc, out) = computer
  let computer = case operator {
    DivideA -> Computer(divide(operand, a, b, c), b, c, pc + 1, out)
    XorB -> Computer(a, b |> int.bitwise_exclusive_or(operand), c, pc + 1, out)
    Mod8B -> Computer(a, combo(operand, a, b, c) % 8, c, pc + 1, out)
    JumpNonZeroA -> {
      let pc = case a == 0 {
        True -> pc + 1
        False -> {
          use <- bool.lazy_guard(operand % 2 == 1, fn() {
            io.println("you fucked up, jump to: " <> operand |> int.to_string)
            panic
          })

          operand
        }
      }
      Computer(a, b, c, pc, out)
    }
    XorBC -> Computer(a, b |> int.bitwise_exclusive_or(c), c, pc + 1, out)
    Out -> Computer(a, b, c, pc + 1, [combo(operand, a, b, c) % 8, ..out])
    DivideAB -> Computer(a, divide(operand, a, b, c), c, pc + 1, out)
    DivideAC -> Computer(a, b, divide(operand, a, b, c), pc + 1, out)
  }

  evaluate(program, computer)
}

fn parse(
  content: String,
) -> #(Machine, glearray.Array(#(Operator, Int)), List(Int)) {
  let assert Ok(#(registers, program)) =
    content |> string.split_once(on: "\n\n")

  let assert [a, b, c] =
    registers
    |> string.split(on: "\n")
    |> list.map(fn(line) {
      let assert Ok(#(_, value)) =
        line
        |> string.split_once(on: ": ")

      let assert Ok(value) =
        value
        |> int.parse

      value
    })

  let assert Ok(#(_, program)) =
    program
    |> string.trim
    |> string.split_once(on: ": ")

  let code =
    program
    |> string.split(on: ",")
    |> list.map(fn(value) {
      let assert Ok(value) = value |> int.parse
      value
    })

  let program =
    {
      program
      |> string.split(on: ",")
      |> list.fold_right(#([], option.None), fn(acc, value) {
        let #(program, operand) = acc
        case operand {
          option.None -> {
            let assert Ok(operand) = value |> int.parse
            #(program, option.Some(operand))
          }
          option.Some(operand) -> {
            let operator = case value {
              "0" -> DivideA
              "1" -> XorB
              "2" -> Mod8B
              "3" -> JumpNonZeroA
              "4" -> XorBC
              "5" -> Out
              "6" -> DivideAB
              "7" -> DivideAC
              _ -> panic
            }
            #([#(operator, operand), ..program], option.None)
          }
        }
      })
    }.0
    |> glearray.from_list

  #(Computer(a, b, c, 0, []), program, code)
}

fn print_instruction(instruction: #(Operator, Int), computer: Machine) {
  let Computer(a, b, c, _, _) = computer
  let #(operator, operand) = instruction

  let combo_operand = case operand {
    operand if 0 <= operand && operand <= 3 -> operand |> int.to_string
    4 -> "a"
    5 -> "b"
    6 -> "c"
    _ -> panic
  }
  let operand = operand |> int.to_string
  let a = a |> int.to_string
  let b = b |> int.to_string
  let c = c |> int.to_string

  io.println(
    "A: "
    <> computer.a |> int.to_base_string(2) |> result.unwrap("-")
    <> "\nB: "
    <> computer.b |> int.to_base_string(2) |> result.unwrap("-")
    <> "\nC: "
    <> computer.c |> int.to_base_string(2) |> result.unwrap("-")
    <> "\n",
  )

  io.println("state -\ta: " <> a <> ",\tb: " <> b <> ",\tc: " <> c)
  io.println(
    "out   -\t " <> computer.out |> list.map(int.to_string) |> string.join(","),
  )
  io.println("")
  io.println("#######################")
  io.println("")
  io.println(case operator {
    DivideA -> "a >> " <> combo_operand <> " -> a"
    XorB -> "b xor " <> operand <> " -> b"
    Mod8B -> combo_operand <> " mod 8 -> b"
    JumpNonZeroA -> "goto " <> operand <> " if a == 0"
    XorBC -> "b xor c -> b"
    Out -> combo_operand <> " % 8 -> out"
    DivideAB -> "a >> " <> combo_operand <> " -> b"
    DivideAC -> "a >> " <> combo_operand <> " -> c"
  })
  io.println("")
}

fn print_program(program: glearray.Array(#(Operator, Int))) {
  let program =
    program
    |> glearray.to_list
    |> list.index_map(fn(instruction, i) {
      let #(operator, operand) = instruction
      let operand = operand |> int.to_string
      i |> int.to_string
      <> ": "
      <> case operator {
        DivideA -> "a >> combo " <> operand <> " -> a"
        XorB -> "b xor lit " <> operand <> " -> b"
        Mod8B -> "combo " <> operand <> " mod 8 -> b"
        JumpNonZeroA -> "goto lit " <> operand <> " if a == 0"
        XorBC -> "b xor c -> b"
        Out -> "combo " <> operand <> " % 8 -> out"
        DivideAB -> "a >> " <> operand <> " -> b"
        DivideAC -> "a >> " <> operand <> " -> c"
      }
    })
    |> string.join("\n")

  io.println(program)
}
