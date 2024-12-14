import gleam/int
import gleam/io
import gleam/list
import gleam/option.{Some}
import gleam/order
import gleam/regexp
import gleam/string
import simplifile

type Vector =
  #(Int, Int)

type Robot =
  #(Vector, Vector)

pub fn get_data() -> String {
  let assert Ok(data) = simplifile.read("src/data/14.txt")
  data
}

fn parse_numbers(match: regexp.Match) -> #(Vector, Vector) {
  case match {
    regexp.Match(_, [Some(p1), Some(p2), Some(v1), Some(v2)]) -> {
      let assert Ok(p1) = int.parse(p1)
      let assert Ok(p2) = int.parse(p2)
      let assert Ok(v1) = int.parse(v1)
      let assert Ok(v2) = int.parse(v2)

      #(#(p1, p2), #(v1, v2))
    }
    _ -> #(#(-1, -1), #(-1, -1))
  }
}

pub fn parse_data(data: String) -> List(Robot) {
  let assert Ok(re) =
    regexp.from_string("p=(\\d+?),(\\d+?) v=(-?\\d+?),(-?\\d+)")
  let matches = regexp.scan(with: re, content: data)

  matches
  |> list.map(parse_numbers)
}

fn vector_add(v: Vector, v2: Vector) -> Vector {
  #(v.0 + v2.0, v.1 + v2.1)
}

fn vector_mod(v: Vector, modulo_x: Int, modulo_y: Int) -> Vector {
  let assert Ok(v0) = int.modulo(v.0, modulo_x)
  let assert Ok(v1) = int.modulo(v.1, modulo_y)

  #(v0, v1)
}

fn is_same_position(position, position2, acc, callback) {
  let #(x, y) = position
  let #(x2, y2) = position2

  case x == x2 && y == y2 {
    True -> acc
    False -> callback()
  }
}

fn get_n_dots(n: Int) -> String {
  string.repeat(".", n)
}

fn print(robots: List(Robot)) -> Nil {
  robots
  |> list.map(fn(x) { x.0 })
  |> list.sort(fn(v1, v2) {
    case v1.1 < v2.1, v1.1 == v2.1, v1.0 < v2.0, v1.0 == v2.0 {
      True, _, _, _ -> order.Lt
      _, True, True, _ -> order.Lt
      _, True, _, True -> order.Eq
      _, _, _, _ -> order.Gt
    }
  })
  |> list.fold(#("", #(-1, 0)), fn(acc, position) {
    let #(str, #(x, y)) = acc
    let #(px, py) = position

    use <- is_same_position(position, #(x, y), acc)

    let str =
      string.append(str, case py - y, px - x {
        0, n -> get_n_dots(n - 1)
        y, _ -> get_n_dots(101 * { y - 1 } + 101 - x + px - 1)
      })

    let str = string.append(str, "#")

    #(str, position)
  })
  |> fn(x) { x.0 }
  |> fn(x) {
    let l = string.length(x)
    string.append(x, get_n_dots(101 * 103 - l))
  }
  |> string.to_graphemes
  |> list.sized_chunk(101)
  |> list.map(string.concat)
  |> list.map(io.println)
  |> fn(_) { io.println("") }
}

fn stop_at_zero(seconds: Int, callback) {
  case seconds {
    0 -> Nil
    _ -> callback()
  }
}

fn do_if(b: Bool, do, callback) {
  case b {
    True -> {
      do()
      callback()
    }
    False -> {
      callback()
    }
  }
}

fn walk(robots: List(Robot), seconds: Int) -> Nil {
  use <- stop_at_zero(seconds)

  robots
  |> list.map(fn(robot) {
    let #(p, v) = robot
    let new_p =
      p
      |> vector_add(v)
      |> vector_mod(101, 103)

    #(new_p, v)
  })
  |> fn(x) {
    use <- do_if(seconds == 2, fn() { print(x) })
    x
  }
  |> walk(seconds - 1)
}

pub fn main() {
  let data = get_data()

  data
  |> parse_data
  |> walk(7775)
}
