import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/result
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

fn get_warehouse() -> #(Grid(String), Position, List(Direction)) {
  let assert Ok(data) = simplifile.read("src/data/15.txt")

  let #(warehouse, instructions) =
    data
    |> string.split("\n")
    |> list.split_while(fn(line) { line != "" })

  let warehouse =
    warehouse |> string.join("\n") |> grid.to_list_of_lists() |> grid.to_grid()
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

fn move(
  warehouse: Grid(String),
  position: Position,
  direction: Direction,
  object: String,
) -> #(Bool, Position, Grid(String)) {
  let new_position = next_position(position, direction)
  let contents = get_position(warehouse, new_position)

  case contents {
    "Out of Bounds" -> #(False, position, warehouse)
    "#" -> #(False, position, warehouse)
    "." -> #(
      True,
      new_position,
      warehouse
        |> set_position(position, ".")
        |> set_position(new_position, object),
    )
    other -> {
      let #(movable, _, new_warehouse) =
        move(warehouse, new_position, direction, other)

      case movable {
        False -> #(False, position, warehouse)
        True -> #(
          True,
          new_position,
          new_warehouse
            |> set_position(position, ".")
            |> set_position(new_position, object),
        )
      }
    }
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
    let #(_, new_position, warehouse) =
      move(warehouse, position, instruction, "@")
    #(warehouse, new_position)
  })
  |> fn(x) { x.0 }
}

fn gps_count(warehouse: Grid(String)) -> Int {
  warehouse
  |> dict.filter(fn(_, value) { value == "O" })
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
