---@class NodeType
local NodeType = {
    NULL = "NULL",
    FALSE = "FALSE",
    TRUE = "TRUE",
    NUMBER = "NUMBER",
    STRING = "STRING",
    ARRAY = "ARRAY",
    OBJECT = "OBJECT",
}

---@alias NodeType.Type
---| '"NULL"'
---| '"FALSE"'
---| '"TRUE"'
---| '"NUMBER"'
---| '"STRING"'
---| '"ARRAY"'
---| '"OBJECT"'

---@class NumberState
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

---@alias NumberState.Type
---| '0x1' # BEGIN
---| '0x2' # NEGATIVE
---| '0x3' # ZERO
---| '0x4' # DIGIT
---| '0x5' # DIGIT_1_TO_9
---| '0x6' # DOT
---| '0x7' # EXPONENT
---| '0x8' # SYMBOL
---| '0x9' # END

---@type string[]
local HexDigits = {
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'
}

---@class ErrorCodes
local ErrorCodes = {
    OutOfRange = 101
}

---@alias ErrorCodes.Type
---| '101' # OutOfRange

---@class ParseResult
local ParseResult = {
    PARSE_OK                           = "PARSE_OK",
    PARSE_EXPECT_VALUE                 = "PARSE_EXPECT_VALUE",
    PARSE_INVALID_TYPE                 = "PARSE_INVALID_TYPE",
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

---@alias ParseResult.Type
---| '"PARSE_OK"'
---| '"PARSE_EXPECT_VALUE"'
---| '"PARSE_INVALID_TYPE"'
---| '"PARSE_INVALID_VALUE"'
---| '"PARSE_ROOT_NOT_SINGULAR"'
---| '"PARSE_NUMBER_TOO_BIG"'
---| '"PARSE_MISS_QUOTATION_MARK"'
---| '"PARSE_INVALID_STRING_ESCAPE"'
---| '"PARSE_INVALID_STRING_CHAR"'
---| '"PARSE_INVALID_UNICODE_HEX"'
---| '"PARSE_INVALID_UNICODE_SURROGATE"'
---| '"PARSE_MISS_COMMA_OR_SQUARE_BRACKET"'
---| '"PARSE_MISS_KEY"'
---| '"PARSE_MISS_COLON"'
---| '"PARSE_MISS_COMMA_OR_CURLY_BRACKET"'

---@class JsonValue
---@field _type string Type of the JSON value (from NodeType)
---@field _value any The actual value stored
local JsonValue = {
    _type = NodeType.NULL,
    _value = nil
}

---@param o? table
---@return JsonValue
function JsonValue:new(o)
    local o = o or {}
    self.__index = self
    setmetatable(o, self)
    return o
end

---@param type string
function JsonValue:setType(type)
    self._type = type
end

---@return string
function JsonValue:getType()
    return self._type
end

---@return boolean
function JsonValue:getBoolean()
    assert(self._type == NodeType.TRUE or self._type == NodeType.FALSE, "Invalid type for boolean")
    return self._type == NodeType.TRUE
end

---@param b boolean
function JsonValue:setBoolean(b)
    self._type = b and NodeType.TRUE or NodeType.FALSE
end

---@return number
function JsonValue:getNumber()
    assert(self._type == NodeType.NUMBER, "Invalid type for number")
    return self._value
end

---@param num number
function JsonValue:setNumber(num)
    self._type = NodeType.NUMBER
    self._value = num
end

---@return string
function JsonValue:getString()
    assert(self._type == NodeType.STRING, "Invalid type for string")
    return self._value
end

---@param str string
function JsonValue:setString(str)
    self._type = NodeType.STRING
    self._value = str
end

---@return JsonValue[]
function JsonValue:getArray()
    assert(self._type == NodeType.ARRAY, "Invalid type for array")
    return self._value
end

---@param arr JsonValue[]
function JsonValue:setArray(arr)
    self._type = NodeType.ARRAY
    self._value = arr
end

---@return table<string, JsonValue>
function JsonValue:getObject()
    assert(self._type == NodeType.OBJECT, "Invalid type for object")
    return self._value
end

---@param object table<string, JsonValue>
function JsonValue:setObject(object)
    self._type = NodeType.OBJECT
    self._value = object
end

---@class DecodeContext
---@field json string The JSON string to parse
---@field index number Current index in the JSON string
---@field stack string[] Stack for building values
---@field state string Current parse state
local DecodeContext = {
    json = "",
    index = 1,
    stack = {},
    state = ParseResult.PARSE_OK
}

---@param jsonStr string
---@return DecodeContext
function DecodeContext:new(jsonStr)
    local o = {
        json = jsonStr,
        index = 1,
        stack = {},
        state = ParseResult.PARSE_OK
    }
    self.__index = self
    setmetatable(o, self)
    return o
end

function DecodeContext:resetStack()
    self.stack = {}
end

---@param err string Error from ParseResult
---@error {message: string} Throws an error with the given message
function DecodeContext:Raise(err)
    self.state = err
    self:resetStack()
    error({
        message = err
    })
end

---@return string
---@error {code: number} Throws an error if index is out of range
function DecodeContext:currentChar()
    if self.index > string.len(self.json) + 1 then
        error({ code = ErrorCodes.OutOfRange })
    end
    local i = self.index
    local ch = self.json:sub(i, i)
    return ch
end

-- consume()  -- without incremental for stack and move to next position,
function DecodeContext:forward()
    self.index = self.index + 1
end

-- consume()  -- put the current char to the stack and move to next position
function DecodeContext:consume()
    self.stack[#self.stack + 1] = self:currentChar()
    self.index = self.index + 1
end

---@param ch string
function DecodeContext:push(ch)
    self.stack[#self.stack + 1] = ch
end

---@return string
function DecodeContext:pop()
    local ch = self.stack[#self.stack]
    self.stack[#self.stack] = nil
    return ch
end

---@param newState string
function DecodeContext:setState(newState)
    self.state = newState
end

---@return string
function DecodeContext:getState()
    return self.state
end

---@return boolean
function DecodeContext:terminative()
    return string.len(self.json) + 1 == self.index
end

---@return boolean
function DecodeContext:isEmpty()
    return #self.stack == 0
end

---@param ch string Expected character
function DecodeContext:expect(ch)
    local i = self.index
    assert(self.json:sub(i, i) == ch)
    self.index = i + 1
end

---@param ch string
---@return boolean
function DecodeContext:isDigit(ch)
    return ch >= '0' and ch <= '9'
end

---@param ch string
---@return boolean
function DecodeContext:isDigit1To9(ch)
    return ch >= '1' and ch <= '9'
end

function DecodeContext:skipWhitespace()
    local ch = self:currentChar()
    while ch == ' ' or ch == '\t' or ch == '\n' or ch == '\r' do
        self:forward()
        ch = self:currentChar()
    end
end

---@param literal string
---@param type string
---@return JsonValue
function DecodeContext:parseLiteral(literal, type)
    -- Check remaining characters
    for i = 1, #literal do
        if self.json:sub(self.index + i - 1, self.index + i - 1) ~= literal:sub(i, i) then
            self:Raise(ParseResult.PARSE_INVALID_VALUE)
        end
    end

    self.index = self.index + #literal

    local v = JsonValue:new()
    v:setType(type)

    return v
end

---@return JsonValue
function DecodeContext:parseNumber()
    local state = NumberState.BEGIN
    local hasDot = false
    local hasExponent = false
    while true do
        if state == NumberState.BEGIN then
            if self:currentChar() == '-' then
                state = NumberState.NEGATIVE
            elseif self:currentChar() == '0' then
                state = NumberState.ZERO
            elseif self:isDigit1To9(self:currentChar()) then
                state = NumberState.DIGIT_1_TO_9
            else
                self:Raise(ParseResult.PARSE_INVALID_VALUE)
            end
            self:consume()
        elseif state == NumberState.NEGATIVE then
            if self:currentChar() == '0' then
                state = NumberState.ZERO
            elseif self:isDigit1To9(self:currentChar()) then
                state = NumberState.DIGIT_1_TO_9
            else
                self:Raise(ParseResult.PARSE_INVALID_VALUE)
            end
            self:consume()
        elseif state == NumberState.ZERO then
            if self:currentChar() == 'e' or self:currentChar() == 'E' then
                if hasExponent then
                    self:Raise(ParseResult.PARSE_INVALID_VALUE)
                end
                state = NumberState.EXPONENT
                self:consume()
            elseif self:currentChar() == '.' then
                if hasDot then
                    self:Raise(ParseResult.PARSE_INVALID_VALUE)
                end
                state = NumberState.DOT
                self:consume()
            else
                state = NumberState.END -- when end , can not forward
            end
        elseif state == NumberState.DIGIT_1_TO_9 then
            if self:currentChar() == 'e' or self:currentChar() == 'E' then
                if hasExponent then
                    self:Raise(ParseResult.PARSE_INVALID_VALUE)
                end
                state = NumberState.EXPONENT
                self:consume()
            elseif self:currentChar() == '.' then
                if hasDot then
                    self:Raise(ParseResult.PARSE_INVALID_VALUE)
                end
                state = NumberState.DOT
                self:consume()
            elseif self:isDigit(self:currentChar()) then
                state = NumberState.DIGIT
                self:consume()
            else
                state = NumberState.END -- when end , can not forward
            end
        elseif state == NumberState.DOT then
            hasDot = true
            if self:isDigit(self:currentChar()) then
                state = NumberState.DIGIT
            else
                self:Raise(ParseResult.PARSE_INVALID_VALUE)
            end
            self:consume()
        elseif state == NumberState.DIGIT then
            while self:isDigit(self:currentChar()) do
                self:consume()
            end
            if self:currentChar() == 'e' or self:currentChar() == 'E' then
                if hasExponent then
                    self:Raise(ParseResult.PARSE_INVALID_VALUE)
                end
                state = NumberState.EXPONENT
                self:consume()
            elseif self:currentChar() == '.' then
                if hasDot then
                    self:Raise(ParseResult.PARSE_INVALID_VALUE)
                end
                state = NumberState.DOT
                self:consume()
            else
                state = NumberState.END -- when end , can not forward
            end
        elseif state == NumberState.EXPONENT then
            hasExponent = true
            if self:currentChar() == '+' or self:currentChar() == '-' then
                state = NumberState.SYMBOL
            elseif self:isDigit(self:currentChar()) then
                state = NumberState.DIGIT
            else
                self:Raise(ParseResult.PARSE_INVALID_VALUE)
            end
            self:consume()
        elseif state == NumberState.SYMBOL then
            if self:isDigit(self:currentChar()) then
                state = NumberState.DIGIT
            else
                self:Raise(ParseResult.PARSE_INVALID_VALUE)
            end
            self:consume()
        elseif state == NumberState.END then
            local numberString = table.concat(self.stack)

            -- Check if it's an integer (no decimal point or scientific notation)
            local isInteger = not string.find(numberString, "[%.eE]")

            if isInteger then
                -- For integers, check string length first to prevent overflow
                local isNegative = numberString:sub(1, 1) == "-"
                local digitString = isNegative and numberString:sub(2) or numberString

                -- Check if the integer has too many digits
                -- 2^53 is 16 digits long, so we can use this as a quick check
                if #digitString > 16 then
                    self:Raise(ParseResult.PARSE_NUMBER_TOO_BIG)
                end

                -- For numbers that might be close to the limit, check the actual value
                if #digitString == 16 then
                    local MAX_SAFE_INTEGER_STR = "9007199254740991"

                    -- Compare string lengths first
                    if #digitString > #MAX_SAFE_INTEGER_STR then
                        self:Raise(ParseResult.PARSE_NUMBER_TOO_BIG)
                    end

                    -- If same length, compare digit by digit
                    if #digitString == #MAX_SAFE_INTEGER_STR then
                        if isNegative then
                            -- For negative numbers, we can use the same comparison
                            -- as -9007199254740991 is the lower limit
                            if digitString > MAX_SAFE_INTEGER_STR then
                                self:Raise(ParseResult.PARSE_NUMBER_TOO_BIG)
                            end
                        else
                            if digitString > MAX_SAFE_INTEGER_STR then
                                self:Raise(ParseResult.PARSE_NUMBER_TOO_BIG)
                            end
                        end
                    end
                end
            end

            -- Now safe to convert to number
            local numberValue = tonumber(numberString)
            if not numberValue then
                self:Raise(ParseResult.PARSE_INVALID_VALUE)
            end
            ---@cast numberValue number

            -- Handle floating point numbers
            if not isInteger then
                if string.find(numberString, "[eE]") then
                    -- Handle scientific notation
                    local _, _, base, exp = string.find(numberString, "([%-%.%d]+)[eE]([%-+]?%d+)")
                    if base and exp then
                        exp = tonumber(exp)
                        if exp and exp > 308 then
                            self:Raise(ParseResult.PARSE_NUMBER_TOO_BIG)
                        end
                    end
                else
                    -- Handle regular floating point numbers
                    local absValue = math.abs(numberValue)
                    if absValue > 1.79769313486231570e+308 then
                        self:Raise(ParseResult.PARSE_NUMBER_TOO_BIG)
                    end
                end
            end

            local v = JsonValue:new()
            v:setType(NodeType.NUMBER)
            v:setNumber(numberValue)
            self:resetStack() -- if get valid value, should clear the stack

            return v
        else
            self:Raise(ParseResult.PARSE_INVALID_VALUE)
        end
    end
end

---@return number
function DecodeContext:parseHex4()
    local u = 0
    for _ = 1, 4, 1 do
        local ch = self:currentChar()
        u = u << 4
        if ch >= '0' and ch <= '9' then
            u = u | (string.byte(ch) - string.byte('0'))
        elseif ch >= 'A' and ch <= 'F' then
            u = u | (string.byte(ch) - (string.byte('A') - 10))
        elseif ch >= 'a' and ch <= 'f' then
            u = u | (string.byte(ch) - (string.byte('a') - 10))
        else
            self:Raise(ParseResult.PARSE_INVALID_UNICODE_HEX)
        end
        self:forward()
    end
    return u
end

---@param u number Unicode code point
function DecodeContext:encodeUTF8(u)
    if u <= 0x7F then
        -- 1-byte sequence
        self:push(string.char(u & 0xFF))
    elseif u <= 0x7FF then
        -- 2-byte sequence
        self:push(string.char(0xC0 | ((u >> 6) & 0xFF)))
        self:push(string.char(0x80 | (u & 0x3F)))
    elseif u <= 0xFFFF then
        -- 3-byte sequence
        self:push(string.char(0xE0 | ((u >> 12) & 0xFF)))
        self:push(string.char(0x80 | ((u >> 6) & 0x3F)))
        self:push(string.char(0x80 | (u & 0x3F)))
    elseif u <= 0x10FFFF then
        -- 4-byte sequence
        self:push(string.char(0xF0 | ((u >> 18) & 0xFF)))
        self:push(string.char(0x80 | ((u >> 12) & 0x3F)))
        self:push(string.char(0x80 | ((u >> 6) & 0x3F)))
        self:push(string.char(0x80 | (u & 0x3F)))
    else
        self:Raise(ParseResult.PARSE_INVALID_UNICODE_HEX)
    end
end

function DecodeContext:parseUnicodeChars()
    local u1 = self:parseHex4()
    if u1 >= 0xD800 and u1 <= 0xDBFF then
        if self:terminative() or self:currentChar() ~= '\\' then
            self:Raise(ParseResult.PARSE_INVALID_UNICODE_SURROGATE)
        end
        self:forward()
        if self:terminative() or self:currentChar() ~= 'u' then
            self:Raise(ParseResult.PARSE_INVALID_UNICODE_SURROGATE)
        end
        self:forward()

        local u2 = self:parseHex4()
        if u2 < 0xDC00 or u2 > 0xDFFF then
            self:Raise(ParseResult.PARSE_INVALID_UNICODE_SURROGATE)
        end

        local u = (((u1 - 0xD800) << 10) | (u2 - 0xDC00)) + 0x10000
        return self:encodeUTF8(u)
    else
        return self:encodeUTF8(u1)
    end
end

---@return JsonValue
function DecodeContext:parseString()
    self:expect('"')

    while true do
        local ch = self:currentChar()
        if ch == '"' then
            self:forward()
            local v = JsonValue:new()
            v:setType(NodeType.STRING)
            v:setString(table.concat(self.stack))
            self:resetStack()

            return v
        elseif ch == '\\' then
            self:forward()
            ch = self:currentChar()
            if ch == '"' then
                self:consume()
            elseif ch == '\\' then
                self:consume()
            elseif ch == '/' then
                self:consume()
            elseif ch == 'b' then
                self:push('\b')
                self:forward()
            elseif ch == 'f' then
                self:push('\f')
                self:forward()
            elseif ch == 'n' then
                self:push('\n')
                self:forward()
            elseif ch == 'r' then
                self:push('\r')
                self:forward()
            elseif ch == 't' then
                self:push('\t')
                self:forward()
            elseif ch == 'u' then
                self:forward()
                self:parseUnicodeChars()
            else
                self:Raise(ParseResult.PARSE_INVALID_STRING_ESCAPE)
            end
        elseif ch == '' then
            self:Raise(ParseResult.PARSE_MISS_QUOTATION_MARK)
        else
            if string.byte(ch) < 0x20 then
                self:Raise(ParseResult.PARSE_INVALID_STRING_CHAR)
            end
            self:consume()
        end
    end
end

---@return JsonValue
function DecodeContext:parseArray()
    self:expect('[')
    self:skipWhitespace()
    if self:currentChar() == ']' then
        self:forward()
        local v = JsonValue:new()
        v:setArray({})
        return v
    end
    local arr = {}
    while true do
        local success, result = pcall(function() return self:ParseValue() end)
        if success then
            arr[#arr + 1] = result
            self:skipWhitespace()
        else
            self:Raise(ParseResult.PARSE_INVALID_VALUE)
        end
        if self:currentChar() == ',' then
            self:forward()
            self:skipWhitespace()
        elseif self:currentChar() == ']' then
            self:forward()
            local v = JsonValue:new()
            v:setArray(arr)
            return v
        else
            self:Raise(ParseResult.PARSE_MISS_COMMA_OR_SQUARE_BRACKET)
        end
    end
end

---@return JsonValue
function DecodeContext:parseObject()
    if self:currentChar() ~= '{' then
        self:Raise(ParseResult.PARSE_MISS_COMMA_OR_CURLY_BRACKET)
    end
    self:forward()
    self:skipWhitespace()

    if self:currentChar() == '}' then
        self:forward()
        local v = JsonValue:new()
        v:setObject({})
        return v
    end

    local object = {}
    while true do
        if self:currentChar() ~= '"' then
            self:Raise(ParseResult.PARSE_MISS_KEY)
        end
        local success, key = pcall(function() return self:parseString() end)
        if not success then
            self:Raise(ParseResult.PARSE_INVALID_VALUE)
        end
        self:skipWhitespace()
        if self:currentChar() ~= ':' then
            self:Raise(ParseResult.PARSE_MISS_COLON)
        end
        self:forward()
        self:skipWhitespace()
        local success, value = pcall(function() return self:ParseValue() end)
        if not success then
            self:Raise(ParseResult.PARSE_INVALID_VALUE)
        end
        object[key:getString()] = value
        self:skipWhitespace()
        if self:currentChar() == ',' then
            self:forward()
            self:skipWhitespace()
            if self:terminative() then
                self:Raise(ParseResult.PARSE_MISS_KEY)
            end
        elseif self:currentChar() == '}' then
            self:forward()
            local v = JsonValue:new()
            v:setObject(object)
            return v
        else
            self:Raise(ParseResult.PARSE_MISS_COMMA_OR_CURLY_BRACKET)
        end
    end
end

---@return JsonValue
function DecodeContext:ParseValue()
    local current_char = self:currentChar()

    if current_char == 't' then
        return self:parseLiteral("true", NodeType.TRUE)
    elseif current_char == 'f' then
        return self:parseLiteral("false", NodeType.FALSE)
    elseif current_char == 'n' then
        return self:parseLiteral("null", NodeType.NULL)
    elseif current_char == '"' then
        return self:parseString()
    elseif current_char == '[' then
        return self:parseArray()
    elseif current_char == '{' then
        return self:parseObject()
    elseif current_char == '' then
        self:Raise(ParseResult.PARSE_EXPECT_VALUE)
    else
        return self:parseNumber()
    end

    error({})
end

---@class EncodeContext
---@field stack string[] Stack for building JSON string
local EncodeContext = {
    stack = {}
}

---@return EncodeContext
function EncodeContext:new()
    local o = {
        stack = {}
    }
    self.__index = self
    setmetatable(o, self)
    return o
end

---@param ch string
function EncodeContext:push(ch)
    self.stack[#self.stack + 1] = ch
end

---@param s string
function EncodeContext:pushString(s)
    for i = 1, string.len(s) do
        self.stack[#self.stack + 1] = s:sub(i, i)
    end
end

---@return string
function EncodeContext:pop()
    local ch = self.stack[#self.stack]
    self.stack[#self.stack] = nil
    return ch
end

function EncodeContext:clear()
    self.stack = {}
end

---@return string[]
function EncodeContext:elements()
    return self.stack
end

-- Main functions that use the classes

---@param jsonStr string
---@return {value: JsonValue, state: string}
function Parse(jsonStr)
    local ctx = DecodeContext:new(jsonStr)
    ctx:skipWhitespace()
    local success, result = pcall(function() return ctx:ParseValue() end)
    if success then
        ctx:skipWhitespace()
        if not ctx:terminative() then
            result:setType(NodeType.NULL)
            ctx:setState(ParseResult.PARSE_ROOT_NOT_SINGULAR)
        end
    end
    assert(ctx:isEmpty())
    return {
        value = success and result or JsonValue:new(),
        state = ctx:getState(),
    }
end

---@param v JsonValue
---@return string
function Stringify(v)
    local ctx = EncodeContext:new()
    local valueType = v:getType()
    if valueType == NodeType.NULL then
        ctx:pushString("null")
    elseif valueType == NodeType.FALSE then
        ctx:pushString("false")
    elseif valueType == NodeType.TRUE then
        ctx:pushString("true")
    elseif valueType == NodeType.NUMBER then
        local num = v:getNumber()
        ctx:pushString(string.format("%.17g", num))
    elseif valueType == NodeType.STRING then
        local str = v:getString()
        ctx:push('"')
        for i = 1, string.len(str), 1 do
            local ch = str:sub(i, i)
            if ch == '\"' then
                ctx:push('\\')
                ctx:push('\"')
            elseif ch == '\\' then
                ctx:push('\\')
                ctx:push('\\')
            elseif ch == '\b' then
                ctx:push('\\')
                ctx:push('\b')
            elseif ch == '\f' then
                ctx:push('\\')
                ctx:push('\f')
            elseif ch == '\n' then
                ctx:push('\\')
                ctx:push('\n')
            elseif ch == '\r' then
                ctx:push('\\')
                ctx:push('\r')
            elseif ch == '\t' then
                ctx:push('\\')
                ctx:push('\t')
            else
                if string.byte(ch) < 0x20 then
                    ctx:push('\\')
                    ctx:push('u')
                    ctx:push('0')
                    ctx:push('0')
                    ctx:push(HexDigits[(string.byte(ch) >> 4) + 1])
                    ctx:push(HexDigits[(string.byte(ch) & 15) + 1])
                else
                    ctx:push(ch)
                end
            end
        end
        ctx:push('"')
    elseif valueType == NodeType.ARRAY then
        local array = v:getArray()
        ctx:push('[')
        for i = 1, #array, 1 do
            local element = Stringify(array[i])
            ctx:pushString(element)
            ctx:push(',')
        end
        if #array > 1 then
            ctx:pop()
        end
        ctx:push(']')
    elseif valueType == NodeType.OBJECT then
        local object = v:getObject()
        ctx:push('{')
        local keys = {}
        for k in pairs(object) do
            table.insert(keys, k)
        end
        table.sort(keys)
        for _, k in ipairs(keys) do
            local element = Stringify(object[k])
            ctx:pushString(k)
            ctx:push(':')
            ctx:pushString(element)
            ctx:push(',')
        end
        if #keys > 0 then
            ctx:pop()
        end
        ctx:push('}')
    else
        error({ message = ParseResult.PARSE_INVALID_TYPE })
        ctx:clear()
    end

    return table.concat(ctx:elements())
end

---@class LeptJson
---@field Parse fun(jsonStr: string): {value: JsonValue, state: string}
---@field Stringify fun(v: JsonValue): string
---@field ParseResult ParseResult
---@field NodeType NodeType
return {
    Parse = Parse,
    Stringify = Stringify,
    ParseResult = ParseResult,
    NodeType = NodeType
}
