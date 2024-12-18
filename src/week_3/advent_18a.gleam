import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{Some}
import gleam/regexp
import gleam/set.{type Set}
import simplifile
import utilities/grid.{type Position, Position}

const maze_size = 70

const maze_corrupted = 1024

fn get_data() -> Set(Position) {
  let assert Ok(data) = simplifile.read("src/data/18.txt")
  let assert Ok(re) = regexp.from_string("(\\d+),(\\d+)")
  let matches = regexp.scan(with: re, content: data)

  matches
  |> list.map(fn(match) {
    let assert regexp.Match(_, [Some(r), Some(c)]) = match
    let assert Ok(r) = int.parse(r)
    let assert Ok(c) = int.parse(c)

    Position(r, c)
  })
  |> list.take(maze_corrupted)
  |> set.from_list
}

fn is_corrupted(corrupted: Set(Position), position: Position) -> Bool {
  set.contains(corrupted, position)
}

fn is_visited_earlier(
  visited: Dict(Position, Int),
  position: Position,
  steps: Int,
) -> Bool {
  case dict.get(visited, position) {
    Ok(value) -> value <= steps
    _ -> False
  }
}

fn next_positions(
  position: Position,
  steps: Int,
  visited: Dict(Position, Int),
  corrupted: Set(Position),
) -> Dict(Position, Int) {
  [
    Position(position.r - 1, position.c),
    Position(position.r + 1, position.c),
    Position(position.r, position.c - 1),
    Position(position.r, position.c + 1),
  ]
  |> list.filter(fn(x) { x.r >= 0 && x.c >= 0 })
  |> list.filter(fn(x) { x.r <= maze_size && x.c <= maze_size })
  |> list.filter(fn(x) { !is_corrupted(corrupted, x) })
  |> list.filter(fn(x) {
    case !is_visited_earlier(visited, x, steps + 1) {
      True -> True
      _ -> {
        // io.debug(#("Visited earlier", x, steps + 1))
        False
      }
    }
  })
  |> list.map(fn(x) { #(x, steps + 1) })
  |> dict.from_list
}

fn combine_positions(
  a: Dict(Position, Int),
  b: Dict(Position, Int),
) -> Dict(Position, Int) {
  dict.combine(a, b, fn(a, b) {
    case a < b {
      True -> a
      _ -> b
    }
  })
}

fn next_position(positions: Dict(Position, Int)) -> #(Position, Int) {
  // Get position with lowest steps
  dict.fold(positions, #(Position(-1, -1), -1), fn(acc, key, value) {
    case acc {
      #(Position(-1, -1), -1) -> #(key, value)
      #(_, steps) -> {
        case value < steps {
          True -> #(key, value)
          _ -> acc
        }
      }
    }
  })
}

fn search(
  corrupted: Set(Position),
  visited: Dict(Position, Int),
  to_visit: Dict(Position, Int),
) -> #(List(Position), Int) {
  let next = next_position(to_visit)
  use <- bool.guard(next.0 == Position(maze_size, maze_size), #(
    visited |> dict.keys(),
    next.1,
  ))

  let visited = dict.insert(visited, next.0, next.1)
  let next_positions = next_positions(next.0, next.1, visited, corrupted)
  let to_visit =
    combine_positions(to_visit, next_positions)
    |> dict.filter(fn(x, _) { x != next.0 })

  search(corrupted, visited, to_visit)
}

pub fn main() {
  let corrupted = get_data()

  grid.print(
    corrupted |> set.to_list |> list.map(fn(x) { #(x, "#") }) |> dict.from_list,
  )

  corrupted
  |> search(dict.new(), dict.new() |> dict.insert(Position(0, 0), 0))
  |> fn(x) {
    x.0
    |> list.map(fn(x) { #(x, "O") })
    |> dict.from_list
    |> dict.combine(
      corrupted
        |> set.to_list
        |> list.map(fn(x) { #(x, "#") })
        |> dict.from_list,
      fn(a, _) { a },
    )
    |> grid.print
    x.1
  }
  |> int.to_string
  |> io.println
}
