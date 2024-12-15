import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/order
import gleam/result
import gleam/set.{type Set}
import gleam/string
import simplifile
import utilities/grid.{type Grid, type Position, Position}

type Direction {
  Up
  Down
  Left
  Right
}

fn to_direction(character: String) -> Result(Direction, Nil) {
  case character {
    "^" -> Ok(Up)
    ">" -> Ok(Right)
    "v" -> Ok(Down)
    "<" -> Ok(Left)
    _ -> Error(Nil)
  }
}

fn rework_warehouse(data: String) -> String {
  data
  |> string.to_graphemes
  |> list.map(fn(s) {
    case s {
      "#" -> "##"
      "O" -> "[]"
      "@" -> "@."
      "." -> ".."
      "\n" -> "\n"
      _ -> "  "
    }
  })
  |> string.concat
}

fn get_warehouse() -> #(Grid(String), Position, List(Direction)) {
  let assert Ok(data) = simplifile.read("src/data/15.txt")

  let #(warehouse, instructions) =
    data
    |> string.split("\n")
    |> list.split_while(fn(line) { line != "" })

  let warehouse =
    warehouse
    |> string.join("\n")
    |> rework_warehouse
    |> grid.to_list_of_lists()
    |> grid.to_grid()

  let starting_point = warehouse |> get_starting_position

  let instructions =
    instructions
    |> list.filter(fn(x) { x != "" })
    |> string.concat
    |> string.to_graphemes
    |> list.map(to_direction)
    |> list.map(fn(x) { result.unwrap(x, Up) })

  #(warehouse, starting_point, instructions)
}

fn get_starting_position(warehouse: Grid(String)) -> Position {
  let assert Ok(starting_point) =
    warehouse
    |> dict.filter(fn(_, value) { value == "@" })
    |> dict.keys
    |> list.first

  starting_point
}

fn get_position(warehouse: Grid(String), position: Position) -> String {
  warehouse
  |> dict.get(position)
  |> result.unwrap("Out of Bounds")
}

fn next_position(position: Position, direction: Direction) -> Position {
  case direction {
    Up -> Position(position.r - 1, position.c)
    Down -> Position(position.r + 1, position.c)
    Left -> Position(position.r, position.c - 1)
    Right -> Position(position.r, position.c + 1)
  }
}

fn set_position(
  warehouse: Grid(String),
  position: Position,
  object: String,
) -> Grid(String) {
  warehouse
  |> dict.insert(position, object)
}

fn early_return(bool, return, callback) {
  case bool {
    False -> return
    True -> callback()
  }
}

fn can_move_horizontal(
  warehouse: Grid(String),
  position: Position,
  direction: Direction,
) -> #(Bool, Set(Position)) {
  let new_position = next_position(position, direction)
  let contents = get_position(warehouse, new_position)

  case contents {
    "[" -> {
      let #(movable, s) =
        can_move_horizontal(warehouse, new_position, direction)
      use <- early_return(movable, #(False, set.new()))

      #(True, s |> set.insert(position))
    }
    "]" -> {
      let #(movable, s) =
        can_move_horizontal(warehouse, new_position, direction)
      use <- early_return(movable, #(False, set.new()))

      #(True, s |> set.insert(position))
    }
    "." -> #(True, set.new() |> set.insert(position))
    _ -> #(False, set.new())
  }
}

fn can_move_vertical(
  warehouse: Grid(String),
  position: Position,
  direction: Direction,
) -> #(Bool, Set(Position)) {
  let new_position = next_position(position, direction)

  let contents = get_position(warehouse, new_position)

  case contents {
    "[" -> {
      let #(movable, s) = can_move_vertical(warehouse, new_position, direction)
      use <- early_return(movable, #(False, set.new()))

      let other_position = next_position(new_position, Right)
      let #(movable, s2) =
        can_move_vertical(warehouse, other_position, direction)
      use <- early_return(movable, #(False, set.new()))

      #(True, set.union(s, s2) |> set.insert(position))
    }
    "]" -> {
      let #(movable, s) = can_move_vertical(warehouse, new_position, direction)
      use <- early_return(movable, #(False, set.new()))

      let other_position = next_position(new_position, Left)
      let #(movable, s2) =
        can_move_vertical(warehouse, other_position, direction)
      use <- early_return(movable, #(False, set.new()))

      #(True, set.union(s, s2) |> set.insert(position))
    }
    "." -> #(True, set.new() |> set.insert(position))
    _ -> #(False, set.new())
  }
}

fn can_move(
  warehouse: Grid(String),
  position: Position,
  direction: Direction,
) -> #(Bool, Set(Position)) {
  case direction {
    Up -> can_move_vertical(warehouse, position, direction)
    Down -> can_move_vertical(warehouse, position, direction)
    Left -> can_move_horizontal(warehouse, position, direction)
    Right -> can_move_horizontal(warehouse, position, direction)
  }
}

fn grouping(position: Position, direction: Direction) -> Int {
  let Position(x, y) = position

  case direction {
    Up -> x
    Right -> -y
    Down -> -x
    Left -> y
  }
}

fn move_all(
  warehouse: Grid(String),
  positions: Set(Position),
  direction: Direction,
) -> Grid(String) {
  positions
  |> set.to_list
  |> list.group(fn(position) { grouping(position, direction) })
  |> dict.to_list
  |> list.sort(fn(x, x2) {
    case x.0 < x2.0 {
      True -> order.Lt
      False -> order.Gt
    }
  })
  |> list.fold(warehouse, fn(warehouse, x) {
    list.fold(x.1, warehouse, fn(warehouse, x) {
      let object = get_position(warehouse, x)
      let new_position = next_position(x, direction)
      warehouse
      |> set_position(new_position, object)
      |> set_position(x, ".")
    })
  })
}

fn move(
  warehouse: Grid(String),
  position: Position,
  direction: Direction,
) -> #(Grid(String), Position) {
  let #(movable, to_move) = can_move(warehouse, position, direction)

  case movable {
    False -> #(warehouse, position)
    True -> #(
      move_all(warehouse, to_move, direction),
      next_position(position, direction),
    )
  }
}

fn robot_walk(
  warehouse: Grid(String),
  position: Position,
  instructions: List(Direction),
) -> Grid(String) {
  instructions
  |> list.fold(#(warehouse, position), fn(acc, instruction) {
    let #(warehouse, position) = acc
    move(warehouse, position, instruction)
  })
  |> fn(x) { x.0 }
}

fn gps_count(warehouse: Grid(String)) -> Int {
  grid.print(warehouse)
  warehouse
  |> dict.filter(fn(_, value) { value == "[" })
  |> dict.to_list
  |> list.map(fn(key) {
    let Position(x, y) = key.0
    x * 100 + y
  })
  |> int.sum
}

pub fn main() {
  let #(warehouse, start, instructions) = get_warehouse()

  warehouse
  |> robot_walk(start, instructions)
  |> gps_count
  |> int.to_string
  |> io.println
}
