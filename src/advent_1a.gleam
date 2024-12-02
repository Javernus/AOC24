import gleam/int.{parse}
import gleam/io
import gleam/list.{filter, first, map, sort, unzip, zip}
import gleam/option
import gleam/regexp
import gleam/string.{split}
import simplifile

pub fn get_data() -> String {
  let assert Ok(data) = simplifile.read("src/data_1.txt")
  data
}

pub fn parse_line(line: String) -> #(Int, Int) {
  let assert Ok(re) = regexp.from_string("(\\d+)\\s+?(\\d+)")
  let match = regexp.scan(with: re, content: line)

  let assert Ok(m) = first(match)

  let assert [option.Some(a), option.Some(b)] = m.submatches

  let assert Ok(a) = parse(a)
  let assert Ok(b) = parse(b)

  #(a, b)
}

pub fn is_valid_line(line: String) -> Bool {
  line != ""
}

pub fn parse_data(data: String) -> #(List(Int), List(Int)) {
  data
  |> split("\n")
  |> filter(is_valid_line)
  |> map(parse_line)
  |> unzip
}

pub fn difference(a) -> Int {
  let #(a, b) = a
  int.absolute_value(a - b)
}

pub fn main() {
  let data = get_data()
  let parsed_data = parse_data(data)

  let #(a, b) = parsed_data

  let a = sort(a, by: int.compare)
  let b = sort(b, by: int.compare)

  let distances =
    zip(a, b)
    |> map(difference)
    |> int.sum

  io.println(int.to_string(distances))
}
