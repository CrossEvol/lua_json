local LeptJson = require "src.lept_json"

describe("JSON Parser for string", function()
    it("should parse string value correctly", function()
        local TEST_STRING = function(expect, json)
            local result = LeptJson.Parse(json)
            local value, state = result.value, result.state
            assert_equal(value.getType(), LeptJson.NodeType.STRING)
            assert_equal(state, LeptJson.ParseResult.PARSE_OK)
            assert_equal(expect, value.getString())
        end

        TEST_STRING("", "\"\"")
        TEST_STRING("Hello", "\"Hello\"")
        TEST_STRING("Hello\nWorld", "\"Hello\\nWorld\"")
        TEST_STRING("\" \\ / \b \f \n \r \t", "\"\\\" \\\\ \\/ \\b \\f \\n \\r \\t\"")
        TEST_STRING("Hello\0World", "\"Hello\\u0000World\"")
        TEST_STRING("\x24", "\"\\u0024\"")                    -- Dollar sign U+0024
        TEST_STRING("\xC2\xA2", "\"\\u00A2\"")                -- Cents sign U+00A2
        TEST_STRING("\xE2\x82\xAC", "\"\\u20AC\"")            --  Euro sign U+20AC
        TEST_STRING("\xF0\x9D\x84\x9E", "\"\\uD834\\uDD1E\"") --  G clef sign U+1D11E
        TEST_STRING("\xF0\x9D\x84\x9E", "\"\\ud834\\udd1e\"") --  G clef sign U+1D11E
    end)
end)
