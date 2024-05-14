import gleam/io.{debug, println}

import json_parser/parser.{parse}

pub fn main() {
  let data = parse("[1, 2, 3]")
  case data {
    Ok(value) -> {
      println("Parsed successfully")
      debug(value)
      Nil
    }
    Error(error) -> {
      println("Failed to parse")
      debug(error)
      Nil
    }
  }
}
