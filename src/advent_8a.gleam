import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/set.{type Set}
import parallel_map.{WorkerAmount, list_pmap}
import simplifile
import utilities/grid.{type Grid, type Position, Position}

pub fn get_grid() -> #(Grid(String), Int, Int, Set(String)) {
  let assert Ok(data) = simplifile.read("src/data/8.txt")
  let nested_list = data |> grid.to_list_of_lists()
  let height = list.length(nested_list)
  let assert Ok(row) = list.first(nested_list)
  let width = list.length(row)

  let grid = nested_list |> grid.to_grid()
  let antenna_types =
    dict.fold(grid, set.new(), fn(acc, _, value) {
      case value {
        "." -> acc
        a -> set.insert(acc, a)
      }
    })

  #(grid, height, width, antenna_types)
}

fn get_antenna_positions(grid: Grid(String), antenna) -> List(Position) {
  let antennae =
    grid
    |> dict.filter(fn(_, value) { value == antenna })
    |> dict.keys

  antennae
}

fn get_antinodes(positions: #(Position, Position)) -> List(Position) {
  let #(position1, position2) = positions

  let row_difference = position2.r - position1.r
  let column_difference = position2.c - position1.c

  [
    Position(position1.r - row_difference, position1.c - column_difference),
    Position(position2.r + row_difference, position2.c + column_difference),
  ]
}

fn find_antinodes(grid: Grid(String), antenna: String) -> List(Position) {
  let antenna_positions = get_antenna_positions(grid, antenna)

  antenna_positions
  |> list.combination_pairs
  |> list.map(get_antinodes)
  |> list.flatten
}

pub fn main() {
  let #(grid, height, width, antenna_types) = get_grid()

  let antinode_count =
    antenna_types
    |> set.to_list
    |> list_pmap(
      fn(antenna) { find_antinodes(grid, antenna) },
      WorkerAmount(14),
      1000,
    )
    |> list.map(fn(x) { result.unwrap(x, []) })
    |> list.flatten
    |> list.unique
    |> list.filter(fn(position) {
      position.r >= 0
      && position.r < height
      && position.c >= 0
      && position.c < width
    })
    |> list.length

  io.println(int.to_string(antinode_count))
}