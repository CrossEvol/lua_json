local NodeType = {
    NULL = "NULL",
    FALSE = "FALSE",
    TRUE = "TRUE",
    NUMBER = "NUMBER",
    STRING = "STRING",
    ARRAY = "ARRAY",
    OBJECT = "OBJECT",
}

-- as a state machine for parse number
local NumberState = {
    BEGIN        = 0x1,
    NEGATIVE     = 0x2,
    ZERO         = 0x3,
    DIGIT        = 0x4,
    DIGIT_1_TO_9 = 0x5,
    DOT          = 0x6,
    EXPONENT     = 0x7,
    SYMBOL       = 0x8,
    END          = 0x9,
};

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
    ctx.skipWhitespace()
    local v = ctx.parseValue()
    if ctx.getState() == ParseResult.PARSE_OK then
        ctx.skipWhitespace()
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
        state = ParseResult.PARSE_OK,
    }

    -- @raise OutOfRange when index over length of jsonString
    local function currentChar()
        if context.index > string.len(context.json) + 1 then
            error({ code = ErrorCodes.OutOfRange })
        end
        local i = context.index
        local ch = context.json:sub(i, i)
        return ch
    end

    -- consume()  -- without incremental for stack and move to next position,
    local function forward()
        context.index = context.index + 1
    end

    -- consume()  -- put the current char to the stack and move to next position
    local function consume()
        context.stack[#context.stack + 1] = currentChar()
        context.index                     = context.index + 1
    end

    -- add the char to the tail of stack
    local function push(ch)
        context.stack[#context.stack + 1] = ch
    end

    -- retrieve the char from the top of the stack
    local function pop()
        local ch = context.stack[#context.stack]
        context.stack[#context.stack] = nil
        return ch
    end

    local function resetStack()
        context.stack = {}
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
        return #context.stack == 0
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

    local function skipWhitespace()
        local ch = currentChar()
        while ch == ' ' or ch == '\t' or ch == '\n' or ch == '\r' do
            forward()
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
        local state = NumberState.BEGIN
        local hasDot = false
        local hasExponent = false
        while true do
            if state == NumberState.BEGIN then
                if currentChar() == '-' then
                    state = NumberState.NEGATIVE
                elseif currentChar() == '0' then
                    state = NumberState.ZERO
                elseif isDigit1To9(currentChar()) then
                    state = NumberState.DIGIT_1_TO_9
                else
                    setState(ParseResult.PARSE_INVALID_VALUE)
                    error(ParseResult.PARSE_INVALID_VALUE)
                end
                consume()
            elseif state == NumberState.NEGATIVE then
                if currentChar() == '0' then
                    state = NumberState.ZERO
                elseif isDigit1To9(currentChar()) then
                    state = NumberState.DIGIT_1_TO_9
                else
                    setState(ParseResult.PARSE_INVALID_VALUE)
                    error(ParseResult.PARSE_INVALID_VALUE)
                end
                consume()
            elseif state == NumberState.ZERO then
                if currentChar() == 'e' or currentChar() == 'E' then
                    if hasExponent then
                        setState(ParseResult.PARSE_INVALID_VALUE)
                        error(ParseResult.PARSE_INVALID_VALUE)
                    end
                    state = NumberState.EXPONENT
                    consume()
                elseif currentChar() == '.' then
                    if hasDot then
                        setState(ParseResult.PARSE_INVALID_VALUE)
                        error(ParseResult.PARSE_INVALID_VALUE)
                    end
                    state = NumberState.DOT
                    consume()
                else
                    state = NumberState.END -- when end , can not forward
                end
            elseif state == NumberState.DIGIT_1_TO_9 then
                if currentChar() == 'e' or currentChar() == 'E' then
                    if hasExponent then
                        setState(ParseResult.PARSE_INVALID_VALUE)
                        error(ParseResult.PARSE_INVALID_VALUE)
                    end
                    state = NumberState.EXPONENT
                    consume()
                elseif currentChar() == '.' then
                    if hasDot then
                        setState(ParseResult.PARSE_INVALID_VALUE)
                        error(ParseResult.PARSE_INVALID_VALUE)
                    end
                    state = NumberState.DOT
                    consume()
                elseif isDigit(currentChar()) then
                    state = NumberState.DIGIT
                    consume()
                else
                    state = NumberState.END -- when end , can not forward
                end
            elseif state == NumberState.DOT then
                hasDot = true
                if isDigit(currentChar()) then
                    state = NumberState.DIGIT
                else
                    setState(ParseResult.PARSE_INVALID_VALUE)
                    error(ParseResult.PARSE_INVALID_VALUE)
                end
                consume()
            elseif state == NumberState.DIGIT then
                while isDigit(currentChar()) do
                    consume()
                end
                if currentChar() == 'e' or currentChar() == 'E' then
                    if hasExponent then
                        setState(ParseResult.PARSE_INVALID_VALUE)
                        error(ParseResult.PARSE_INVALID_VALUE)
                    end
                    state = NumberState.EXPONENT
                    consume()
                elseif currentChar() == '.' then
                    if hasDot then
                        setState(ParseResult.PARSE_INVALID_VALUE)
                        error(ParseResult.PARSE_INVALID_VALUE)
                    end
                    state = NumberState.DOT
                    consume()
                else
                    state = NumberState.END -- when end , can not forward
                end
            elseif state == NumberState.EXPONENT then
                hasExponent = true
                if currentChar() == '+' or currentChar() == '-' then
                    state = NumberState.SYMBOL
                elseif isDigit(currentChar()) then
                    state = NumberState.DIGIT
                else
                    setState(ParseResult.PARSE_INVALID_VALUE)
                    error(ParseResult.PARSE_INVALID_VALUE)
                end
                consume()
            elseif state == NumberState.SYMBOL then
                if isDigit(currentChar()) then
                    state = NumberState.DIGIT
                else
                    setState(ParseResult.PARSE_INVALID_VALUE)
                    error(ParseResult.PARSE_INVALID_VALUE)
                end
                consume()
            elseif state == NumberState.END then
                local numberString = table.concat(context.stack)

                -- Check if it's an integer (no decimal point or scientific notation)
                local isInteger = not string.find(numberString, "[%.eE]")

                if isInteger then
                    -- For integers, check string length first to prevent overflow
                    local isNegative = numberString:sub(1, 1) == "-"
                    local digitString = isNegative and numberString:sub(2) or numberString

                    -- Check if the integer has too many digits
                    -- 2^53 is 16 digits long, so we can use this as a quick check
                    if #digitString > 16 then
                        setState(ParseResult.PARSE_NUMBER_TOO_BIG)
                        error(ParseResult.PARSE_NUMBER_TOO_BIG)
                    end

                    -- For numbers that might be close to the limit, check the actual value
                    if #digitString == 16 then
                        local MAX_SAFE_INTEGER_STR = "9007199254740991"

                        -- Compare string lengths first
                        if #digitString > #MAX_SAFE_INTEGER_STR then
                            setState(ParseResult.PARSE_NUMBER_TOO_BIG)
                            error(ParseResult.PARSE_NUMBER_TOO_BIG)
                        end

                        -- If same length, compare digit by digit
                        if #digitString == #MAX_SAFE_INTEGER_STR then
                            if isNegative then
                                -- For negative numbers, we can use the same comparison
                                -- as -9007199254740991 is the lower limit
                                if digitString > MAX_SAFE_INTEGER_STR then
                                    setState(ParseResult.PARSE_NUMBER_TOO_BIG)
                                    error(ParseResult.PARSE_NUMBER_TOO_BIG)
                                end
                            else
                                if digitString > MAX_SAFE_INTEGER_STR then
                                    setState(ParseResult.PARSE_NUMBER_TOO_BIG)
                                    error(ParseResult.PARSE_NUMBER_TOO_BIG)
                                end
                            end
                        end
                    end
                end

                -- Now safe to convert to number
                local numberValue = tonumber(numberString)
                if not numberValue then
                    setState(ParseResult.PARSE_INVALID_VALUE)
                    error(ParseResult.PARSE_INVALID_VALUE)
                end

                -- Handle floating point numbers
                if not isInteger then
                    if string.find(numberString, "[eE]") then
                        -- Handle scientific notation
                        local _, _, base, exp = string.find(numberString, "([%-%.%d]+)[eE]([%-+]?%d+)")
                        if base and exp then
                            exp = tonumber(exp)
                            if exp and exp > 308 then
                                setState(ParseResult.PARSE_NUMBER_TOO_BIG)
                                error(ParseResult.PARSE_NUMBER_TOO_BIG)
                            end
                        end
                    else
                        -- Handle regular floating point numbers
                        local absValue = math.abs(numberValue)
                        if absValue > 1.79769313486231570e+308 then
                            setState(ParseResult.PARSE_NUMBER_TOO_BIG)
                            error(ParseResult.PARSE_NUMBER_TOO_BIG)
                        end
                    end
                end

                local v = jsonValue()
                v.setType(NodeType.NUMBER)
                v.setNumber(numberValue)
                resetStack() -- if get valid value, should clear the stack

                return v
            else
                setState(ParseResult.PARSE_INVALID_VALUE)
                error(ParseResult.PARSE_INVALID_VALUE)
            end
        end
    end

    local function parseHex4()
        local u = 0
        for _ = 1, 4, 1 do
            local ch = currentChar()
            u        = u << 4
            if ch >= '0' and ch <= '9' then
                u = u | (string.byte(ch) - string.byte('0'))
            elseif ch >= 'A' and ch <= 'F' then
                u = u | (string.byte(ch) - (string.byte('A') - 10))
            elseif ch >= 'a' and ch <= 'f' then
                u = u | (string.byte(ch) - (string.byte('a') - 10))
            else
                error(ParseResult.PARSE_INVALID_UNICODE_HEX)
            end
            forward()
        end
        return u
    end

    local function encodeUTF8(u)
        if u <= 0x7F then
            -- 1-byte sequence
            push(string.char(u & 0xFF))
        elseif u <= 0x7FF then
            -- 2-byte sequence
            push(string.char(0xC0 | ((u >> 6) & 0xFF)))
            push(string.char(0x80 | (u & 0x3F)))
        elseif u <= 0xFFFF then
            -- 3-byte sequence
            push(string.char(0xE0 | ((u >> 12) & 0xFF)))
            push(string.char(0x80 | ((u >> 6) & 0x3F)))
            push(string.char(0x80 | (u & 0x3F)))
        elseif u <= 0x10FFFF then
            -- 4-byte sequence
            push(string.char(0xF0 | ((u >> 18) & 0xFF)))
            push(string.char(0x80 | ((u >> 12) & 0x3F)))
            push(string.char(0x80 | ((u >> 6) & 0x3F)))
            push(string.char(0x80 | (u & 0x3F)))
        else
            setState(ParseResult.PARSE_INVALID_UNICODE_HEX)
            error(ParseResult.PARSE_INVALID_UNICODE_HEX)
        end
    end


    local function parseUnicodeChars()
        local u1 = parseHex4()
        if u1 > 0xD800 and u1 < 0xDBFF then
            if terminative() or currentChar() ~= '\\' then
                setState(ParseResult.PARSE_INVALID_UNICODE_SURROGATE)
                error(ParseResult.PARSE_INVALID_UNICODE_SURROGATE)
            end
            forward()
            if terminative() or currentChar() ~= 'u' then
                setState(ParseResult.PARSE_INVALID_UNICODE_SURROGATE)
                error(ParseResult.PARSE_INVALID_UNICODE_SURROGATE)
            end
            forward()

            local u2 = parseHex4()
            if u2 < 0xDC00 or u2 > 0xDFFF then
                setState(ParseResult.PARSE_INVALID_UNICODE_SURROGATE)
                error(ParseResult.PARSE_INVALID_UNICODE_SURROGATE)
            end

            local u = (((u1 - 0xD800) << 10) | (u2 - 0xDC00)) + 0x10000
            return encodeUTF8(u)
        else
            return encodeUTF8(u1)
        end
    end

    local function parseString()
        expect('"')

        while true do
            local ch = currentChar()
            if ch == '"' then
                forward()
                local v = jsonValue()
                v.setType(NodeType.STRING)
                v.setString(table.concat(context.stack))
                resetStack()

                return v
            elseif ch == '\\' then
                forward()
                ch = currentChar()
                if ch == '"' then
                    consume()
                elseif ch == '\\' then
                    consume()
                elseif ch == '/' then
                    consume()
                elseif ch == 'b' then
                    push('\b')
                    forward()
                elseif ch == 'f' then
                    push('\f')
                    forward()
                elseif ch == 'n' then
                    push('\n')
                    forward()
                elseif ch == 'r' then
                    push('\r')
                    forward()
                elseif ch == 't' then
                    push('\t')
                    forward()
                elseif ch == 'u' then
                    forward()
                    parseUnicodeChars()
                else
                    setState(ParseResult.PARSE_INVALID_STRING_ESCAPE)
                    error(ParseResult.PARSE_INVALID_STRING_ESCAPE)
                end
            else
                if string.byte(ch) < 0x20 then
                    setState(ParseResult.PARSE_INVALID_STRING_CHAR)
                    error(ParseResult.PARSE_INVALID_STRING_CHAR)
                end
                consume()
            end
        end
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
    self.skipWhitespace = skipWhitespace
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
