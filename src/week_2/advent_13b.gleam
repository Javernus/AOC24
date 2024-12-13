import gleam/int
import gleam/io
import gleam/list.{map}
import gleam/option.{Some}
import gleam/regexp
import simplifile

type XY =
  #(Int, Int)

type Machine =
  #(XY, XY, XY)

type Matrix =
  #(Int, Int, Int, Int)

pub fn get_data() -> String {
  let assert Ok(data) = simplifile.read("src/data/13.txt")
  data
}

fn parse_numbers(match: regexp.Match) -> XY {
  case match {
    regexp.Match(_, [Some(x), Some(y)]) -> {
      let assert Ok(x) = int.parse(x)
      let assert Ok(y) = int.parse(y)

      #(x, y)
    }
    _ -> #(-1, -1)
  }
}

pub fn parse_data(data: String) -> List(Machine) {
  let assert Ok(a_re) = regexp.from_string("Button A: X\\+(\\d+?), Y\\+(\\d+)")
  let a_buttons = regexp.scan(with: a_re, content: data)
  let assert Ok(b_re) = regexp.from_string("Button B: X\\+(\\d+?), Y\\+(\\d+)")
  let b_buttons = regexp.scan(with: b_re, content: data)
  let assert Ok(prize_re) = regexp.from_string("Prize: X=(\\d+?), Y=(\\d+)")
  let prizes = regexp.scan(with: prize_re, content: data)

  a_buttons
  |> list.zip(b_buttons)
  |> list.zip(prizes)
  |> list.map(fn(machine) {
    let #(#(a, b), p) = machine
    let prize = parse_numbers(p)
    let prize = #(10_000_000_000_000 + prize.0, 10_000_000_000_000 + prize.1)
    #(parse_numbers(a), parse_numbers(b), prize)
  })
}

fn create_matrix(a: XY, b: XY) -> Matrix {
  #(a.0, b.0, a.1, b.1)
}

// Inverse determinant
fn determinant(m: Matrix) -> Int {
  m.0 * m.3 - m.1 * m.2
}

// Without determinant multiplication
fn inverse_matrix(m: Matrix) -> Matrix {
  #(m.3, -m.1, -m.2, m.0)
}

fn matrix_vector_multiply(m: Matrix, v: XY, d: Int) -> XY {
  case
    int.modulo({ m.0 * v.0 + m.1 * v.1 }, d),
    int.modulo({ m.2 * v.0 + m.3 * v.1 }, d)
  {
    Ok(0), Ok(0) -> #(
      { m.0 * v.0 + m.1 * v.1 } / d,
      { m.2 * v.0 + m.3 * v.1 } / d,
    )
    _, _ -> {
      #(0, 0)
    }
  }
}

fn minimum_tokens(machine: Machine) -> Int {
  let #(a, b, p) = machine
  let matrix = create_matrix(a, b)

  matrix
  |> inverse_matrix
  |> matrix_vector_multiply(p, determinant(matrix))
  |> fn(outcome) {
    case outcome.0 < 0 || outcome.1 < 0 {
      True -> 0
      False -> 3 * outcome.0 + outcome.1
    }
  }
}

pub fn main() {
  let data = get_data()

  data
  |> parse_data
  |> map(minimum_tokens)
  |> int.sum
  |> int.to_string
  |> io.println
}
