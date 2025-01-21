local LeptJson = require "src.lept_json"

describe("JSON Parser for array", function()
    it("should parse empty array correctly", function()
        local result = LeptJson.Parse("[ ]")
        local value, state = result.value, result.state
        assert_equal(value.getType(), LeptJson.NodeType.ARRAY)
        assert_equal(state, LeptJson.ParseResult.PARSE_OK)
        assert_empty(value.getArray())
    end)

    it("should parse array correctly", function()
        local result = LeptJson.Parse("[ null , false , true , 123 , \"abc\" ]")
        local value, state = result.value, result.state
        assert_equal(value.getType(), LeptJson.NodeType.ARRAY)
        assert_equal(state, LeptJson.ParseResult.PARSE_OK)
        assert_not_empty(value.getArray())
        assert_equal(#value.getArray(), 5)

        local array = value.getArray()
        assert_equal(array[1].getType(), LeptJson.NodeType.NULL)
        assert_equal(array[2].getType(), LeptJson.NodeType.FALSE)
        assert_equal(array[3].getType(), LeptJson.NodeType.TRUE)
        assert_equal(array[4].getType(), LeptJson.NodeType.NUMBER)
        assert_equal(array[4].getNumber(), 123)
        assert_equal(array[5].getType(), LeptJson.NodeType.STRING)
        assert_equal(array[5].getString(), "abc")
    end)


    it("should parse nested array correctly", function()
        local result = LeptJson.Parse("[ [ ] , [ 0 ] , [ 0 , 1 ] , [ 0 , 1 , 2 ] ]")
        local value, state = result.value, result.state
        assert_equal(value.getType(), LeptJson.NodeType.ARRAY)
        assert_equal(state, LeptJson.ParseResult.PARSE_OK)
        assert_not_empty(value.getArray())

        local array = value.getArray()
        for i = 1, 4, 1 do
            assert_equal(array[i].getType(), LeptJson.NodeType.ARRAY)

            local subArray = array[i].getArray()
            assert_equal(#subArray, i - 1)
            for j = 1, i - 1, 1 do
                assert_equal(subArray[j].getType(), LeptJson.NodeType.NUMBER)
                assert_equal(subArray[j].getNumber(), j - 1)
            end
        end
    end)
end)
