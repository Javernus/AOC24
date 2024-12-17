import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{Some}
import gleam/regexp
import gleam/result
import gleam/string
import simplifile

type Register {
  RegisterA
  RegisterB
  RegisterC
}

type Opcode {
  Adv0
  Bxl1
  Bst2
  Jnz3
  Bxc4
  Out5
  Bdv6
  Cdv7
}

type Registers =
  #(Int, Int, Int)

type Instructions =
  List(Int)

type Machine =
  #(Registers, Instructions, Int, List(Int))

fn get_data() -> String {
  let assert Ok(data) = simplifile.read("src/data/17.txt")
  data
}

fn parse_register(data: String) -> Registers {
  let assert Ok(register_re) = regexp.from_string("Register [A|B|C]: (\\d+)")
  let registers = regexp.scan(with: register_re, content: data)

  registers
  |> list.map(fn(match) {
    case match {
      regexp.Match(_, [Some(x)]) -> {
        let assert Ok(x) = int.parse(x)

        x
      }
      _ -> -1
    }
  })
  |> fn(x) {
    case x {
      [a, b, c] -> #(a, b, c)
      _ -> #(0, 0, 0)
    }
  }
}

fn get_opcode(i: Int) -> Opcode {
  case i {
    0 -> Adv0
    1 -> Bxl1
    2 -> Bst2
    3 -> Jnz3
    4 -> Bxc4
    5 -> Out5
    6 -> Bdv6
    7 -> Cdv7
    _ -> Adv0
  }
}

fn parse_instructions(data: String) -> Instructions {
  let assert Ok(register_re) = regexp.from_string("Program: ((?:[\\d],)+\\d)")
  let instructions = regexp.scan(with: register_re, content: data)

  case list.first(instructions) {
    Ok(regexp.Match(_, [Some(x)])) -> {
      list.filter_map(string.split(x, ","), fn(x) { int.parse(x) })
    }
    _ -> []
  }
}

fn parse_data(data: String) -> Machine {
  let registers = parse_register(data)
  let instructions = parse_instructions(data)

  #(registers, instructions, 0, [])
}

fn update_register(machine: Machine, register: Register, value: Int) -> Machine {
  let registers = machine.0
  #(
    case register {
      RegisterA -> #(value, registers.1, registers.2)
      RegisterB -> #(registers.0, value, registers.2)
      RegisterC -> #(registers.0, registers.1, value)
    },
    machine.1,
    machine.2,
    machine.3,
  )
}

fn read_instruction(
  instructions: Instructions,
  ic: Int,
) -> Result(#(Opcode, Int), Nil) {
  let l = list.take(list.drop(instructions, ic), 2)

  case l {
    [a, b] -> Ok(#(get_opcode(a), b))
    _ -> Error(Nil)
  }
}

fn get_operand(machine: Machine, opcode: Opcode, operand: Int) -> Int {
  let combo = case operand {
    4 -> machine.0.0
    5 -> machine.0.1
    6 -> machine.0.2
    _ -> operand
  }

  case opcode {
    Adv0 -> combo
    Bxl1 -> operand
    Bst2 -> combo
    Jnz3 -> operand
    Bxc4 -> operand
    Out5 -> combo
    Bdv6 -> combo
    Cdv7 -> combo
  }
}

fn increase_ic(machine: Machine) -> Machine {
  #(machine.0, machine.1, machine.2 + 2, machine.3)
}

fn execute(machine: Machine) -> Machine {
  let instruction = read_instruction(machine.1, machine.2)
  use <- bool.guard(result.is_error(instruction), machine)
  let #(opcode, operand) = result.unwrap(instruction, #(Adv0, 0))

  let operand = get_operand(machine, opcode, operand)

  let machine = case opcode {
    Adv0 -> {
      update_register(
        machine,
        RegisterA,
        machine.0.0 / { int.product(list.repeat(2, operand)) },
      )
      |> increase_ic
    }
    Bxl1 -> {
      update_register(
        machine,
        RegisterB,
        int.bitwise_exclusive_or(machine.0.1, operand),
      )
      |> increase_ic
    }
    Bst2 -> {
      update_register(machine, RegisterB, {
        let assert Ok(x) = int.modulo(operand, 8)
        x
      })
      |> increase_ic
    }
    Jnz3 -> {
      case machine.0.0 {
        0 -> increase_ic(machine)
        _ -> {
          #(machine.0, machine.1, operand, machine.3)
        }
      }
    }
    Bxc4 -> {
      update_register(
        machine,
        RegisterB,
        int.bitwise_exclusive_or(machine.0.1, machine.0.2),
      )
      |> increase_ic
    }
    Out5 -> {
      let assert Ok(output) = int.modulo(operand, 8)
      #(machine.0, machine.1, machine.2, list.append(machine.3, [output]))
      |> increase_ic
    }
    Bdv6 -> {
      update_register(
        machine,
        RegisterB,
        machine.0.0 / { int.product(list.repeat(2, operand)) },
      )
      |> increase_ic
    }
    Cdv7 -> {
      update_register(
        machine,
        RegisterC,
        machine.0.0 / { int.product(list.repeat(2, operand)) },
      )
      |> increase_ic
    }
  }

  io.debug(machine)

  execute(machine)
}

fn run_program(machine: Machine) -> List(Int) {
  let machine = execute(machine)
  io.debug(machine)
  machine.3
}

pub fn main() {
  let data = get_data()

  parse_data(data)
  |> run_program
  |> list.map(int.to_string)
  |> string.join(",")
  |> io.println
}
