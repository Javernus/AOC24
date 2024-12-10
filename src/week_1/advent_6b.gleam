import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/set.{type Set}
import parallel_map.{WorkerAmount, list_pmap}
import simplifile
import utilities/grid.{type Grid, type Position, Position}

type Visited =
  Set(#(Position, Direction))

type Direction {
  Up
  Down
  Left
  Right
}

pub fn get_grid() -> #(Grid(String), Position) {
  let assert Ok(data) = simplifile.read("src/data/6.txt")
  let grid = data |> grid.to_list_of_lists() |> grid.to_grid()
  let starting_point = grid |> get_starting_position

  #(grid, starting_point)
}

fn get_starting_position(grid: Grid(String)) -> Position {
  let assert Ok(starting_point) =
    grid
    |> dict.filter(fn(_, value) { value == "^" })
    |> dict.keys
    |> list.first

  starting_point
}

fn get_position(grid: Grid(String), position: Position) -> String {
  grid
  |> dict.get(position)
  |> result.unwrap("Done")
}

fn next_position(position: Position, direction: Direction) -> Position {
  case direction {
    Up -> Position(position.r - 1, position.c)
    Down -> Position(position.r + 1, position.c)
    Left -> Position(position.r, position.c - 1)
    Right -> Position(position.r, position.c + 1)
  }
}

fn rotate(dir: Direction) -> Direction {
  case dir {
    Up -> Right
    Right -> Down
    Down -> Left
    Left -> Up
  }
}

fn guard_walk(
  grid: Grid(String),
  position: Position,
  direction: Direction,
  visited: Visited,
) -> #(Bool, Visited) {
  case set.contains(visited, #(position, direction)) {
    True -> #(True, visited)
    False -> {
      let visited = set.insert(visited, #(position, direction))
      let next_pos = next_position(position, direction)
      let cell = get_position(grid, next_pos)

      case cell {
        "Done" -> #(False, visited)
        "#" -> guard_walk(grid, position, rotate(direction), visited)
        _ -> guard_walk(grid, next_pos, direction, visited)
      }
    }
  }
}

pub fn main() {
  let #(grid, starting_pos) = get_grid()
  let #(_, visited) = guard_walk(grid, starting_pos, Up, set.new())

  let object_count =
    visited
    |> set.map(fn(t) { t.0 })
    |> set.filter(fn(p) { p.r != starting_pos.r || p.c != starting_pos.c })
    |> set.to_list
    |> list_pmap(
      fn(p) {
        let new_grid = dict.insert(grid, p, "#")
        guard_walk(new_grid, starting_pos, Up, set.new()).0
      },
      WorkerAmount(24),
      5000,
    )
    |> list.map(fn(x) { result.unwrap(x, False) })
    |> list.filter(fn(p) { p })
    |> list.length

  io.println(int.to_string(object_count))
}
