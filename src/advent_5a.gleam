import gleam/int
import gleam/io
import gleam/list.{map}
import gleam/option.{Some}
import gleam/regexp
import gleam/string
import simplifile

pub fn get_data() -> String {
  let assert Ok(data) = simplifile.read("src/data/5.txt")
  data
}

pub fn is_valid_line(line: String) -> Bool {
  line != ""
}

pub fn parse_rule(data: String) -> List(#(Int, Int)) {
  let assert Ok(re) = regexp.from_string("(\\d+)\\|(\\d+)")
  let match = regexp.scan(with: re, content: data)

  match
  |> map(fn(match) {
    let assert regexp.Match(_, [Some(a), Some(b)]) = match
    let assert Ok(a) = int.parse(a)
    let assert Ok(b) = int.parse(b)

    #(a, b)
  })
}

fn parse_order(line: String) -> List(Int) {
  let assert Ok(re) = regexp.from_string(",")
  regexp.split(with: re, content: line)
  |> map(fn(x) {
    let assert Ok(a) = int.parse(x)
    a
  })
}

fn is_valid_order(numbers, rules) -> Bool {
  let length = list.length(numbers)

  case length {
    0 -> True
    _ -> {
      let assert [head, ..tail] = numbers
      let bad_rules = tail |> map(fn(x) { #(x, head) })

      let layer_not_ok =
        bad_rules
        |> list.any(fn(rule) { list.contains(rules, rule) })

      case layer_not_ok {
        False -> is_valid_order(tail, rules)
        True -> False
      }
    }
  }
}

fn get_middle_int(numbers) -> Int {
  let l = list.length(numbers)
  let middle_index = l / 2

  numbers
  |> list.index_fold(0, fn(acc, x, i) {
    case i == middle_index {
      True -> x
      _ -> acc
    }
  })
}

fn parse_data(data: String) -> Int {
  let rules = parse_rule(data)

  data
  |> string.split("\n")
  |> list.split_while(fn(line) { line != "" })
  |> fn(lists) { lists.1 }
  |> list.filter(is_valid_line)
  |> map(parse_order)
  |> list.filter(fn(numbers) { is_valid_order(numbers, rules) })
  |> map(get_middle_int)
  |> int.sum
}

pub fn main() {
  let data = get_data()
  io.println(int.to_string(parse_data(data)))
}
