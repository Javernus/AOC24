import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import simplifile
import utilities/grid.{type Grid, type Position, Position}

type Direction {
  Up
  Down
  Left
  Right
}

type Maze =
  Grid(String)

type Reindeer =
  #(Position, Direction)

fn get_data() -> #(Maze, Reindeer) {
  let assert Ok(data) = simplifile.read("src/data/16.txt")

  let data =
    data
    |> grid.to_list_of_lists()
    |> grid.to_grid()

  let starting_point = data |> get_starting_position

  #(data, #(starting_point, Right))
}

fn get_starting_position(data: Maze) -> Position {
  let assert Ok(starting_point) =
    data
    |> dict.filter(fn(_, value) { value == "S" })
    |> dict.keys
    |> list.first

  starting_point
}

fn rotate(rotation: Direction, anticlockwise: Bool) -> Direction {
  case rotation, anticlockwise {
    Up, True -> Left
    Up, False -> Right
    Right, True -> Up
    Right, False -> Down
    Down, True -> Right
    Down, False -> Left
    Left, True -> Down
    Left, False -> Up
  }
}

fn get_position(grid: Maze, position: Position) -> String {
  grid
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

fn filter_visited(l: List(a), visited: Dict(a, Int), score: Int) -> List(a) {
  let visited = dict.take(visited, l)

  let ok = list.filter(l, fn(x) { !dict.has_key(visited, x) })

  let visited_ok =
    visited
    |> dict.filter(fn(_, value) { value > score })
    |> dict.keys

  list.append(ok, visited_ok)
}

fn filter_to_visit(
  l: List(#(a, b)),
  to_visit: List(#(a, b, Int)),
  score: Int,
) -> List(#(a, b)) {
  let to_visit =
    to_visit |> list.map(fn(x) { #(#(x.0, x.1), x.2) }) |> dict.from_list
  let visited = dict.take(to_visit, l)

  let ok = list.filter(l, fn(x) { !dict.has_key(visited, x) })

  let visited_ok =
    visited
    |> dict.filter(fn(_, value) { value > score })
    |> dict.keys

  list.append(ok, visited_ok)
}

fn sort_to_visit(
  to_visit: List(#(Position, Direction, Int)),
) -> List(#(Position, Direction, Int)) {
  list.sort(to_visit, fn(a, b) { int.compare(a.2, b.2) })
}

fn get_next(
  to_visit: List(#(Position, Direction, Int)),
) -> Result(
  #(#(Position, Direction, Int), List(#(Position, Direction, Int))),
  Nil,
) {
  case to_visit {
    [] -> Error(Nil)
    [a] -> Ok(#(a, []))
    [a, ..b] -> Ok(#(a, b))
  }
}

fn go_through_maze(
  grid: Maze,
  visited: Dict(#(Position, Direction), Int),
  to_visit: List(#(Position, Direction, Int)),
) -> Result(Int, Nil) {
  use #(next, rest) <- result.try(get_next(to_visit))

  let visited = dict.insert(visited, #(next.0, next.1), next.2)

  let new_rotations =
    [rotate(next.1, True), rotate(next.1, False)]
    |> list.map(fn(x) { #(next.0, x) })
    |> filter_visited(visited, next.2 + 1000)
    |> filter_to_visit(to_visit, next.2 + 1000)
    |> list.map(fn(x) { #(x.0, x.1, next.2 + 1000) })

  let next_pos = next_position(next.0, next.1)
  let contents = get_position(grid, next_pos)
  let score = next.2 + 1

  let forward_cell = #(next_pos, next.1, score)

  let to_visit =
    new_rotations
    |> fn(x) {
      case contents {
        "#" -> x
        _ -> list.append(x, [forward_cell])
      }
    }
    |> list.append(rest)
    |> sort_to_visit

  case contents {
    "E" -> Ok(score)
    _ -> go_through_maze(grid, visited, to_visit)
  }
}

pub fn main() {
  let #(grid, start) = get_data()

  grid
  |> go_through_maze(dict.new(), [#(start.0, start.1, 0)])
  |> fn(x) {
    let assert Ok(x) = x
    x
  }
  |> int.to_string
  |> io.println
}
