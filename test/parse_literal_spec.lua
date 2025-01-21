local LeptJson = require "src.lept_json"

describe("JSON Parser for literal", function()
    it("should parse null value correctly", function()
        local result = LeptJson.Parse("null")
        local value, state = result.value, result.state
        assert_equal(value.getType(), LeptJson.NodeType.NULL)
        assert_equal(state, LeptJson.ParseResult.PARSE_OK)
    end)

    it("should parse true value correctly", function()
        local result = LeptJson.Parse("true")
        local value, state = result.value, result.state
        assert_equal(value.getType(), LeptJson.NodeType.TRUE)
        assert_equal(state, LeptJson.ParseResult.PARSE_OK)
    end)

    it("should parse false value correctly", function()
        local result = LeptJson.Parse("false")
        local value, state = result.value, result.state
        assert_equal(value.getType(), LeptJson.NodeType.FALSE)
        assert_equal(state, LeptJson.ParseResult.PARSE_OK)
    end)
end)
