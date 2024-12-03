import gleam/int.{parse}
import gleam/io
import gleam/list.{map}
import gleam/option.{Some}
import gleam/regexp
import simplifile

pub fn get_data() -> String {
  let assert Ok(data) = simplifile.read("src/data/3.txt")
  data
}

pub fn parse_data(data: String) -> Int {
  let assert Ok(re) = regexp.from_string("mul\\((\\d{1,3}),(\\d{1,3})\\)")
  let matches = regexp.scan(with: re, content: data)

  matches
  |> map(fn(match) {
    let assert regexp.Match(_, [Some(a), Some(b)]) = match
    let assert Ok(a) = parse(a)
    let assert Ok(b) = parse(b)

    a * b
  })
  |> int.sum
}

pub fn main() {
  let data = get_data()
  io.println(int.to_string(parse_data(data)))
}
