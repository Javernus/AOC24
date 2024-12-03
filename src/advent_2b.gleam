import gleam/int.{parse}
import gleam/io
import gleam/list.{count, filter, map}
import gleam/regexp
import gleam/string.{split}
import simplifile

pub fn get_data() -> String {
  let assert Ok(data) = simplifile.read("src/data/2.txt")
  data
}

pub fn parse_list(list: List(Int)) -> Bool {
  let diffs =
    list
    |> list.window_by_2
    |> map(fn(x) {
      let #(a, b) = x
      a - b
    })

  let diffs_ok =
    diffs
    |> filter(fn(x) { int.absolute_value(x) > 3 || int.absolute_value(x) == 0 })
    |> list.is_empty

  let all_signs_same =
    diffs |> filter(fn(x) { x < 0 }) |> list.is_empty
    || diffs |> filter(fn(x) { x > 0 }) |> list.is_empty

  diffs_ok && all_signs_same
}

pub fn parse_line(line: String) -> Bool {
  let assert Ok(re) = regexp.from_string("\\s+")
  let matches = regexp.split(with: re, content: line)

  let items =
    matches
    |> map(fn(x) {
      let assert Ok(x) = parse(x)
      x
    })

  let list_ok = parse_list(items)

  case list_ok {
    True -> True
    False -> {
      list.any(list.range(0, list.length(items) - 1), fn(index) {
        let sublist =
          items
          |> list.index_map(fn(x, i) { #(i, x) })
          |> list.filter(fn(x) { x.0 != index })
          |> list.map(fn(x) { x.1 })
        parse_list(sublist)
      })
    }
  }
}

pub fn is_valid_line(line: String) -> Bool {
  line != ""
}

pub fn parse_data(data: String) -> Int {
  data
  |> split("\n")
  |> filter(is_valid_line)
  |> map(parse_line)
  |> count(fn(x) { x })
}

pub fn similarity(l) -> fn(Int) -> Int {
  fn(a: Int) -> Int {
    l
    |> count(fn(b) { a == b })
    |> int.multiply(a)
  }
}

pub fn main() {
  let data = get_data()
  let parsed_data = parse_data(data)

  let i = parsed_data

  io.println(int.to_string(i))
}
