import gleam/int.{parse}
import gleam/io
import gleam/list.{map}
import gleam/option.{Some}
import gleam/regexp
import gleam/result
import gleam/string
import parallel_map.{WorkerAmount, list_pmap}
import simplifile

pub fn get_data() -> String {
  let assert Ok(data) = simplifile.read("src/data/7.txt")
  data
}

pub fn parse_data(data: String) -> List(#(Int, List(Int))) {
  let assert Ok(re) =
    regexp.compile("(\\d+?):\\s(.+?)$", regexp.Options(True, True))
  let matches = regexp.scan(with: re, content: data)

  matches
  |> map(fn(match) {
    let assert regexp.Match(_, [Some(a), Some(b)]) = match
    let assert Ok(end_value) = parse(a)
    let numbers =
      string.split(b, " ") |> map(parse) |> map(fn(n) { result.unwrap(n, 0) })

    #(end_value, numbers)
  })
}

fn mul_add(input: #(Int, List(Int))) -> Int {
  let #(goal, numbers) = input

  numbers
  |> list.fold([], fn(acc, number) {
    case acc {
      [] -> [number]
      numbers ->
        []
        |> list.append(numbers |> list.map(fn(n) { n + number }))
        |> list.append(numbers |> list.map(fn(n) { n * number }))
        |> list.append(
          numbers
          |> list.map(fn(n) {
            let assert Ok(n) = int.digits(n, 10)
            let assert Ok(number) = int.digits(number, 10)
            let assert Ok(n) = int.undigits(list.append(n, number), 10)
            n
          }),
        )
    }
  })
  |> fn(numbers) {
    case list.contains(numbers, goal) {
      True -> goal
      False -> 0
    }
  }
}

pub fn main() {
  let data = get_data()

  let output =
    data
    |> parse_data
    |> list_pmap(mul_add, WorkerAmount(14), 1000)
    |> map(fn(x) { result.unwrap(x, 0) })
    |> int.sum

  io.println(int.to_string(output))
}
