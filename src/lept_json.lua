local NodeType = {
    NULL = 1, FALSE = 2, TRUE = 3, NUMBER = 4, STRING = 5, ARRAY = 6, OBJECT = 7
}

local ParseResult = {
    PARSE_OK                           = 0,
    PARSE_EXPECT_VALUE                 = 1,
    PARSE_INVALID_VALUE                = 2,
    PARSE_ROOT_NOT_SINGULAR            = 3,
    PARSE_NUMBER_TOO_BIG               = 4,
    PARSE_MISS_QUOTATION_MARK          = 5,
    PARSE_INVALID_STRING_ESCAPE        = 6,
    PARSE_INVALID_STRING_CHAR          = 7,
    PARSE_INVALID_UNICODE_HEX          = 8,
    PARSE_INVALID_UNICODE_SURROGATE    = 9,
    PARSE_MISS_COMMA_OR_SQUARE_BRACKET = 10,
    PARSE_MISS_KEY                     = 11,
    PARSE_MISS_COLON                   = 12,
    PARSE_MISS_COMMA_OR_CURLY_BRACKET  = 13
}


local function jsonValue()
    return {
        type = NodeType.NULL,
        value = nil
    }
end

local function jsonPair(k, v)
    return {
        key = k,
        value = v
    }
end
