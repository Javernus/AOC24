import gleam/int
import gleam/io
import gleam/list.{map}
import gleam/option.{Some}
import gleam/regexp
import gleam/result
import gleam/set
import simplifile

type Block {
  Empty(size: Int)
  Block(size: Int, id: Int)
}

fn is_valid_line(line: String) -> Bool {
  line != ""
}

fn parse_data() -> List(Block) {
  let assert Ok(data) = simplifile.read("src/data/9.txt")
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
      #([a, b], i) -> [Block(a, i), Empty(b)]
      #([a], i) -> [Block(a, i)]
      _ -> []
    }
  })
  |> list.flatten
}

fn add_block(size: Int, block: Block) -> #(Bool, List(Block)) {
  let assert Block(block_size, id) = block

  case size > block_size {
    True -> #(True, [Block(block_size, id), Empty(size - block_size)])
    False ->
      case size == block_size {
        True -> #(True, [Block(block_size, id)])
        False -> #(False, [Empty(size)])
      }
  }
}

fn get_last_block(blocks: List(Block)) -> #(Block, List(Block)) {
  let first = blocks |> list.reverse |> list.first
  let rest = blocks |> list.reverse |> list.rest |> result.unwrap([])

  case first {
    Ok(Block(size, id)) -> #(Block(size, id), list.reverse(rest))
    Ok(Empty(size)) -> get_last_block(list.reverse(rest))
    _ -> #(Empty(0), [])
  }
}

fn find_first_fit(
  size: Int,
  data: List(Block),
) -> #(Bool, List(Block), Block, Int) {
  let block =
    data
    |> list.reverse
    |> list.find(fn(block) {
      case block {
        Block(s, _) -> s <= size
        Empty(_) -> False
      }
    })

  case block {
    Ok(Block(s, id)) -> {
      let new_data =
        data
        |> list.map(fn(b) {
          case b {
            Block(s, i) ->
              case i != id {
                True -> b
                False -> Empty(s)
              }
            b -> b
          }
        })

      #(True, new_data, Block(s, id), size - s)
    }
    _ -> #(False, data, Empty(0), 0)
  }
}

fn sort_disk(data: List(Block)) -> List(Block) {
  case list.first(data), list.rest(data) {
    Ok(Block(size, id)), Ok(rest) ->
      list.append([Block(size, id)], sort_disk(rest))
    Ok(Block(size, id)), _ -> [Block(size, id)]
    Ok(Empty(size)), Ok(rest) -> {
      let #(fit, new_data, block, space_left) = find_first_fit(size, rest)
      let data = case space_left {
        0 -> new_data
        _ -> list.append([Empty(space_left)], new_data)
      }

      case fit {
        True -> list.append([block], sort_disk(data))
        False -> list.append([Empty(size)], sort_disk(data))
      }
    }
    _, _ -> []
  }
}

fn get_checksum(position, id, size) -> Int {
  // Get id * position + id * (position + 1) + ... + id * (position + size - 1)
  case size {
    0 -> 0
    _ -> id * position + get_checksum(position + 1, id, size - 1)
  }
}

pub fn main() {
  let data = parse_data()
  let sorted_disk = sort_disk(data)

  sorted_disk
  |> list.fold(#(0, 0), fn(acc, block) {
    case block {
      Block(size, id) -> #(acc.0 + get_checksum(acc.1, id, size), acc.1 + size)
      Empty(size) -> #(acc.0, acc.1 + size)
    }
  })
  |> fn(x) { x.0 }
  |> int.to_string
  |> io.println
}
