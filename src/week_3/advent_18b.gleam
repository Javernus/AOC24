import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{Some}
import gleam/regexp
import gleam/set.{type Set}
import gleam/string
import simplifile
import utilities/grid.{type Position, Position}

const maze_size = 70

const maze_corrupted = 2

fn get_data() -> List(Position) {
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
  use <- bool.guard(next.0 == Position(-1, -1), #(visited |> dict.keys(), -1))
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

fn try_break(corrupted: List(Position), count: Int) -> Position {
  let #(_, a) =
    corrupted
    |> list.take(count)
    |> set.from_list
    |> search(dict.new(), dict.new() |> dict.insert(Position(0, 0), 0))

  case a == -1 {
    True -> {
      let broken =
        list.index_map(corrupted, fn(x, i) { #(i, x) })
        |> dict.from_list
        |> dict.get(count - 1)
      case broken {
        Ok(b) -> b
        _ -> Position(-1, -1)
      }
    }
    // TODO: Use binary search instead of +1
    _ -> try_break(corrupted, count + 1)
  }
}

pub fn main() {
  let corrupted = get_data()

  corrupted
  |> try_break(maze_corrupted)
  |> fn(x) {
    let Position(x, y) = x
    let x = int.to_string(x)
    let y = int.to_string(y)
    string.concat([x, ",", y])
  }
  |> io.println
}
