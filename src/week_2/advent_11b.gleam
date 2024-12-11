import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import parallel_map.{WorkerAmount, list_pmap}
import simplifile

pub fn get_data() -> List(Int) {
  let assert Ok(data) = simplifile.read("src/data/11.txt")
  data
  |> string.split("\n")
  |> fn(x) {
    let assert Ok(first) = list.first(x)
    first
  }
  |> string.split(" ")
  |> list.map(fn(x) {
    let assert Ok(x) = int.parse(x)
    x
  })
}

fn count_occurrences(numbers: List(Int)) -> Dict(Int, Int) {
  numbers
  |> list.fold(dict.new(), fn(acc, number) {
    dict.upsert(acc, number, fn(x) { option.unwrap(x, 0) + 1 })
  })
}

fn count_stones(numbers: Dict(Int, Int)) -> Int {
  dict.fold(numbers, 0, fn(acc, _, count) { acc + count })
}

fn split_in_half(input: List(Int), length: Int) -> List(Int) {
  let half = length / 2
  let assert Ok(first) = int.undigits(list.take(input, half), 10)
  let assert Ok(second) = int.undigits(list.drop(input, half), 10)

  [first, second]
}

fn transform(
  input: Dict(Int, Int),
  memo: Dict(Int, List(Int)),
) -> #(Dict(Int, Int), Dict(Int, List(Int))) {
  let new_list =
    input
    |> dict.to_list
    |> list_pmap(
      fn(number) {
        let #(number, count) = number
        let memo_output = dict.get(memo, number)

        case memo_output {
          Ok(m) -> m
          Error(_) -> {
            let assert Ok(number_list) = int.digits(number, 10)
            let length = list.length(number_list)

            let new = case length % 2 {
              0 -> split_in_half(number_list, length)
              _ -> [number * 2024]
            }

            dict.insert(memo, number, new)
            new
          }
        }
        |> list.map(fn(x) { #(x, count) })
      },
      WorkerAmount(4),
      1000,
    )
    |> list.map(fn(x) { result.unwrap(x, [#(0, 0)]) })
    |> list.flatten
    |> list.fold(dict.new(), fn(acc, number) {
      let #(number, count) = number
      dict.upsert(acc, number, fn(x) { option.unwrap(x, 0) + count })
    })

  #(new_list, memo)
}

fn blink(
  input: Dict(Int, Int),
  count: Int,
  memo: Dict(Int, List(Int)),
) -> Dict(Int, Int) {
  case count {
    0 -> input
    count -> {
      let #(result, new_memo) = transform(input, memo)
      blink(result, count - 1, new_memo)
    }
  }
}

pub fn main() {
  let memo = dict.new()
  let memo = dict.insert(memo, 0, [1])

  get_data()
  |> count_occurrences
  |> blink(75, memo)
  |> count_stones
  |> int.to_string
  |> io.println
}
