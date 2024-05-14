# json_parser

<!-- [![Package Version](https://img.shields.io/hexpm/v/json_parser)](https://hex.pm/packages/json_parser) -->
<!-- [![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/json_parser/) -->

```sh
gleam add json_parser
```

```gleam
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

```

<!-- Further documentation can be found at <https://hexdocs.pm/json_parser>. -->

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
gleam shell # Run an Erlang shell
```
