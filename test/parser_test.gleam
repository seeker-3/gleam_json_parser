import gleam/dict
import gleeunit/should
import json_parser/escapes
import json_parser/parser.{
  ArrayMissingComma, JsonArray, JsonBool, JsonFloat, JsonInt, JsonNull,
  JsonObject, JsonString, ObjectDuplicateKey, ObjectMissingColon,
  ObjectMissingComma, ObjectMissingKey, UnexpectedToken, UnmatchedTokens, parse,
}

pub fn primitives_test() {
  "null"
  |> parse
  |> should.equal(Ok(JsonNull))

  "true"
  |> parse
  |> should.equal(Ok(JsonBool(True)))

  "false"
  |> parse
  |> should.equal(Ok(JsonBool(False)))

  "123"
  |> parse
  |> should.equal(Ok(JsonInt(123)))

  "123.456"
  |> parse
  |> should.equal(Ok(JsonFloat(123.456)))

  "2E2"
  |> parse
  |> should.equal(Ok(JsonFloat(4.0)))

  "123.456E1"
  |> parse
  |> should.equal(Ok(JsonFloat(123.456)))

  "\"\""
  |> parse
  |> should.equal(Ok(JsonString("")))

  "\"hello\""
  |> parse
  |> should.equal(Ok(JsonString("hello")))

  "\"\\n\""
  |> parse
  |> should.equal(Ok(JsonString("\\n")))

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
  |> parse
  |> should.equal(Ok(JsonString(all_escapes)))
}

pub fn arrays_test() {
  "[]"
  |> parse
  |> should.equal(Ok(JsonArray([])))

  "[true]"
  |> parse
  |> should.equal(Ok(JsonArray([JsonBool(True)])))

  "[true, false, null, 123, 123.456, 2E2, 123.456E1]"
  |> parse
  |> should.equal(
    Ok(
      JsonArray([
        JsonBool(True),
        JsonBool(False),
        JsonNull,
        JsonInt(123),
        JsonFloat(123.456),
        JsonFloat(4.0),
        JsonFloat(123.456),
      ]),
    ),
  )

  "[1, 1, [2, 2, [3, 3], 2, 2], 1, 1]"
  |> parse
  |> should.equal(
    Ok(
      JsonArray([
        JsonInt(1),
        JsonInt(1),
        JsonArray([
          JsonInt(2),
          JsonInt(2),
          JsonArray([JsonInt(3), JsonInt(3)]),
          JsonInt(2),
          JsonInt(2),
        ]),
        JsonInt(1),
        JsonInt(1),
      ]),
    ),
  )
}

pub fn objects_test() {
  "{}"
  |> parse
  |> should.equal(Ok(JsonObject(dict.new())))

  "{
    \"string\": \"test text\"
  }"
  |> parse
  |> should.equal(
    Ok(JsonObject(dict.from_list([#("string", JsonString("test text"))]))),
  )

  "{
    \"string\": \"test text\",
    \"integer\": 123456,
    \"float\": 123.456,
    \"true\": true,
    \"false\": false,
    \"null\": null
  }"
  |> parse
  |> should.equal(
    Ok(
      JsonObject(
        dict.from_list([
          #("string", JsonString("test text")),
          #("integer", JsonInt(123_456)),
          #("float", JsonFloat(123.456)),
          #("true", JsonBool(True)),
          #("false", JsonBool(False)),
          #("null", JsonNull),
        ]),
      ),
    ),
  )

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
  |> parse
  |> should.equal(
    Ok(
      JsonObject(
        dict.from_list([
          #("string", JsonString("test text")),
          #("integer", JsonInt(123_456)),
          #("float", JsonFloat(123.456)),
          #("true", JsonBool(True)),
          #("false", JsonBool(False)),
          #("null", JsonNull),
          #(
            "array",
            JsonArray([
              JsonString("string"),
              JsonInt(123_446),
              JsonFloat(123.456),
              JsonBool(True),
              JsonBool(False),
              JsonNull,
              JsonArray([]),
              JsonObject(dict.new()),
            ]),
          ),
          #(
            "object",
            JsonObject(
              dict.from_list([
                #("string", JsonString("test text")),
                #("integer", JsonInt(123_456)),
                #("float", JsonFloat(123.456)),
                #("true", JsonBool(True)),
                #("false", JsonBool(False)),
                #("null", JsonNull),
                #(
                  "array",
                  JsonArray([
                    JsonString("string"),
                    JsonInt(123_446),
                    JsonFloat(123.456),
                    JsonBool(True),
                    JsonBool(False),
                    JsonNull,
                    JsonArray([]),
                    JsonObject(dict.new()),
                  ]),
                ),
              ]),
            ),
          ),
        ]),
      ),
    ),
  )
}

pub fn errors_test() {
  "true true"
  |> parse
  |> should.equal(Error(UnmatchedTokens))

  ","
  |> parse
  |> should.equal(Error(UnexpectedToken))

  ":"
  |> parse
  |> should.equal(Error(UnexpectedToken))

  "}"
  |> parse
  |> should.equal(Error(UnexpectedToken))

  "]"
  |> parse
  |> should.equal(Error(UnexpectedToken))

  "[1 2]"
  |> parse
  |> should.equal(Error(ArrayMissingComma))

  "{ : 123}"
  |> parse
  |> should.equal(Error(ObjectMissingKey))

  "{\"key\": 123, : 456}"
  |> parse
  |> should.equal(Error(ObjectMissingKey))

  "{\"key1\" 123}"
  |> parse
  |> should.equal(Error(ObjectMissingColon))

  "{\"key1\": 123, \"key2\" 456}"
  |> parse
  |> should.equal(Error(ObjectMissingColon))

  "{\"key1\": 123 \"key2\": 456}"
  |> parse
  |> should.equal(Error(ObjectMissingComma))

  "{\"key\": 123, \"key\": 456}"
  |> parse
  |> should.equal(Error(ObjectDuplicateKey))
}
