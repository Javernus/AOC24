import gleam/int
import gleam/io
import gleam/list
import gleam/string
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

fn split_in_half(input: List(Int), length: Int) -> List(Int) {
  let half = length / 2
  let assert Ok(first) = int.undigits(list.take(input, half), 10)
  let assert Ok(second) = int.undigits(list.drop(input, half), 10)

  [first, second]
}

fn transform(input: Int) -> List(Int) {
  case input {
    0 -> [1]
    input -> {
      let assert Ok(input_list) = int.digits(input, 10)
      let length = list.length(input_list)

      case length % 2 {
        0 -> split_in_half(input_list, length)
        _ -> [input * 2024]
      }
    }
  }
}

fn blink(input: List(Int), count: Int) -> List(Int) {
  case count {
    0 -> input
    count ->
      blink(
        input
          |> list.map(transform)
          |> list.flatten,
        count - 1,
      )
  }
}

pub fn main() {
  get_data()
  |> blink(75)
  |> list.length
  |> int.to_string
  |> io.println
}
