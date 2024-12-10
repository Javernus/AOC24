import gleam/int
import gleam/io
import gleam/list.{map}
import gleam/string
import simplifile

type Cell =
  #(Int, Int, Type)

type Row =
  List(Cell)

type Grid =
  List(Row)

type Guard =
  #(Int, Int, Direction)

type Type {
  Empty
  Block
  Visited
  Guard
  Done
}

type Direction {
  Up
  Down
  Left
  Right
}

pub fn get_data() -> String {
  let assert Ok(data) = simplifile.read("src/data/6.txt")
  data
}

pub fn is_valid_line(line: String) -> Bool {
  line != ""
}

fn parse_line(line: String, row: Int) -> Row {
  line
  |> string.to_graphemes()
  |> map(fn(character) {
    case character {
      "." -> Empty
      "#" -> Block
      "^" -> Guard
      _ -> Visited
    }
  })
  |> list.index_map(fn(character, index) { #(row, index, character) })
}

fn get_pos(grid: Grid, row_index, column_index) -> Type {
  grid
  |> list.index_fold(Done, fn(acc, row, i) {
    case i == row_index {
      True ->
        list.index_fold(row, acc, fn(acc, cell, i) {
          case i == column_index {
            True -> cell.2
            False -> acc
          }
        })
      False -> acc
    }
  })
}

fn cell_map(grid: Grid, func: fn(Cell) -> a) {
  grid
  |> list.map(fn(row) { list.map(row, func) })
}

fn cell_set(grid: Grid, x, y, cell_type: Type) -> Grid {
  cell_map(grid, fn(cell) {
    case cell.0 == x && cell.1 == y {
      True -> #(x, y, cell_type)
      False -> cell
    }
  })
}

fn next_position(position: Guard) -> #(Int, Int) {
  case position.2 {
    Up -> #(position.0 - 1, position.1)
    Down -> #(position.0 + 1, position.1)
    Left -> #(position.0, position.1 - 1)
    Right -> #(position.0, position.1 + 1)
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

fn guard_walk(grid: Grid, guard_position) -> Grid {
  let #(x, y) = next_position(guard_position)
  let cell = get_pos(grid, x, y)

  case cell {
    Done -> grid
    Empty -> {
      let grid = cell_set(grid, x, y, Visited)

      guard_walk(grid, #(x, y, guard_position.2))
    }
    Block -> {
      guard_walk(grid, #(
        guard_position.0,
        guard_position.1,
        rotate(guard_position.2),
      ))
    }
    _ -> {
      let grid = cell_set(grid, x, y, Visited)
      guard_walk(grid, #(x, y, guard_position.2))
    }
  }
}

fn guard_count(grid) -> Int {
  grid
  |> cell_map(fn(cell) {
    case cell.2 == Visited {
      True -> 1
      False -> 0
    }
  })
  |> list.flatten
  |> int.sum
}

fn parse_data(data: String) -> Int {
  let grid: Grid =
    data
    |> string.split("\n")
    |> list.filter(is_valid_line)
    |> list.index_map(parse_line)

  let guard_position =
    grid
    |> list.fold(#(0, 0, Guard), fn(acc, row) {
      list.fold(row, acc, fn(acc, cell) {
        case cell.2 == Guard {
          True -> cell
          _ -> acc
        }
      })
    })
    |> fn(position) { #(position.0, position.1, Up) }

  let grid =
    grid
    |> cell_map(fn(cell) {
      case cell.2 == Guard {
        True -> #(cell.0, cell.1, Empty)
        False -> cell
      }
    })

  guard_walk(grid, guard_position) |> guard_count()
}

pub fn main() {
  let data = get_data()

  io.println(int.to_string(parse_data(data)))
}
