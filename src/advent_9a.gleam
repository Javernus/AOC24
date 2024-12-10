import gleam/int
import gleam/io
import gleam/list.{map}
import gleam/option.{Some}
import gleam/regexp
import simplifile

pub fn get_data() -> String {
  let assert Ok(data) = simplifile.read("src/data/9.txt")
  data
}

pub fn is_valid_line(line: String) -> Bool {
  line != ""
}

pub fn parse_data(data: String) -> List(Int) {
  let assert Ok(re) = regexp.from_string("(\\d)")
  let match = regexp.scan(with: re, content: data)

  match
  |> map(fn(match) {
    let assert regexp.Match(_, [Some(a)]) = match
    let assert Ok(a) = int.parse(a)

    a
  })
  |> list.sized_chunk(into: 2)
  |> list.index_map(fn(x, i) { #(x, i) })
  |> map(fn(x) {
    case x {
      #([a, b], i) -> list.append(list.repeat(i, a), list.repeat(-1, b))
      #([a], i) -> list.repeat(i, a)
      _ -> []
    }
  })
  |> list.flatten
}

fn sort_disk(data: String) -> Int {
  let disk = parse_data(data)
  let swapped_disk = list.reverse(disk) |> list.filter(fn(x) { x != -1 })
  let size = list.length(swapped_disk)

  list.fold(swapped_disk, disk, fn(disk, last_value) {
    let pre_empty = list.take_while(disk, fn(x) { x != -1 })
    let post_empty = disk |> list.drop_while(fn(x) { x != -1 }) |> list.rest

    case post_empty {
      Error(Nil) -> disk
      Ok(post_empty) ->
        pre_empty
        |> list.append([last_value])
        |> list.append(post_empty)
    }
  })
  |> list.take(size)
  |> list.filter(fn(x) { x != -1 })
  |> list.index_map(fn(x, i) { x * i })
  |> int.sum
}

pub fn main() {
  let data = get_data()
  io.println(int.to_string(sort_disk(data)))
}
