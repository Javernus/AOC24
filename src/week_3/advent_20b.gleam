import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/set.{type Set}
import gleamy/non_empty_list.{type NonEmptyList}
import simplifile
import utilities/dijkstra.{dijkstra}
import utilities/grid.{type Grid, type Position, Position}

type Obstacles =
  Set(Position)

fn get_data() -> #(Obstacles, #(Int, Int), #(Int, Int)) {
  let assert Ok(data) = simplifile.read("src/data/20.txt")

  let data =
    data
    |> grid.to_list_of_lists()
    |> grid.to_grid()

  let start = data |> get_position("S") |> position_to_tuple
  let finish = data |> get_position("E") |> position_to_tuple
  let walls = data |> get_positions("#")

  #(walls, start, finish)
}

fn get_position(data: Grid(String), character: String) -> Position {
  let assert Ok(point) =
    data
    |> dict.filter(fn(_, value) { value == character })
    |> dict.keys
    |> list.first

  point
}

fn get_positions(data: Grid(String), character: String) -> Set(Position) {
  data
  |> dict.filter(fn(_, value) { value == character })
  |> dict.keys
  |> set.from_list
}

fn get_neighbours_function(
  walls: Set(#(Int, Int)),
) -> fn(#(Int, Int)) -> List(#(Int, #(Int, Int))) {
  fn(position: #(Int, Int)) -> List(#(Int, #(Int, Int))) {
    [
      #(position.0 - 1, position.1),
      #(position.0 + 1, position.1),
      #(position.0, position.1 - 1),
      #(position.0, position.1 + 1),
    ]
    |> list.filter(fn(x) { !set.contains(walls, x) })
    |> list.map(fn(x) { #(1, x) })
  }
}

fn position_to_tuple(position: Position) -> #(Int, Int) {
  #(position.r, position.c)
}

fn find_path(
  path: Dict(#(Int, Int), #(Int, NonEmptyList(#(Int, Int)))),
  start: #(Int, Int),
  next: #(Int, Int),
) -> List(#(Int, Int)) {
  use <- bool.guard(start == next, [start])
  case dict.get(path, next) {
    Ok(#(_, p)) -> {
      let next = case p {
        non_empty_list.End(first) -> first
        non_empty_list.Next(first, _) -> first
      }

      list.append(find_path(path, start, next), [next])
    }
    _ -> []
  }
}

pub fn main() {
  let #(walls, start, finish) = get_data()

  let tuple_walls = set.map(walls, position_to_tuple)

  let path = dijkstra(start, get_neighbours_function(tuple_walls))
  let path =
    find_path(path, start, finish)
    |> list.append([finish])
    |> list.index_map(fn(x, i) { #(x, i) })

  path
  |> list.map(fn(a) {
    path
    |> list.drop_while(fn(x) { x != a })
    |> list.drop(1)
    |> list.map(fn(x) { #(a, x) })
  })
  |> list.flatten
  |> list.fold(0, fn(acc, a) {
    let #(a, b) = a

    let distance =
      int.absolute_value(a.0.0 - b.0.0) + int.absolute_value(a.0.1 - b.0.1)
    let savings = b.1 - a.1 - distance

    case distance <= 20 && savings >= 100 && int.is_even(savings) {
      True -> acc + 1
      _ -> acc
    }
  })
  |> int.to_string
  |> io.println
}
