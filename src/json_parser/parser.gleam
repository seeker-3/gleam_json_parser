import gleam/bool.{guard}
import gleam/dict
import gleam/float
import gleam/int
import gleam/result.{try}
import gleam/string
import json_parser/lexer.{
  type TokenizeError, ColonToken, CommaToken, FalseToken, FloatToken, IntToken,
  LeftCurlyBraceToken, LeftSquareBraceToken, NullToken, RightCurlyBraceToken,
  RightSquareBraceToken, StringToken, TrueToken, tokenize,
}

pub type ParseError {
  UnmatchedTokens
  UnexpectedToken
  ExponentParseFailed
  ArrayMissingComma
  ObjectMissingKey
  ObjectMissingColon
  ObjectMissingComma
  ObjectDuplicateKey
  TokenizingFailed(TokenizeError)
}

pub type JsonValue {
  JsonNull
  JsonBool(Bool)
  JsonInt(Int)
  JsonFloat(Float)
  JsonString(String)
  JsonArray(List(JsonValue))
  JsonObject(dict.Dict(String, JsonValue))
}

pub fn parse(stream) {
  use #(data, tokens) <- try(
    stream
    |> tokenize
    |> result.map_error(TokenizingFailed)
    |> try(parse_value),
  )

  case tokens {
    [] -> Ok(data)
    _ -> Error(UnmatchedTokens)
  }
}

fn parse_int(number) {
  // Lexer should have already validated that this
  let assert Ok(number) = int.parse(number)
  JsonInt(number)
}

fn parse_float(number) {
  // Lexer should have already validated that this
  let assert Ok(number) = float.parse(number)
  JsonFloat(number)
}

fn parse_exponent(number) {
  // Lexer should have already validated that these
  let assert Ok(#(base, exponent)) = string.split_once(number, "E")

  let assert Ok(exponent) = int.parse(exponent)

  let assert Ok(base) =
    case string.contains(base, ".") {
      True -> base
      False -> base <> ".0"
    }
    |> float.parse

  exponent
  |> int.to_float
  |> float.power(base, _)
  |> result.replace_error(ExponentParseFailed)
  |> result.map(JsonFloat)
}

fn add_rest(value, rest) {
  Ok(#(value, rest))
}

fn parse_value(tokens) {
  case tokens {
    [NullToken, ..rest] ->
      JsonNull
      |> add_rest(rest)
    [TrueToken, ..rest] ->
      True
      |> JsonBool
      |> add_rest(rest)
    [FalseToken, ..rest] ->
      False
      |> JsonBool
      |> add_rest(rest)
    [IntToken(number), ..rest] ->
      number
      |> parse_int
      |> add_rest(rest)
    [FloatToken(number, False), ..rest] ->
      number
      |> parse_float
      |> add_rest(rest)
    [FloatToken(number, True), ..rest] ->
      number
      |> parse_exponent
      |> result.map(fn(number) { #(number, rest) })
    [StringToken(text), ..rest] ->
      text
      |> JsonString
      |> add_rest(rest)
    [LeftSquareBraceToken, ..rest] ->
      rest
      |> parse_array(False)
      |> try(fn(array_rest) {
        let #(array, rest) = array_rest

        array
        |> JsonArray
        |> add_rest(rest)
      })
    [LeftCurlyBraceToken, ..rest] ->
      rest
      |> parse_object(False)
      |> try(fn(object_rest) {
        let #(object, rest) = object_rest
        object
        |> JsonObject
        |> add_rest(rest)
      })
    _ -> Error(UnexpectedToken)
  }
}

fn match_token(tokens, token, error) {
  case tokens {
    [t, ..tokens] if t == token -> Ok(tokens)
    _ -> Error(error)
  }
}

fn match_comma(tokens, error, should_match) {
  use <- guard(!should_match, Ok(tokens))
  match_token(tokens, CommaToken, error)
}

fn parse_array(tokens, should_match_comma) {
  case tokens {
    [RightSquareBraceToken, ..tokens] -> add_rest([], tokens)
    _ -> {
      use tokens <- try(match_comma(
        tokens,
        ArrayMissingComma,
        should_match_comma,
      ))
      use #(value, tokens) <- try(parse_value(tokens))
      use #(values, tokens) <- try(parse_array(tokens, True))

      add_rest([value, ..values], tokens)
    }
  }
}

fn match_object_key(tokens) {
  case tokens {
    [StringToken(key), ..rest] -> add_rest(key, rest)
    _ -> Error(ObjectMissingKey)
  }
}

fn parse_object(tokens, should_match_comma) {
  case tokens {
    [RightCurlyBraceToken, ..tokens] -> add_rest(dict.new(), tokens)
    _ -> {
      use tokens <- try(match_comma(
        tokens,
        ObjectMissingComma,
        should_match_comma,
      ))
      use #(key, tokens) <- try(match_object_key(tokens))
      use tokens <- try(match_token(tokens, ColonToken, ObjectMissingColon))
      use #(value, tokens) <- try(parse_value(tokens))
      use #(object, tokens) <- try(parse_object(tokens, True))
      use <- guard(dict.has_key(object, key), Error(ObjectDuplicateKey))

      [#(key, value)]
      |> dict.from_list
      |> dict.merge(object)
      |> add_rest(tokens)
    }
  }
}
