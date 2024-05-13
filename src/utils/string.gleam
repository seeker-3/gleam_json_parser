import gleam/iterator
import gleam/string

pub fn to_iter(string) {
  string
  |> string.split("")
  |> iterator.from_list
}

pub fn from_iter(iter) {
  iter
  |> iterator.to_list
  |> string.join("")
}
