local LeptJson = require "src.lept_json"
local ParseResult = LeptJson.ParseResult

describe("JSON Parser for ERROR", function()
    local TEST_PARSE_ERROR = function(err, json)
    end

    before(function()
        TEST_PARSE_ERROR = function(err, json)
            local result = LeptJson.Parse(json)
            local value, state = result.value, result.state
            assert_equal(value:getType(), LeptJson.NodeType.NULL)
            assert_equal(state, err)
        end
    end)

    it("should generate PARSE_EXPECT_VALUE correctly", function()
        TEST_PARSE_ERROR(ParseResult.PARSE_EXPECT_VALUE, "");
        TEST_PARSE_ERROR(ParseResult.PARSE_EXPECT_VALUE, " ");
    end)

    it("should generate PARSE_INVALID_VALUE correctly", function()
        TEST_PARSE_ERROR(ParseResult.PARSE_INVALID_VALUE, "nul");
        TEST_PARSE_ERROR(ParseResult.PARSE_INVALID_VALUE, "?");

        -- invalid number
        TEST_PARSE_ERROR(ParseResult.PARSE_INVALID_VALUE, "+0");
        TEST_PARSE_ERROR(ParseResult.PARSE_INVALID_VALUE, "+1");
        TEST_PARSE_ERROR(ParseResult.PARSE_INVALID_VALUE, ".123"); --  at least one digit before '.'
        TEST_PARSE_ERROR(ParseResult.PARSE_INVALID_VALUE, "1.");   --  at least one digit after '.'
        TEST_PARSE_ERROR(ParseResult.PARSE_INVALID_VALUE, "INF");
        TEST_PARSE_ERROR(ParseResult.PARSE_INVALID_VALUE, "inf");
        TEST_PARSE_ERROR(ParseResult.PARSE_INVALID_VALUE, "NAN");
        TEST_PARSE_ERROR(ParseResult.PARSE_INVALID_VALUE, "nan");

        -- -- invalid value in array
        TEST_PARSE_ERROR(ParseResult.PARSE_INVALID_VALUE, "[1,]");
        TEST_PARSE_ERROR(ParseResult.PARSE_INVALID_VALUE, "[\"a\", nul]");
    end)

    it("should generate PARSE_NUMBER_TOO_BIG correctly", function()
        TEST_PARSE_ERROR(ParseResult.PARSE_ROOT_NOT_SINGULAR, "null x");

        -- invalid number
        TEST_PARSE_ERROR(ParseResult.PARSE_ROOT_NOT_SINGULAR, "0123"); --  after zero should be '.' or nothing
        TEST_PARSE_ERROR(ParseResult.PARSE_ROOT_NOT_SINGULAR, "0x0");
        TEST_PARSE_ERROR(ParseResult.PARSE_ROOT_NOT_SINGULAR, "0x123");
    end)

    it("should generate PARSE_NUMBER_TOO_BIG correctly", function()
        TEST_PARSE_ERROR(ParseResult.PARSE_NUMBER_TOO_BIG, "1e309");
        TEST_PARSE_ERROR(ParseResult.PARSE_NUMBER_TOO_BIG, "-1e309");
    end)

    it("should generate PARSE_MISS_QUOTATION_MARK correctly", function()
        TEST_PARSE_ERROR(ParseResult.PARSE_MISS_QUOTATION_MARK, "\"");
        TEST_PARSE_ERROR(ParseResult.PARSE_MISS_QUOTATION_MARK, "\"abc");
    end)

    it("should generate PARSE_INVALID_STRING_ESCAPE correctly", function()
        TEST_PARSE_ERROR(ParseResult.PARSE_INVALID_STRING_ESCAPE, "\"\\v\"");
        TEST_PARSE_ERROR(ParseResult.PARSE_INVALID_STRING_ESCAPE, "\"\\'\"");
        TEST_PARSE_ERROR(ParseResult.PARSE_INVALID_STRING_ESCAPE, "\"\\0\"");
        TEST_PARSE_ERROR(ParseResult.PARSE_INVALID_STRING_ESCAPE, "\"\\x12\"");
    end)

    it("should generate PARSE_INVALID_STRING_CHAR correctly", function()
        TEST_PARSE_ERROR(ParseResult.PARSE_INVALID_STRING_CHAR, "\"\x01\"");
        TEST_PARSE_ERROR(ParseResult.PARSE_INVALID_STRING_CHAR, "\"\x1F\"");
    end)

    it("should generate PARSE_INVALID_UNICODE_HEX correctly", function()
        TEST_PARSE_ERROR(ParseResult.PARSE_INVALID_UNICODE_HEX, "\"\\u\"");
        TEST_PARSE_ERROR(ParseResult.PARSE_INVALID_UNICODE_HEX, "\"\\u0\"");
        TEST_PARSE_ERROR(ParseResult.PARSE_INVALID_UNICODE_HEX, "\"\\u01\"");
        TEST_PARSE_ERROR(ParseResult.PARSE_INVALID_UNICODE_HEX, "\"\\u012\"");
        TEST_PARSE_ERROR(ParseResult.PARSE_INVALID_UNICODE_HEX, "\"\\u/000\"");
        TEST_PARSE_ERROR(ParseResult.PARSE_INVALID_UNICODE_HEX, "\"\\uG000\"");
        TEST_PARSE_ERROR(ParseResult.PARSE_INVALID_UNICODE_HEX, "\"\\u0/00\"");
        TEST_PARSE_ERROR(ParseResult.PARSE_INVALID_UNICODE_HEX, "\"\\u0G00\"");
        TEST_PARSE_ERROR(ParseResult.PARSE_INVALID_UNICODE_HEX, "\"\\u0/00\"");
        TEST_PARSE_ERROR(ParseResult.PARSE_INVALID_UNICODE_HEX, "\"\\u00G0\"");
        TEST_PARSE_ERROR(ParseResult.PARSE_INVALID_UNICODE_HEX, "\"\\u000/\"");
        TEST_PARSE_ERROR(ParseResult.PARSE_INVALID_UNICODE_HEX, "\"\\u000G\"");
        TEST_PARSE_ERROR(ParseResult.PARSE_INVALID_UNICODE_HEX, "\"\\u 123\"");
    end)

    it("should generate PARSE_INVALID_UNICODE_SURROGATE correctly", function()
        TEST_PARSE_ERROR(ParseResult.PARSE_INVALID_UNICODE_SURROGATE, "\"\\uD800\"");
        TEST_PARSE_ERROR(ParseResult.PARSE_INVALID_UNICODE_SURROGATE, "\"\\uDBFF\"");
        TEST_PARSE_ERROR(ParseResult.PARSE_INVALID_UNICODE_SURROGATE, "\"\\uD800\\\\\"");
        TEST_PARSE_ERROR(ParseResult.PARSE_INVALID_UNICODE_SURROGATE, "\"\\uD800\\uDBFF\"");
        TEST_PARSE_ERROR(ParseResult.PARSE_INVALID_UNICODE_SURROGATE, "\"\\uD800\\uE000\"");
    end)

    it("should generate PARSE_MISS_COMMA_OR_SQUARE_BRACKET correctly", function()
        TEST_PARSE_ERROR(ParseResult.PARSE_MISS_COMMA_OR_SQUARE_BRACKET, "[1");
        TEST_PARSE_ERROR(ParseResult.PARSE_MISS_COMMA_OR_SQUARE_BRACKET, "[1}");
        TEST_PARSE_ERROR(ParseResult.PARSE_MISS_COMMA_OR_SQUARE_BRACKET, "[1 2");
        TEST_PARSE_ERROR(ParseResult.PARSE_MISS_COMMA_OR_SQUARE_BRACKET, "[[]");
    end)

    it("should generate PARSE_MISS_KEY correctly", function()
        TEST_PARSE_ERROR(ParseResult.PARSE_MISS_KEY, "{:1,");
        TEST_PARSE_ERROR(ParseResult.PARSE_MISS_KEY, "{1:1,");
        TEST_PARSE_ERROR(ParseResult.PARSE_MISS_KEY, "{true:1,");
        TEST_PARSE_ERROR(ParseResult.PARSE_MISS_KEY, "{false:1,");
        TEST_PARSE_ERROR(ParseResult.PARSE_MISS_KEY, "{null:1,");
        TEST_PARSE_ERROR(ParseResult.PARSE_MISS_KEY, "{[]:1,");
        TEST_PARSE_ERROR(ParseResult.PARSE_MISS_KEY, "{{}:1,");
        TEST_PARSE_ERROR(ParseResult.PARSE_MISS_KEY, "{\"a\":1,");
    end)

    it("should generate PARSE_MISS_COLON correctly", function()
        TEST_PARSE_ERROR(ParseResult.PARSE_MISS_COLON, "{\"a\"}");
        TEST_PARSE_ERROR(ParseResult.PARSE_MISS_COLON, "{\"a\",\"b\"}");
    end)

    it("should generate PARSE_MISS_COMMA_OR_CURLY_BRACKET correctly", function()
        TEST_PARSE_ERROR(ParseResult.PARSE_MISS_COMMA_OR_CURLY_BRACKET, "{\"a\":1");
        TEST_PARSE_ERROR(ParseResult.PARSE_MISS_COMMA_OR_CURLY_BRACKET, "{\"a\":1]");
        TEST_PARSE_ERROR(ParseResult.PARSE_MISS_COMMA_OR_CURLY_BRACKET, "{\"a\":1 \"b\"");
        TEST_PARSE_ERROR(ParseResult.PARSE_MISS_COMMA_OR_CURLY_BRACKET, "{\"a\":{}");
    end)
end)
