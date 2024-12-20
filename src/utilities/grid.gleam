import gleam/dict.{type Dict}
import gleam/io
import gleam/list
import gleam/result
import gleam/string

pub type Position {
  Position(r: Int, c: Int)
}

pub type Grid(a) =
  Dict(Position, a)

pub fn to_grid(xss: List(List(a))) -> Grid(a) {
  to_grid_using(xss, fn(x) { Ok(x) })
}

pub fn to_grid_using(xss: List(List(a)), f: fn(a) -> Result(b, Nil)) -> Grid(b) {
  {
    use row, r <- list.index_map(xss)
    use cell, c <- list.index_map(row)
    case f(cell) {
      Ok(contents) -> Ok(#(Position(r, c), contents))
      Error(Nil) -> Error(Nil)
    }
  }
  |> list.flatten
  |> result.values
  |> dict.from_list
}

pub fn to_list_of_lists(str: String) -> List(List(String)) {
  str
  |> string.trim
  |> string.split("\n")
  |> list.map(string.trim)
  |> list.map(string.to_graphemes)
}

pub fn print(grid: Grid(String)) -> Nil {
  let #(width, height) =
    grid
    |> dict.fold(#(0, 0), fn(acc, key, _) {
      let #(ax, ay) = acc
      let Position(x, y) = key

      case ax < x, ay < y {
        True, True -> #(x, y)
        True, _ -> #(x, ay)
        _, True -> #(ax, y)
        _, _ -> acc
      }
    })

  {
    use y <- list.map(list.range(0, height))
    io.println("")
    use x <- list.map(list.range(0, width))

    let current = dict.get(grid, Position(x, y))

    case current {
      Ok(a) -> io.print(a)
      Error(_) -> io.print(" ")
    }

    Nil
  }

  io.println("")
  io.println("")
}
