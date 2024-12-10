import gleam/int
import gleam/io
import gleam/list.{map}
import gleam/regexp
import gleam/string
import simplifile

pub fn get_data() -> String {
  let assert Ok(data) = simplifile.read("src/data/4.txt")
  data
}

fn reverse_lines(lines) -> List(String) {
  lines
  |> map(fn(line) { string.reverse(line) })
}

fn transpose_line(lines) -> List(String) {
  lines
  |> map(string.to_graphemes)
  |> list.transpose
  |> map(fn(line) { string.join(line, "") })
}

fn get_top_diagonal(lines, include_first) -> List(String) {
  // Edge case for first and final triangles
  let length = list.length(lines)

  lines
  |> string.join("")
  |> string.to_graphemes()
  |> list.sized_chunk(length + 1)
  |> list.transpose()
  |> list.fold(#(length, []), fn(acc, column) {
    let #(length, lines) = acc

    let column = list.take(column, length)

    #(length - 1, list.append(lines, [string.join(column, "")]))
  })
  |> fn(x) { x.1 }
  |> fn(lines) {
    case include_first {
      True -> lines
      False -> list.split(lines, 1).1
    }
  }
}

fn get_all_options(lines) -> List(String) {
  lines
  |> list.append(reverse_lines(lines))
  |> list.append(transpose_line(lines))
  |> list.append(reverse_lines(transpose_line(lines)))
  |> list.append(get_top_diagonal(lines, True))
  |> list.append(reverse_lines(get_top_diagonal(lines, True)))
  |> list.append(get_top_diagonal(transpose_line(lines), False))
  |> list.append(reverse_lines(get_top_diagonal(transpose_line(lines), False)))
  |> list.append(get_top_diagonal(reverse_lines(lines), True))
  |> list.append(reverse_lines(get_top_diagonal(reverse_lines(lines), True)))
  |> list.append(get_top_diagonal(transpose_line(reverse_lines(lines)), False))
  |> list.append(
    reverse_lines(get_top_diagonal(transpose_line(reverse_lines(lines)), False)),
  )
}

fn find_xmas(line) -> Int {
  let assert Ok(re) = regexp.from_string("XMAS")
  // use string.?
  let matches = regexp.scan(with: re, content: line)

  list.length(matches)
}

pub fn is_valid_line(line: String) -> Bool {
  line != ""
}

fn parse_data(data: String) -> Int {
  data
  |> string.split("\n")
  |> list.filter(is_valid_line)
  |> get_all_options()
  |> map(find_xmas)
  |> int.sum
}

pub fn main() {
  let data = get_data()

  io.println(int.to_string(parse_data(data)))
}
