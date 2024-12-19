import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/string
import rememo/memo
import simplifile

type Towel =
  String

fn get_data() -> String {
  let assert Ok(data) = simplifile.read("src/data/19.txt")
  data
}

fn parse_towels(data: String) -> #(List(Towel), List(Towel)) {
  let towels =
    data
    |> string.split("\n")
    |> list.first
    |> fn(x) {
      let assert Ok(x) = x
      x
    }
    |> string.split(", ")

  let towel_creations =
    data
    |> string.split("\n")
    |> list.drop_while(fn(x) { x != "" })
    |> list.filter(fn(x) { x != "" })

  #(towels, towel_creations)
}

fn match_until_end(a: Towel, b: Towel) -> Bool {
  string.starts_with(a, b)
}

fn can_create_towel(towels: List(Towel), towel: Towel, cache) -> Int {
  use <- memo.memoize(cache, #(towel))
  use <- bool.guard(towel == "", 1)

  towels
  |> list.map(fn(t) {
    case match_until_end(towel, t) {
      True ->
        can_create_towel(
          towels,
          string.drop_start(towel, string.length(t)),
          cache,
        )
      _ -> 0
    }
  })
  |> int.sum
}

pub fn main() {
  let #(towels, towel_creations) = parse_towels(get_data())
  io.debug(#(list.length(towels), list.length(towel_creations)))
  use cache <- memo.create()

  towel_creations
  |> list.map(can_create_towel(towels, _, cache))
  |> int.sum
  |> int.to_string
  |> io.println
}
