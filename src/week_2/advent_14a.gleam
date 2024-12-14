import gleam/dict
import gleam/int
import gleam/io
import gleam/list.{map}
import gleam/option.{Some}
import gleam/regexp
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

fn scalar_multiply(v: Vector, scalar: Int) -> Vector {
  #(v.0 * scalar, v.1 * scalar)
}

fn vector_mod(v: Vector, modulo_x: Int, modulo_y: Int) -> Vector {
  let assert Ok(v0) = int.modulo(v.0, modulo_x)
  let assert Ok(v1) = int.modulo(v.1, modulo_y)

  #(v0, v1)
}

fn walk(robot: Robot, seconds: Int) -> Vector {
  let #(p, v) = robot
  v
  |> scalar_multiply(seconds)
  |> vector_add(p)
  |> vector_mod(101, 103)
}

fn is_in_quadrant(position, callback) {
  let #(x, y) = position

  case x == 50 || y == 51 {
    True -> -1
    False -> callback()
  }
}

fn count_quadrants(positions: List(Vector)) -> Int {
  list.group(positions, fn(position) {
    let #(x, y) = position
    use <- is_in_quadrant(position)
    case x < 50, y < 51 {
      True, True -> 0
      False, True -> 1
      True, False -> 2
      False, False -> 3
    }
  })
  |> dict.filter(fn(index, _) { index != -1 })
  |> dict.to_list
  |> list.map(fn(values) { list.length(values.1) })
  |> int.product
}

pub fn main() {
  let data = get_data()

  data
  |> parse_data
  |> map(fn(robots) { walk(robots, 100) })
  |> count_quadrants
  |> int.to_string
  |> io.println
}
