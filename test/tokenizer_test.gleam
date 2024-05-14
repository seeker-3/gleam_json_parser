import gleeunit/should
import json_parser/escapes
import json_parser/lexer.{
  ColonToken, CommaToken, FalseToken, FloatToken, IntToken, InvalidDot,
  InvalidEscape, InvalidExponent, InvalidToken, LeftCurlyBraceToken,
  LeftSquareBraceToken, NoNumberAfterDot, NoNumberAfterExponent, NullToken,
  RightCurlyBraceToken, RightSquareBraceToken, StringLineBreak, StringToken,
  TrueToken, UnterminatedString, tokenize,
}

pub fn whitespace_test() {
  " \r\n"
  |> tokenize
  |> should.equal(Ok([]))
}

pub fn numbers_test() {
  "123"
  |> tokenize
  |> should.equal(Ok([IntToken("123")]))

  "123.456"
  |> tokenize
  |> should.equal(Ok([FloatToken("123.456", False)]))

  "123E456"
  |> tokenize
  |> should.equal(Ok([FloatToken("123E456", True)]))

  "123e456"
  |> tokenize
  |> should.equal(Ok([FloatToken("123E456", True)]))

  "123.456E789"
  |> tokenize
  |> should.equal(Ok([FloatToken("123.456E789", True)]))

  "123.456e789"
  |> tokenize
  |> should.equal(Ok([FloatToken("123.456E789", True)]))
}

pub fn keywords_test() {
  "true"
  |> tokenize
  |> should.equal(Ok([TrueToken]))

  "false"
  |> tokenize
  |> should.equal(Ok([FalseToken]))

  "null"
  |> tokenize
  |> should.equal(Ok([NullToken]))

  "true false null"
  |> tokenize
  |> should.equal(Ok([TrueToken, FalseToken, NullToken]))
}

pub fn symbols_test() {
  "[]"
  |> tokenize
  |> should.equal(Ok([LeftSquareBraceToken, RightSquareBraceToken]))

  "{}"
  |> tokenize
  |> should.equal(Ok([LeftCurlyBraceToken, RightCurlyBraceToken]))

  ":,"
  |> tokenize
  |> should.equal(Ok([ColonToken, CommaToken]))

  " [ ] { } : , "
  |> tokenize
  |> should.equal(
    Ok([
      LeftSquareBraceToken,
      RightSquareBraceToken,
      LeftCurlyBraceToken,
      RightCurlyBraceToken,
      ColonToken,
      CommaToken,
    ]),
  )
}

pub fn strings_test() {
  "\"\""
  |> tokenize
  |> should.equal(Ok([StringToken("")]))

  "\"hello\""
  |> tokenize
  |> should.equal(Ok([StringToken("hello")]))

  let all_escapes =
    " "
    <> escapes.back_slash
    <> " "
    <> escapes.forward_slash
    <> " "
    <> escapes.backspace
    <> " "
    <> escapes.form_feed
    <> " "
    <> escapes.newline
    <> " "
    <> escapes.carriage_return
    <> " "
    <> escapes.tab
    <> " "
    <> escapes.double_quote
    <> " "

  { "\"" <> all_escapes <> "\"" }
  |> tokenize
  |> should.equal(Ok([StringToken(all_escapes)]))
}

pub fn records_test() {
  "{
    \"string\": \"test text\",
    \"integer\": 123456,
    \"float\": 123.456,
    \"true\": true,
    \"false\": false,
    \"null\": null,
    \"array\": [\"string\", 123446, 123.456, true, false, null, [], {}],
    \"object\": {
      \"string\": \"test text\",
      \"integer\": 123456,
      \"float\": 123.456,
      \"true\": true,
      \"false\": false,
      \"null\": null,
      \"array\": [\"string\", 123446, 123.456, true, false, null, [], {}]
    }
  }"
  |> tokenize
  |> should.equal(
    Ok([
      LeftCurlyBraceToken,
      StringToken("string"),
      ColonToken,
      StringToken("test text"),
      CommaToken,
      StringToken("integer"),
      ColonToken,
      IntToken("123456"),
      CommaToken,
      StringToken("float"),
      ColonToken,
      FloatToken("123.456", False),
      CommaToken,
      StringToken("true"),
      ColonToken,
      TrueToken,
      CommaToken,
      StringToken("false"),
      ColonToken,
      FalseToken,
      CommaToken,
      StringToken("null"),
      ColonToken,
      NullToken,
      CommaToken,
      StringToken("array"),
      ColonToken,
      LeftSquareBraceToken,
      StringToken("string"),
      CommaToken,
      IntToken("123446"),
      CommaToken,
      FloatToken("123.456", False),
      CommaToken,
      TrueToken,
      CommaToken,
      FalseToken,
      CommaToken,
      NullToken,
      CommaToken,
      LeftSquareBraceToken,
      RightSquareBraceToken,
      CommaToken,
      LeftCurlyBraceToken,
      RightCurlyBraceToken,
      RightSquareBraceToken,
      CommaToken,
      StringToken("object"),
      ColonToken,
      LeftCurlyBraceToken,
      StringToken("string"),
      ColonToken,
      StringToken("test text"),
      CommaToken,
      StringToken("integer"),
      ColonToken,
      IntToken("123456"),
      CommaToken,
      StringToken("float"),
      ColonToken,
      FloatToken("123.456", False),
      CommaToken,
      StringToken("true"),
      ColonToken,
      TrueToken,
      CommaToken,
      StringToken("false"),
      ColonToken,
      FalseToken,
      CommaToken,
      StringToken("null"),
      ColonToken,
      NullToken,
      CommaToken,
      StringToken("array"),
      ColonToken,
      LeftSquareBraceToken,
      StringToken("string"),
      CommaToken,
      IntToken("123446"),
      CommaToken,
      FloatToken("123.456", False),
      CommaToken,
      TrueToken,
      CommaToken,
      FalseToken,
      CommaToken,
      NullToken,
      CommaToken,
      LeftSquareBraceToken,
      RightSquareBraceToken,
      CommaToken,
      LeftCurlyBraceToken,
      RightCurlyBraceToken,
      RightSquareBraceToken,
      RightCurlyBraceToken,
      RightCurlyBraceToken,
    ]),
  )
}

pub fn token_errors_test() {
  "+"
  |> tokenize
  |> should.equal(Error(InvalidToken))

  "."
  |> tokenize
  |> should.equal(Error(InvalidToken))

  "("
  |> tokenize
  |> should.equal(Error(InvalidToken))

  ")"
  |> tokenize
  |> should.equal(Error(InvalidToken))
}

pub fn number_errors_test() {
  "123."
  |> tokenize
  |> should.equal(Error(NoNumberAfterDot))

  "123E"
  |> tokenize
  |> should.equal(Error(NoNumberAfterExponent))

  "123x"
  |> tokenize
  |> should.equal(Error(InvalidToken))

  "123.456.789"
  |> tokenize
  |> should.equal(Error(InvalidDot))

  "123E456E789"
  |> tokenize
  |> should.equal(Error(InvalidExponent))

  "123E456.789"
  |> tokenize
  |> should.equal(Error(InvalidDot))
}

pub fn string_errors_test() {
  "\"hello"
  |> tokenize
  |> should.equal(Error(UnterminatedString))

  "\"\\x\""
  |> tokenize
  |> should.equal(Error(InvalidEscape))

  "\"\n\""
  |> tokenize
  |> should.equal(Error(StringLineBreak))
}
