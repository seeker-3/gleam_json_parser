import gleam/bool.{guard}
import gleam/result
import gleam/string

pub type TokenizeError {
  InvalidToken
  UnexpectedEndOfString
  StringLineBreak
  UnterminatedString
  InvalidEscape
  NoNumberAfterDot
  NoNumberAfterExponent
  InvalidDot
  InvalidExponent
}

pub type Token {
  IntToken(String)
  FloatToken(String, Bool)
  StringToken(String)
  NullToken
  FalseToken
  TrueToken
  LeftSquareBraceToken
  RightSquareBraceToken
  LeftCurlyBraceToken
  RightCurlyBraceToken
  CommaToken
  ColonToken
}

fn skip(text, number) {
  string.slice(text, number, string.length(text))
}

fn skip_match(stream, match) {
  string.slice(stream, string.length(match), string.length(stream))
}

fn match_string(stream) {
  case stream {
    "\"" <> _ -> Ok("")
    "\\" <> rest -> {
      let escape = match_escape(rest)
      let match =
        rest
        |> skip(1)
        |> match_string

      use escape <- result.try(escape)
      use match <- result.map(match)
      "\\" <> escape <> match
    }
    "\n" <> _ | "\r" <> _ -> Error(StringLineBreak)
    "" -> Error(UnterminatedString)
    rest -> {
      // Can't fail since previous case is the empty string
      let assert Ok(c) = string.first(rest)
      let match =
        rest
        |> skip(1)
        |> match_string

      use match <- result.map(match)
      c <> match
    }
  }
}

fn match_escape(stream) {
  case stream {
    "\\" <> _ -> Ok("\\")
    "\"" <> _ -> Ok("\"")
    "/" as c <> _
    | "b" as c <> _
    | "f" as c <> _
    | "n" as c <> _
    | "r" as c <> _
    | "t" as c <> _ -> Ok(c)
    _ -> Error(InvalidEscape)
  }
}

fn match_number(stream) {
  do_match_number(stream, False, False)
}

fn do_match_number(stream, is_decimal, is_exponent) {
  case stream {
    "0" as c <> rest
    | "1" as c <> rest
    | "2" as c <> rest
    | "3" as c <> rest
    | "4" as c <> rest
    | "5" as c <> rest
    | "6" as c <> rest
    | "7" as c <> rest
    | "8" as c <> rest
    | "9" as c <> rest -> {
      use match <- result.map(do_match_number(rest, is_decimal, is_exponent))
      c <> match
    }
    "." as c <> rest -> {
      use <- guard(is_decimal, Error(InvalidDot))
      let digit = match_digit(rest, NoNumberAfterDot)
      let match =
        rest
        |> skip(1)
        |> do_match_number(True, False)

      use digit <- result.try(digit)
      use match <- result.map(match)
      c <> digit <> match
    }
    "e" <> rest | "E" <> rest -> {
      use <- guard(is_exponent, Error(InvalidExponent))
      let digit = match_digit(rest, NoNumberAfterExponent)
      let match =
        rest
        |> skip(1)
        |> do_match_number(True, True)

      use digit <- result.try(digit)
      use match <- result.map(match)
      "E" <> digit <> match
    }
    _ -> Ok("")
  }
}

fn match_digit(stream, error) {
  case stream {
    "0" as c <> _
    | "1" as c <> _
    | "2" as c <> _
    | "3" as c <> _
    | "4" as c <> _
    | "5" as c <> _
    | "6" as c <> _
    | "7" as c <> _
    | "8" as c <> _
    | "9" as c <> _ -> Ok(c)
    _ -> Error(error)
  }
}

fn add_token(token, rest: String) {
  rest
  |> tokenize
  |> result.map(fn(tokens) { [token, ..tokens] })
}

pub fn tokenize(stream) {
  case stream {
    "null" <> rest -> add_token(NullToken, rest)
    "true" <> rest -> add_token(TrueToken, rest)
    "false" <> rest -> add_token(FalseToken, rest)
    "[" <> rest -> add_token(LeftSquareBraceToken, rest)
    "]" <> rest -> add_token(RightSquareBraceToken, rest)
    "{" <> rest -> add_token(LeftCurlyBraceToken, rest)
    "}" <> rest -> add_token(RightCurlyBraceToken, rest)
    "," <> rest -> add_token(CommaToken, rest)
    ":" <> rest -> add_token(ColonToken, rest)
    "\"" <> rest -> {
      use match <- result.try(match_string(rest))
      stream
      |> skip_match(match)
      // Skip quotes
      |> skip(2)
      |> add_token(StringToken(match), _)
    }
    "-" as c <> rest
    | "0" as c <> rest
    | "1" as c <> rest
    | "2" as c <> rest
    | "3" as c <> rest
    | "4" as c <> rest
    | "5" as c <> rest
    | "6" as c <> rest
    | "7" as c <> rest
    | "8" as c <> rest
    | "9" as c <> rest -> {
      use match <- result.try(match_number(rest))
      let match = c <> match

      let is_exponent = string.contains(match, "E")
      let is_float = string.contains(match, ".") || is_exponent

      let token = case is_float {
        True -> FloatToken(match, is_exponent)
        False -> IntToken(match)
      }
      stream
      |> skip_match(match)
      |> add_token(token, _)
    }

    // Skip whitespace
    "\n" <> rest | "\r" <> rest | "\t" <> rest | " " <> rest -> tokenize(rest)
    "" -> Ok([])
    _ -> Error(InvalidToken)
  }
}
