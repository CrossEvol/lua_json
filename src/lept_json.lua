local NodeType = {
    NULL = "NULL",
    FALSE = "FALSE",
    TRUE = "TRUE",
    NUMBER = "NUMBER",
    STRING = "STRING",
    ARRAY = "ARRAY",
    OBJECT =
    "OBJECT"
}

local ErrorCodes = {
    OutOfRange = 101
}

local ParseResult = {
    PARSE_OK                           = "PARSE_OK",
    PARSE_EXPECT_VALUE                 = "PARSE_EXPECT_VALUE",
    PARSE_INVALID_VALUE                = "PARSE_INVALID_VALUE",
    PARSE_ROOT_NOT_SINGULAR            = "PARSE_ROOT_NOT_SINGULAR",
    PARSE_NUMBER_TOO_BIG               = "PARSE_NUMBER_TOO_BIG",
    PARSE_MISS_QUOTATION_MARK          = "PARSE_MISS_QUOTATION_MARK",
    PARSE_INVALID_STRING_ESCAPE        = "PARSE_INVALID_STRING_ESCAPE",
    PARSE_INVALID_STRING_CHAR          = "PARSE_INVALID_STRING_CHAR",
    PARSE_INVALID_UNICODE_HEX          = "PARSE_INVALID_UNICODE_HEX",
    PARSE_INVALID_UNICODE_SURROGATE    = "PARSE_INVALID_UNICODE_SURROGATE",
    PARSE_MISS_COMMA_OR_SQUARE_BRACKET = "PARSE_MISS_COMMA_OR_SQUARE_BRACKET",
    PARSE_MISS_KEY                     = "PARSE_MISS_KEY",
    PARSE_MISS_COLON                   = "PARSE_MISS_COLON",
    PARSE_MISS_COMMA_OR_CURLY_BRACKET  = "PARSE_MISS_COMMA_OR_CURLY_BRACKET"
}


local function jsonValue()
    -- Private attributes
    local _type = NodeType.NULL
    local _value = nil

    -- Public methods
    local self = {}

    local function setType(type)
        _type = type
    end

    local function getType()
        return _type
    end

    local function getBoolean()
        assert(_type == NodeType.TRUE or _type == NodeType.FALSE, "Invalid type for boolean")
        return _type == NodeType.TRUE
    end

    local function setBoolean(b)
        _type = b and NodeType.TRUE or NodeType.FALSE
    end

    local function getNumber()
        assert(_type == NodeType.NUMBER, "Invalid type for number")
        return _value
    end

    local function setNumber(num)
        _type = NodeType.NUMBER
        _value = num
    end

    local function getString()
        assert(_type == NodeType.STRING, "Invalid type for string")
        return _value
    end

    local function setString(str)
        _type = NodeType.STRING
        _value = str
    end

    -- Add methods to the self table
    self.setType = setType
    self.getType = getType
    self.getBoolean = getBoolean
    self.setBoolean = setBoolean
    self.getNumber = getNumber
    self.setNumber = setNumber
    self.getString = getString
    self.setString = setString

    return self
end

local function jsonPair(k, v)
    return {
        key = k,
        value = v
    }
end

function Parse(jsonStr)
    local ctx = NewContext(jsonStr)
    ctx.parseWhitespace()
    local v = ctx.parseValue()
    if ctx.getState() == ParseResult.PARSE_OK then
        ctx.parseWhitespace()
        if not ctx.terminative() then
            v.setType(NodeType.NULL)
            ctx.setState(ParseResult.PARSE_ROOT_NOT_SINGULAR)
        end
    end
    assert(ctx.isEmpty())
    return {
        value = v,
        state = ctx.getState(),
    }
end

function Stringify(jsonValue)
    return ""
end

function NewContext(jsonStr)
    -- Private attributes
    local context = {
        json = jsonStr,
        index = 1,
        stack = {},
        size = 1,
        top = 1,
        state = ParseResult.PARSE_OK,
    }

    -- Private methods
    local function currentChar()
        if context.index > string.len(context.json) + 1 then
            error({ code = ErrorCodes.OutOfRange })
        end
        local i = context.index
        local ch = context.json:sub(i, i)
        return ch
    end

    local function setState(newState)
        context.state = newState
    end

    local function getState()
        return context.state
    end

    local function terminative()
        return string.len(context.json) + 1 == context.index
    end

    local function isEmpty()
        return context.top == 1
    end

    local function expect(ch)
        local i = context.index
        assert(context.json:sub(i, i) == ch)
        context.index = i + 1
    end

    local function isDigit(ch)
        return ch >= '0' and ch <= '9'
    end

    local function isDigit1To9(ch)
        return ch >= '1' and ch <= '9'
    end

    local function parseWhitespace()
        local ch = currentChar()
        while ch == ' ' or ch == '\t' or ch == '\n' or ch == '\r' do
            context.index = context.index + 1
            ch = currentChar()
        end
    end

    local function parseLiteral(literal, type)
        expect(literal:sub(1, 1))

        -- Check remaining characters
        for i = 1, #literal do
            if context.json:sub(context.index + i - 1, context.index + i - 1) ~= literal:sub(i + 1, i + 1) then
                context.state = ParseResult.PARSE_INVALID_VALUE
                error(ParseResult.PARSE_INVALID_VALUE)
            end
        end

        context.index = context.index + #literal - 1

        local v = jsonValue()
        v.setType(type)

        return v
    end

    local function parseNumber()
        -- TODO: Implement number parsing
        local v = jsonValue()
        v.setType(NodeType.NUMBER)

        return v
    end

    local function parseString()
        -- TODO: Implement string parsing
        local v = jsonValue()
        v.setType(NodeType.STRING)

        return v
    end

    local function parseArray()
        -- TODO: Implement array parsing
        local v = jsonValue()
        v.setType(NodeType.ARRAY)

        return v
    end

    local function parseObject()
        -- TODO: Implement object parsing
        local v = jsonValue()
        v.setType(NodeType.OBJECT)

        return v
    end

    local function push(byte)
        -- TODO: Implement stack push
    end

    local function pop()
        -- TODO: Implement stack pop
    end

    local function parseValue()
        local current_char = currentChar()

        if current_char == 't' then
            return parseLiteral("true", NodeType.TRUE)
        elseif current_char == 'f' then
            return parseLiteral("false", NodeType.FALSE)
        elseif current_char == 'n' then
            return parseLiteral("null", NodeType.NULL)
        elseif current_char == '"' then
            return parseString()
        elseif current_char == '[' then
            return parseArray()
        elseif current_char == '{' then
            return parseObject()
        elseif current_char == '' then
            return ParseResult.PARSE_EXPECT_VALUE
        else
            return parseNumber()
        end
    end

    -- Public interface
    local self = {}
    self.setState = setState
    self.getState = getState
    self.parseWhitespace = parseWhitespace
    self.parseValue = parseValue
    self.terminative = terminative
    self.isEmpty = isEmpty
    self.push = push
    self.pop = pop

    return self
end

return {
    Parse = Parse,
    ParseResult = ParseResult,
    NodeType = NodeType
}
