import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/set.{type Set}
import parallel_map.{WorkerAmount, list_pmap}
import simplifile
import utilities/grid.{type Grid, type Position, Position}

type Direction {
  Up
  Down
  Left
  Right
}

pub fn get_grid() -> #(Grid(Int), Set(Position)) {
  let assert Ok(data) = simplifile.read("src/data/10.txt")
  let grid =
    data
    |> grid.to_list_of_lists()
    |> list.map(fn(x) {
      list.map(x, fn(x) {
        let assert Ok(x) = int.parse(x)
        x
      })
    })
    |> grid.to_grid()

  let zeroes =
    dict.fold(grid, set.new(), fn(acc, position, value) {
      case value {
        0 -> set.insert(acc, position)
        _ -> acc
      }
    })

  #(grid, zeroes)
}

fn get_position(grid: Grid(Int), position: Position) -> Result(Int, Nil) {
  grid
  |> dict.get(position)
}

fn next_position(position: Position, direction: Direction) -> Position {
  case direction {
    Up -> Position(position.r - 1, position.c)
    Down -> Position(position.r + 1, position.c)
    Left -> Position(position.r, position.c - 1)
    Right -> Position(position.r, position.c + 1)
  }
}

fn get_directions(grid: Grid(Int), position: Position) -> List(Position) {
  [Up, Down, Left, Right]
  |> list.filter_map(fn(direction) {
    let next = next_position(position, direction)
    let value = get_position(grid, next)

    case value {
      Ok(_) -> Ok(next)
      Error(_) -> Error("Out of bounds")
    }
  })
}

fn find_trailheads(
  grid: Grid(Int),
  position: Position,
  value: Int,
) -> List(Position) {
  get_directions(grid, position)
  |> list.map(fn(position) {
    let assert Ok(v) = get_position(grid, position)

    case v == value + 1, v == 9 {
      True, True -> [position]
      True, _ -> find_trailheads(grid, position, v)
      False, _ -> []
    }
  })
  |> list.flatten
}

fn count_trailheads(grid: Grid(Int), zero: Position) -> Int {
  find_trailheads(grid, zero, 0)
  |> list.unique
  |> list.length
}

pub fn main() {
  let #(grid, zeroes) = get_grid()

  zeroes
  |> set.to_list
  |> list_pmap(
    fn(zero) { count_trailheads(grid, zero) },
    WorkerAmount(14),
    1000,
  )
  |> list.map(fn(x) { result.unwrap(x, 0) })
  |> int.sum
  |> int.to_string()
  |> io.println()
}
