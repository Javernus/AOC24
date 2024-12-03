import gleam/int.{parse}
import gleam/io
import gleam/list.{fold, map}
import gleam/option.{Some}
import gleam/regexp
import simplifile

type Type {
  Mul
  Do
  Dont
  Ignore
}

pub fn get_data() -> String {
  let assert Ok(data) = simplifile.read("src/data/3.txt")
  data
}

pub fn parse_data(data: String) -> Int {
  let assert Ok(re) =
    regexp.from_string("do(?:n't)?\\(\\)|mul\\((\\d{1,3}),(\\d{1,3})\\)")
  let matches = regexp.scan(with: re, content: data)

  matches
  |> map(fn(match) {
    case match {
      regexp.Match(_, [Some(a), Some(b)]) -> {
        let assert Ok(a) = parse(a)
        let assert Ok(b) = parse(b)

        #(a * b, Mul)
      }
      regexp.Match("do()", []) -> {
        #(0, Do)
      }
      regexp.Match("don't()", []) -> {
        #(0, Dont)
      }
      _ -> {
        #(0, Ignore)
      }
    }
  })
  |> fold(#(0, Do), fn(acc, match) {
    let #(new_value, t) = match
    let #(value, acc_t) = acc

    case t {
      Do -> {
        #(value, t)
      }
      Dont -> {
        #(value, t)
      }
      Mul -> {
        case acc_t {
          Do -> {
            #(value + new_value, acc_t)
          }
          _ -> {
            #(value, acc_t)
          }
        }
      }
      Ignore -> {
        #(value, acc_t)
      }
    }
  })
  |> fn(x) { x.0 }
}

pub fn main() {
  let data = get_data()
  io.println(int.to_string(parse_data(data)))
}
