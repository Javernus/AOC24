import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/set.{type Set}
import simplifile
import utilities/grid.{type Grid, type Position, Position}

type Direction {
  Up
  Down
  Left
  Right
}

pub fn get_grid() -> Grid(String) {
  let assert Ok(data) = simplifile.read("src/data/12.txt")
  let grid = data |> grid.to_list_of_lists() |> grid.to_grid()

  grid
}

fn get_farm_type(grid: Grid(String), position: Position) -> String {
  grid |> dict.get(position) |> result.unwrap("Out of Bounds")
}

fn is_same_farm(grid: Grid(String), position: Position, farm: String) -> Bool {
  let value = get_farm_type(grid, position)
  value == farm
}

fn count_region_neighbours(region: Set(Position), position: Position) -> Int {
  get_neighbours(position)
  |> list.filter(fn(farm) { set.contains(region, farm) })
  |> list.length
}

fn next_position(position: Position, direction: Direction) -> Position {
  case direction {
    Up -> Position(position.r - 1, position.c)
    Down -> Position(position.r + 1, position.c)
    Left -> Position(position.r, position.c - 1)
    Right -> Position(position.r, position.c + 1)
  }
}

fn get_neighbours(position: Position) -> List(Position) {
  [Up, Down, Left, Right]
  |> list.map(fn(direction) { next_position(position, direction) })
}

fn get_region(
  grid: Grid(String),
  region: Set(Position),
  other_regions: List(Set(Position)),
  position: Position,
) -> Set(Position) {
  let farm = get_farm_type(grid, position)

  get_neighbours(position)
  |> list.filter(fn(neighbour) { get_farm_type(grid, neighbour) == farm })
  |> list.filter(fn(neighbour) {
    case set.contains(region, neighbour), in_any(other_regions, neighbour) {
      True, _ -> False
      _, True -> False
      False, False -> {
        let farm = get_farm_type(grid, neighbour)
        is_same_farm(grid, neighbour, farm)
      }
    }
  })
  |> list.fold(region, fn(region, neighbour) {
    get_region(grid, set.insert(region, neighbour), other_regions, neighbour)
  })
}

fn in_any(s: List(Set(a)), a: a) -> Bool {
  list.any(s, fn(s) { set.contains(s, a) })
}

fn find_regions(grid: Grid(String)) -> List(Set(Position)) {
  let positions = dict.keys(grid)

  positions
  |> list.fold([], fn(regions, farm) {
    case in_any(regions, farm) {
      True -> regions
      False ->
        list.append(regions, [
          get_region(grid, set.new() |> set.insert(farm), regions, farm),
        ])
    }
  })
}

fn calculate_cost(region: Set(Position)) -> Int {
  let farms = region |> set.to_list
  let area = farms |> list.length
  let perimeter_overlap =
    farms
    |> list.map(fn(farm) { count_region_neighbours(region, farm) })
    |> int.sum

  area * { 4 * area - perimeter_overlap }
}

pub fn main() {
  let grid = get_grid()

  grid
  |> find_regions
  |> list.map(calculate_cost)
  |> int.sum
  |> int.to_string
  |> io.println
}
