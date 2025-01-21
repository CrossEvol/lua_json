local LeptJson = require "src.lept_json"

describe("JSON Parser for number", function()
    it("should parse number value correctly", function()
        local TEST_NUMBER = function(expect, json)
            local result = LeptJson.Parse(json)
            local value, state = result.value, result.state
            assert_equal(value.getType(), LeptJson.NodeType.NUMBER)
            assert_equal(state, LeptJson.ParseResult.PARSE_OK)
            assert_equal(expect, value.getNumber())
        end

        TEST_NUMBER(0, "0");
        TEST_NUMBER(0, "-0");
        TEST_NUMBER(0, "-0.0");
        TEST_NUMBER(1, "1");
        TEST_NUMBER(-1, "-1");
        TEST_NUMBER(1.5, "1.5");
        TEST_NUMBER(-1.5, "-1.5");
        TEST_NUMBER(3.1416, "3.1416");
        TEST_NUMBER(1E10, "1E10");
        TEST_NUMBER(1e10, "1e10");
        TEST_NUMBER(1E+10, "1E+10");
        TEST_NUMBER(1E-10, "1E-10");
        TEST_NUMBER(-1E10, "-1E10");
        TEST_NUMBER(-1e10, "-1e10");
        TEST_NUMBER(-1E+10, "-1E+10");
        TEST_NUMBER(-1E-10, "-1E-10");
        TEST_NUMBER(1.234E+10, "1.234E+10");
        TEST_NUMBER(1.234E-10, "1.234E-10");
        TEST_NUMBER(0.0, "1e-10000");                                    -- must underflow

        TEST_NUMBER(1.0000000000000002, "1.0000000000000002");           --  the smallest number > 1
        TEST_NUMBER(4.940656458412465e-324, "4.9406564584124654e-324");  -- minimum denormal
        TEST_NUMBER(-4.940656458412465e-324, "-4.9406564584124654e-324");
        TEST_NUMBER(2.225073858507201e-308, "2.2250738585072009e-308");  -- Max subnormal double
        TEST_NUMBER(-2.225073858507201e-308, "-2.2250738585072009e-308");
        TEST_NUMBER(2.2250738585072014e-308, "2.2250738585072014e-308"); -- Min normal positive double
        TEST_NUMBER(-2.2250738585072014e-308, "-2.2250738585072014e-308");
        TEST_NUMBER(1.7976931348623157e+308, "1.7976931348623157e+308"); -- Max double
        TEST_NUMBER(-1.7976931348623157e+308, "-1.7976931348623157e+308");
    end)
end)
