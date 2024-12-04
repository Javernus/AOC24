import gleam/int
import gleam/io
import gleam/list.{map}
import gleam/option
import gleam/regexp
import gleam/string
import simplifile

fn is_x_mas(box: List(String)) -> Bool {
  let box = string.join(box, "")

  let assert Ok(re) = regexp.from_string("([MS]).([MS]).A.([MS]).([MS])")
  let matches = regexp.scan(with: re, content: box)

  case matches {
    [match] -> {
      let x_string =
        match.submatches
        |> map(fn(x) { option.unwrap(x, "") })
        |> string.join("")

      case x_string {
        "MMSS" -> True
        "MSMS" -> True
        "SMSM" -> True
        "SSMM" -> True
        _ -> False
      }
    }
    _ -> False
  }
}

pub fn get_data() -> String {
  let assert Ok(data) = simplifile.read("src/data/4.txt")
  data
}

fn get_all_options(lines: List(String)) -> List(List(String)) {
  // Get all 3x3 boxes
  lines
  |> map(string.to_graphemes)
  |> list.window(3)
  |> map(fn(rows) { list.transpose(rows) })
  |> map(fn(rows) { list.window(rows, 3) })
  |> map(fn(rows) { map(rows, fn(box) { list.transpose(box) }) })
  |> list.flatten
  |> map(fn(box) {
    box
    |> map(fn(row) { string.join(row, "") })
  })
}

pub fn is_valid_line(line: String) -> Bool {
  line != ""
}

fn parse_data(data: String) -> Int {
  data
  |> string.split("\n")
  |> list.filter(is_valid_line)
  |> get_all_options()
  |> list.count(is_x_mas)
}

pub fn main() {
  let data = get_data()
  io.println(int.to_string(parse_data(data)))
}
