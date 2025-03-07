local LeptJson = require "src.lept_json"

describe("JSON Parser for object", function()
    it("should parse empty object correctly", function()
        local result = LeptJson.Parse(" { } ")
        local value, state = result.value, result.state
        assert_equal(value:getType(), LeptJson.NodeType.OBJECT)
        assert_equal(state, LeptJson.ParseResult.PARSE_OK)
        assert_empty(value:getObject())
    end)

    it("should parse object correctly", function()
        local jsonString = [[
            {
                "n": null,
                "f": false,
                "t": true,
                "i": 123,
                "s": "abc",
                "a": [1, 2, 3],
                "o": {
                    "1": 1,
                    "2": 2,
                    "3": 3
                }
            }
            ]]

        local result = LeptJson.Parse(jsonString)
        local value, state = result.value, result.state
        assert_equal(value:getType(), LeptJson.NodeType.OBJECT)
        assert_equal(state, LeptJson.ParseResult.PARSE_OK)
        assert_not_empty(value:getObject())

        local object = value:getObject()
        assert_equal(object['n']:getType(), LeptJson.NodeType.NULL)
        assert_equal(object['f']:getType(), LeptJson.NodeType.FALSE)
        assert_equal(object['t']:getType(), LeptJson.NodeType.TRUE)
        assert_equal(object['i']:getType(), LeptJson.NodeType.NUMBER)
        assert_equal(object['i']:getNumber(), 123)
        assert_equal(object['s']:getType(), LeptJson.NodeType.STRING)
        assert_equal(object['s']:getString(), "abc")
        assert_equal(object['a']:getType(), LeptJson.NodeType.ARRAY)
        local array = object['a']:getArray()
        for i = 1, 3, 1 do
            assert_equal(array[i]:getType(), LeptJson.NodeType.NUMBER)
            assert_equal(array[i]:getNumber(), i)
        end
        assert_equal(object['o']:getType(), LeptJson.NodeType.OBJECT)
        local subObject = object['o']:getObject()
        for i = 1, 3, 1 do
            assert_equal(subObject[tostring(i)]:getType(), LeptJson.NodeType.NUMBER)
            assert_equal(subObject[tostring(i)]:getNumber(), i)
        end
    end)
end)
