local LeptJson = require "src.lept_json"

describe("JSON Parser for number", function()
    local TEST_ROUNDTRIP = function(source)
    end

    local TEST_STRINGIFY = function(src, dst)

    end

    before(function()
        TEST_ROUNDTRIP = function(source)
            local result = LeptJson.Parse(source)
            local value, state = result.value, result.state
            assert_equal(state, LeptJson.ParseResult.PARSE_OK)
            local stringified = LeptJson.Stringify(value)
            assert_equal(stringified, source)
        end

        TEST_STRINGIFY = function(src, dst)
            local result = LeptJson.Parse(src)
            local value, state = result.value, result.state
            assert_equal(state, LeptJson.ParseResult.PARSE_OK)
            local stringified = LeptJson.Stringify(value)
            assert_equal(stringified, dst)
        end
    end)

    it("should Stringify LITERAL value correctly", function()
        TEST_ROUNDTRIP("null");
        TEST_ROUNDTRIP("false");
        TEST_ROUNDTRIP("true");
    end)

    it("should Stringify NUMBER value correctly", function()
        TEST_ROUNDTRIP("0");
        TEST_STRINGIFY("-0", "0");
        TEST_ROUNDTRIP("1");
        TEST_ROUNDTRIP("-1");
        TEST_ROUNDTRIP("1.5");
        TEST_ROUNDTRIP("-1.5");
        TEST_ROUNDTRIP("3.25");
        TEST_STRINGIFY("1e+020", "1e+20");
        TEST_STRINGIFY("1.234e+020", "1.234e+20");
        TEST_STRINGIFY("1.234e-020", "1.234e-20");

        TEST_ROUNDTRIP("1.0000000000000002");      --  the smallest number > 1
        TEST_ROUNDTRIP("4.9406564584124654e-324"); --  minimum denormal
        TEST_ROUNDTRIP("-4.9406564584124654e-324");
        TEST_ROUNDTRIP("2.2250738585072009e-308"); --  Max subnormal double
        TEST_ROUNDTRIP("-2.2250738585072009e-308");
        TEST_ROUNDTRIP("2.2250738585072014e-308"); --  Min normal positive double
        TEST_ROUNDTRIP("-2.2250738585072014e-308");
        TEST_ROUNDTRIP("1.7976931348623157e+308"); --  Max double
        TEST_ROUNDTRIP("-1.7976931348623157e+308");
    end)

    it("should Stringify STRING value correctly", function()
        TEST_ROUNDTRIP("\"\"");
        TEST_ROUNDTRIP("\"Hello\"");
        TEST_STRINGIFY("\"Hello\\nWorld\"", "\"Hello\\\nWorld\"");
        TEST_STRINGIFY("\"\\\" \\\\ / \\b \\f \\n \\r \\t\"", "\"\\\" \\\\ / \\\b \\\f \\\n \\\r \\\t\"");
        TEST_ROUNDTRIP("\"Hello\\u0000World\"");
    end)

    it("should Stringify ARRAY value correctly", function()
        TEST_ROUNDTRIP("[]");
        TEST_ROUNDTRIP("[null,false,true,123,\"abc\",[1,2,3]]");
    end)

    it("should Stringify OBJECT value correctly", function()
        TEST_ROUNDTRIP("{}");
        TEST_STRINGIFY(
            "{\"n\":null,\"f\":false,\"t\":true,\"i\":123,\"s\":\"abc\",\"a\":[1,2,3],\"o\":{\"1\":1,\"2\":2,\"3\":3}}",
            [[{a:[1,2,3],f:false,i:123,n:null,o:{1:1,2:2,3:3},s:"abc",t:true}]]);
    end)
end)
