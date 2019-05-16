local function pack(...)
    return {n = select('#', ...), ...}
end

local array_mt = {}

local function mark_as_array(tab)
    return setmetatable(tab, array_mt)
end

local function array(...)
    return mark_as_array({...})
end

local function is_array(tab)
    return getmetatable(tab) == array_mt
end

local function null()
    return nil
end

local function string_starts(String, Start)
    return string.sub(String, 1, string.len(Start)) == Start
end

local function string_ends(String, End)
    return End == '' or string.sub(String, -string.len(End)) == End
end

local function is_logic(closure, tab)
    local is_object = type(tab) == 'table' and not closure.opts.is_nil(tab) and not closure.opts.is_array(tab)
    if is_object == false then
        return false
    end
    local contains_one_key = false
    for _, v in pairs(tab) do
        if not contains_one_key and type(v) ~= 'function' then
            contains_one_key = true
        else
            return false
        end
    end
    return is_object and contains_one_key
end

local function js_to_boolean(closure, value)
    if value == 0 or value == '' or value == '' or closure.opts.is_nil(value) then
        return false
    end
    if type(value) == 'number' and value ~= value then
        return false
    end
    return not (not value)
end

local function js_reducible_array_to_string(closure, value)
    if closure.opts.is_array(value) then
        local newval = value
        while #newval == 1 and closure.opts.is_array(newval[1]) do
            -- reduce array that only contain array
            newval = newval[1]
        end
        if #newval == 0 then
            return ''
        elseif #newval == 1 then
            return tostring(newval[1])
        end
    end
    return value
end

local function js_to_number(closure, value)
    value = js_reducible_array_to_string(closure, value)

    if value == 0 or value == '' or value == '0' or value == false then
        return 0
    end

    if value == true then
        return 1
    end

    local n = tonumber(value)
    if type(n) ~= 'number' then
        return 0 / 0
    end
    return n
end

local function js_is_equal(closure, a, b)
    if type(a) == type(b) then
        return a == b
    end
    if closure.opts.is_nil(a) or closure.opts.is_nil(b) then
        return a == b
    end

    -- handle empty or single item array
    if closure.opts.is_array(a) or closure.opts.is_array(b) then
        local a_ar = js_reducible_array_to_string(closure, a)
        local b_ar = js_reducible_array_to_string(closure, b)
        if type(a_ar) == 'string' and type(b_ar) == 'string' then
            return a_ar == b_ar
        end
    end

    -- convert to number
    local a_num = js_to_number(closure, a)
    local b_num = js_to_number(closure, b)
    return a_num == b_num
end

local function js_array_to_string(closure, a)
    local res = ''
    local stack = {}
    local local_closure = {
        table = a,
        index = 1
    }
    local first = true
    while local_closure ~= nil do
        local fully_iterated = true
        for i = local_closure.index, #local_closure.table, 1 do
            local v = local_closure.table[i]
            local str
            if closure.opts.is_array(v) then
                -- prevent recursive loop
                local recurse = false
                for _, saved in pairs(stack) do
                    if saved.table == v then
                        recurse = true
                        break
                    end
                end
                if recurse then
                    break
                end
                --

                -- add to stack
                local_closure.index = i + 1
                table.insert(stack, local_closure)
                local_closure = {table = v, index = 1}
                fully_iterated = false
                --
                break
            elseif type(v) == 'table' then
                str = '[object Object]'
            else
                str = tostring(v)
            end
            -- add comma between array items
            if first then
                first = false
            else
                res = res .. ','
            end
            --
            res = res .. str
        end

        if fully_iterated then
            local_closure = table.remove(stack)
        end
    end
    return res
end

local function js_to_string(closure, a)
    if closure.opts.is_array(a) then
        return js_array_to_string(closure, a)
    elseif type(a) == 'table' then
        -- object
        return '[object Object]'
    end

    -- others
    return tostring(a)
end

local operations = {}
operations.__index = operations

operations['!!'] = function(closure, a)
    return js_to_boolean(closure, a)
end

operations['!'] = function(closure, a)
    return not js_to_boolean(closure, a)
end

operations['=='] = function(closure, a, b)
    return js_is_equal(closure, a, b)
end

operations['==='] = function(_, a, b)
    return a == b
end

operations['!='] = function(closure, a, b)
    return not js_is_equal(closure, a, b)
end

operations['!=='] = function(_, a, b)
    return a ~= b
end

operations['>'] = function(closure, a, b)
    a = js_to_number(closure, a)
    b = js_to_number(closure, b)
    return a == a and b == b and a > b
end

operations['>='] = function(closure, a, b)
    a = js_to_number(closure, a)
    b = js_to_number(closure, b)
    return a == a and b == b and a >= b
end

operations['<'] = function(closure, a, b, c)
    a = js_to_number(closure, a)
    b = js_to_number(closure, b)
    if closure.opts.is_nil(c) then
        return a == a and b == b and a < b
    else
        c = js_to_number(closure, c)
        return a == a and b == b and c == c and a < b and b < c
    end
end

operations['<='] = function(closure, a, b, c)
    a = js_to_number(closure, a)
    b = js_to_number(closure, b)
    if closure.opts.is_nil(c) then
        return a == a and b == b and a <= b
    else
        c = js_to_number(closure, c)
        return a == a and b == b and c == c and a <= b and b <= c
    end
end

operations['+'] = function(closure, ...)
    local arg = pack(...)
    local a = 0
    for i = 1, arg.n do
        local v = arg[i]
        if i == 1 and type(v) == 'string' and arg.n > 1 then
            a = ''
        end

        if type(a) == 'string' then
            a = a .. js_to_string(closure, v)
        else
            local n = js_to_number(closure, v)
            if n == n then
                a = a + n
            else
                a = js_to_string(closure, a) .. js_to_string(closure, v)
            end
        end
    end
    return a
end

operations['*'] = function(closure, ...)
    local arg = pack(...)
    local a = 1
    for i = 1, arg.n do
        local v = arg[i]
        a = a * js_to_number(closure, v)
    end
    return a
end

operations['-'] = function(closure, a, b)
    a = js_to_number(closure, a)
    if closure.opts.is_nil(b) then
        return -a
    end
    b = js_to_number(closure, b)
    return a - b
end

operations['/'] = function(closure, a, b)
    a = js_to_number(closure, a)
    b = js_to_number(closure, b)
    return a / b
end

operations['%'] = function(closure, a, b)
    a = js_to_number(closure, a)
    b = js_to_number(closure, b)
    return a % b
end

operations['min'] = function(closure, ...)
    local arg = pack(...)
    for i = 1, arg.n do
        local v = arg[i]
        v = js_to_number(closure, v)
        if v ~= v then
            return v
        end
        arg[i] = v
    end
    return math.min(unpack(arg))
end

operations['max'] = function(closure, ...)
    local arg = pack(...)
    for i = 1, arg.n do
        local v = arg[i]
        v = js_to_number(closure, v)
        if v ~= v then
            return v
        end
        arg[i] = v
    end
    return math.max(unpack(arg))
end

operations['log'] = function(_, a)
    print(a)
    return a
end

operations['in'] = function(closure, a, b)
    if closure.opts.is_array(b) then
        for _, v in ipairs(b) do
            if v == a then
                return true
            end
        end
    elseif type(b) == 'table' then
        for _, v in pairs(b) do
            if v == a then
                return true
            end
        end
    elseif type(b) == 'string' then
        local i = string.find(b, tostring(a))
        return i ~= nil
    end

    return false
end

operations['cat'] = function(closure, ...)
    local arg = pack(...)
    local res = ''
    for i = 1, arg.n do
        local v = arg[i]
        res = res .. js_to_string(closure, v)
    end
    return res
end

operations['substr'] = function(closure, source, st, en)
    if closure.opts.is_nil(st) then
        return source
    end
    if st >= 0 then
        st = st + 1
    end
    if closure.opts.is_nil(en) then
        return string.sub(source, st)
    end
    if en >= 0 then
        en = st + en - 1
    else
        en = string.len(source) + en
    end
    return string.sub(source, st, en)
end

operations['merge'] = function(closure, ...)
    local arg = pack(...)
    if arg.n < 1 then
        return closure.opts.array()
    end

    local res = closure.opts.array()
    for i = 1, arg.n do
        local v = arg[i]
        if not closure.opts.is_array(v) then
            table.insert(res, v)
        else
            for _, sv in ipairs(v) do
                table.insert(res, sv)
            end
        end
    end
    return res
end

operations['var'] = function(closure, attr, default)
    local data = closure.data
    if closure.opts.is_nil(attr) or attr == '' then
        return data
    end

    if closure.opts.is_nil(data) or type(data) ~= 'table' then
        return data
    end

    if type(attr) == 'number' then
        local val = data[attr + 1]
        if closure.opts.is_nil(val) then
            return default
        end
        return val
    end

    if type(attr) ~= 'string' then
        return closure.opts.null()
    end

    if (string_starts(attr, '.') or string_ends(attr, '.')) then
        return closure.opts.null()
    end

    for sub in attr:gmatch('([^\\.]+)') do
        data = data[sub]
        if closure.opts.is_nil(data) then
            return default
        end
    end
    return data
end

operations['missing'] = function(closure, ...)
    local arg = pack(...)
    local missing = closure.opts.array()
    local keys = arg
    if closure.opts.is_array(keys[1]) then
        keys = keys[1]
    end

    for i = 1, keys.n or #keys do
        local attr = keys[i]
        local val = operations.var(closure, attr)
        if closure.opts.is_nil(val) or val == '' then
            table.insert(missing, attr)
        end
    end
    return missing
end

operations['missingSome'] = function(closure, minimum, keys)
    local missing = operations.missing(closure, unpack(keys))
    if #keys - #missing >= minimum then
        return closure.opts.array()
    else
        return missing
    end
end

operations['method'] = function(closure, obj, method, ...)
    if obj ~= nil and method ~= nil then
        return obj[method](obj, ...)
    end
    return closure.opts.null()
end

operations['join'] = function(closure, separator, items)
    if not closure.opts.is_array(items) then
        return closure.opts.null()
    end
    if not js_to_boolean(closure, separator) then
        return js_to_string(closure, items)
    end

    local res = ''
    for i, v in ipairs(items) do
        if i > 1 then
            res = res .. js_to_string(closure, separator)
        end
        res = res .. js_to_string(closure, v)
    end
    return res
end

operations['length'] = function(_, obj)
    if type(obj) == 'string' then
        return string.len(obj)
    end

    if type(obj) == 'table' then
        return #obj
    end

    return 0
end

operations['typeof'] = function(closure, v)
    if closure.opts.null() == v then
        return 'object'
    end

    local t = type(v)
    if t == 'nil' then
        return 'undefined'
    end
    if t == 'table' or t == 'userdata' or t == 'thread' then
        return 'object'
    end
    return t
end

operations['isArray'] = function(closure, v)
    return closure.opts.is_array(v)
end

operations['toUpperCase'] = function(_, v)
    if type(v) ~= "string" then
        return nil
    end
    return string.upper(v)
end

operations['toLowerCase'] = function(_, v)
    if type(v) ~= "string" then
        return nil
    end
    return string.lower(v)
end

-- snake-case alias to be compatible with original json logic
operations['missing_some'] = operations['missingSome']
operations['is_array'] = operations['isArray']

local function get_operator(tab)
    for k, _ in pairs(tab) do
        return k
    end
    return nil
end

local function table_copy_fill(source, opts)
    local target = {}
    for i, _ in pairs(source) do
        target[i] = opts.null() or true
    end
    if opts.is_array(source) then
        opts.mark_as_array(target)
    end
    return target
end

function recurse_array(stack, closure, last_child_result)
    -- zero length
    if #closure.logic == 0 then
        return table.remove(stack), closure.opts.array()
    end

    -- state initialization
    closure.state.length = closure.state.length or #closure.logic
    closure.state.index = closure.state.index or 1
    closure.state.recursed = closure.state.recursed or {}
    closure.state.normalized = closure.state.normalized or table_copy_fill(closure.logic, closure.opts)
    --

    -- recurse if necessary
    if not closure.state.recursed[closure.state.index] then
        closure.state.recursed[closure.state.index] = true
        table.insert(stack, closure)

        closure = {
            logic = closure.logic[closure.state.index],
            data = closure.data,
            state = {},
            opts = closure.opts
        }
        return closure, last_child_result
    end
    closure.state.normalized[closure.state.index] = last_child_result
    --

    -- process next item if available
    if closure.state.index < closure.state.length then
        closure.state.index = closure.state.index + 1
        return closure, last_child_result
    end

    return table.remove(stack), closure.state.normalized
end

local recurser = {}

-- 'if' should be called with a odd number of parameters, 3 or greater
-- This works on the pattern:
-- if( 0 ){ 1 }else{ 2 };
-- if( 0 ){ 1 }else if( 2 ){ 3 }else{ 4 };
-- if( 0 ){ 1 }else if( 2 ){ 3 }else if( 4 ){ 5 }else{ 6 };
-- The implementation is:
-- For pairs of values (0,1 then 2,3 then 4,5 etc)
-- If the first evaluates truthy, evaluate and return the second
-- If the first evaluates falsy, jump to the next pair (e.g, 0,1 to 2,3)
-- given one parameter, evaluate and return it. (it's an Else and all the If/ElseIf were false)
-- given 0 parameters, return NULL (not great practice, but there was no Else)
recurser['if'] = function(stack, closure, last_child_result)
    local op = get_operator(closure.logic)

    -- zero or one length
    if #closure.logic[op] <= 1 then
        return table.remove(stack), nil
    end

    -- state initialization
    closure.state.length = closure.state.length or #closure.logic[op]
    closure.state.index = closure.state.index or 1
    closure.state.recursed = closure.state.recursed or {}
    closure.state.normalized[op] = closure.state.normalized[op] or closure.opts.array()
    --

    -- recurse if haven't
    if not closure.state.recursed[closure.state.index] then
        closure.state.recursed[closure.state.index] = true
        table.insert(stack, closure)
        closure = {
            logic = closure.logic[op][closure.state.index],
            data = closure.data,
            state = {},
            opts = closure.opts
        }
        return closure, last_child_result
    end
    closure.state.normalized[op][closure.state.index] = last_child_result
    --

    if closure.state.index % 2 == 1 and closure.state.index < closure.state.length then
        if js_to_boolean(closure, closure.state.normalized[op][closure.state.index]) then
            -- closure conditions is true
            closure.state.index = closure.state.index + 1
        else
            -- closure conditions is false
            closure.state.index = closure.state.index + 2
        end
    else
        last_child_result = closure.state.normalized[op][closure.state.index]
        closure = table.remove(stack)
    end

    return closure, last_child_result
end

recurser['?:'] = recurser['if']

recurser['and'] = function(stack, closure, last_child_result)
    local op = get_operator(closure.logic)

    -- zero length
    if #closure.logic[op] == 0 then
        return table.remove(stack), nil
    end

    -- state initialization
    closure.state.length = closure.state.length or #closure.logic[op]
    closure.state.index = closure.state.index or 1
    closure.state.recursed = closure.state.recursed or {}
    closure.state.normalized[op] = closure.state.normalized[op] or closure.opts.array()
    --

    -- recurse if haven't
    if not closure.state.recursed[closure.state.index] then
        closure.state.recursed[closure.state.index] = true
        table.insert(stack, closure)
        closure = {
            logic = closure.logic[op][closure.state.index],
            data = closure.data,
            state = {},
            opts = closure.opts
        }
        return closure, last_child_result
    end
    closure.state.normalized[op][closure.state.index] = last_child_result
    --

    if
        js_to_boolean(closure, closure.state.normalized[op][closure.state.index]) and
            closure.state.index < closure.state.length
     then
        -- closure condition is true
        closure.state.index = closure.state.index + 1
    else
        -- closure condition is false or the last element
        last_child_result = closure.state.normalized[op][closure.state.index]
        closure = table.remove(stack)
    end

    return closure, last_child_result
end

recurser['or'] = function(stack, closure, last_child_result)
    local op = get_operator(closure.logic)

    -- zero length
    if #closure.logic[op] == 0 then
        closure = table.remove(stack)
        return closure, nil
    end

    -- state initialization
    closure.state.length = closure.state.length or #closure.logic[op]
    closure.state.index = closure.state.index or 1
    closure.state.recursed = closure.state.recursed or {}
    closure.state.normalized[op] = closure.state.normalized[op] or closure.opts.array()
    --

    -- recurse if necessary
    if not closure.state.recursed[closure.state.index] then
        closure.state.recursed[closure.state.index] = true
        table.insert(stack, closure)
        closure = {
            logic = closure.logic[op][closure.state.index],
            data = closure.data,
            state = {},
            opts = closure.opts
        }
        return closure, last_child_result
    end
    closure.state.normalized[op][closure.state.index] = last_child_result
    --

    if
        not js_to_boolean(closure, closure.state.normalized[op][closure.state.index]) and
            closure.state.index < closure.state.length
     then
        -- if true then continue next
        closure.state.index = closure.state.index + 1
    else
        -- false or the last element
        last_child_result = closure.state.normalized[op][closure.state.index]
        closure = table.remove(stack)
    end

    return closure, last_child_result
end

recurser['filter'] = function(stack, closure, last_child_result)
    local op = get_operator(closure.logic)

    -- zero length
    if #closure.logic[op] == 0 then
        return table.remove(stack), nil
    end

    -- state initialization
    closure.state.index = closure.state.index or 1
    closure.state.recursed = closure.state.recursed or false
    closure.state.scoped = closure.state.scoped or false
    closure.state.filtered = closure.state.filtered or {}
    closure.state.result = closure.state.result or closure.opts.array()
    closure.state.normalized[op] = closure.state.normalized[op] or closure.opts.array()
    --

    -- recurse scoped_data if necessary
    if not closure.state.recursed then
        closure.state.recursed = true
        table.insert(stack, closure)
        closure = {
            logic = closure.logic[op][1],
            data = closure.data,
            state = {},
            opts = closure.opts
        }
        return closure, last_child_result
    end
    if not closure.state.scoped then
        if type(last_child_result) ~= 'table' then
            return table.remove(stack), nil
        end
        closure.state.scoped = true
        closure.state.normalized[op][1] = last_child_result
        closure.state.length = #closure.state.normalized[op][1]
    end
    --

    -- filter and recurse if necessary
    local scoped_data = closure.state.normalized[op][1]
    if not closure.state.filtered[closure.state.index] then
        closure.state.filtered[closure.state.index] = true
        table.insert(stack, closure)
        closure = {
            logic = closure.logic[op][2],
            data = scoped_data[closure.state.index],
            state = {},
            opts = closure.opts
        }
        return closure, last_child_result
    end
    if js_to_boolean(closure, last_child_result) then
        table.insert(closure.state.result, scoped_data[closure.state.index])
    end
    --
    if closure.state.index < closure.state.length then
        closure.state.index = closure.state.index + 1
    else
        last_child_result = closure.state.result
        closure = table.remove(stack)
    end
    return closure, last_child_result
end

recurser['map'] = function(stack, closure, last_child_result)
    local op = get_operator(closure.logic)

    -- zero length
    if #closure.logic[op] == 0 then
        return table.remove(stack), nil
    end

    -- state initialization
    closure.state.index = closure.state.index or 1
    closure.state.recursed = closure.state.recursed or false
    closure.state.scoped = closure.state.scoped or false
    closure.state.mapped = closure.state.mapped or {}
    closure.state.result = closure.state.result or table_copy_fill(closure.logic[op], closure.opts)
    closure.state.normalized[op] = closure.state.normalized[op] or closure.opts.array()
    --

    -- recurse scoped_data if necessary
    if not closure.state.recursed then
        closure.state.recursed = true
        table.insert(stack, closure)
        closure = {
            logic = closure.logic[op][1],
            data = closure.data,
            state = {},
            opts = closure.opts
        }
        return closure, last_child_result
    end
    if not closure.state.scoped then
        if type(last_child_result) ~= 'table' then
            return table.remove(stack), nil
        end
        closure.state.scoped = true
        closure.state.normalized[op][1] = last_child_result
        closure.state.length = #closure.state.normalized[op][1]
    end
    --

    -- map and recurse if necessary
    local scoped_data = closure.state.normalized[op][1]
    if closure.state.length < 1 then
        return table.remove(stack), closure.opts.array()
    end
    if not closure.state.mapped[closure.state.index] then
        closure.state.mapped[closure.state.index] = true
        table.insert(stack, closure)
        closure = {
            logic = closure.logic[op][2],
            data = scoped_data[closure.state.index],
            state = {},
            opts = closure.opts
        }
        return closure, last_child_result
    end
    closure.state.result[closure.state.index] = last_child_result
    --

    if closure.state.index < closure.state.length then
        closure.state.index = closure.state.index + 1
    else
        last_child_result = closure.state.result
        closure = table.remove(stack)
    end
    return closure, last_child_result
end

recurser['reduce'] = function(stack, closure, last_child_result)
    local op = get_operator(closure.logic)
    -- zero length
    if #closure.logic[op] == 0 then
        closure = table.remove(stack)
        return closure, nil
    end

    -- state initialization
    closure.state.index = closure.state.index or 1
    closure.state.recursed = closure.state.recursed or false
    closure.state.scoped = closure.state.scoped or false
    closure.state.reduced = closure.state.reduced or {}
    closure.state.result = closure.state.result or closure.logic[op][3]
    closure.state.normalized[op] = closure.state.normalized[op] or closure.opts.array()
    --

    -- recurse scoped_data if necessary
    if not closure.state.recursed then
        closure.state.recursed = true
        table.insert(stack, closure)
        closure = {
            logic = closure.logic[op][1],
            data = closure.data,
            state = {},
            opts = closure.opts
        }
        return closure, last_child_result
    end
    if not closure.state.scoped then
        if type(last_child_result) ~= 'table' then
            return table.remove(stack), closure.state.result
        end
        closure.state.scoped = true
        closure.state.normalized[op][1] = last_child_result
        closure.state.length = #closure.state.normalized[op][1]
    end
    --

    -- reduce and recurse if necessary
    local scoped_data = closure.state.normalized[op][1]
    if closure.state.length < 1 then
        return table.remove(stack), closure.state.result
    end
    if not closure.state.reduced[closure.state.index] then
        closure.state.reduced[closure.state.index] = true
        table.insert(stack, closure)
        closure = {
            logic = closure.logic[op][2],
            data = {
                current = scoped_data[closure.state.index],
                accumulator = closure.state.result
            },
            state = {},
            opts = closure.opts
        }
        return closure, last_child_result
    end
    closure.state.result = last_child_result
    --

    if closure.state.index < closure.state.length then
        closure.state.index = closure.state.index + 1
    else
        last_child_result = closure.state.result
        closure = table.remove(stack)
    end
    return closure, last_child_result
end

recurser['all'] = function(stack, closure, last_child_result)
    local op = get_operator(closure.logic)

    -- zero length
    if #closure.logic[op] == 0 then
        return table.remove(stack), nil
    end

    -- state initialization
    closure.state.index = closure.state.index or 1
    closure.state.recursed = closure.state.recursed or false
    closure.state.scoped = closure.state.scoped or false
    closure.state.checked = closure.state.checked or {}
    closure.state.normalized[op] = closure.state.normalized[op] or closure.opts.array()
    --

    -- recurse scoped_data if necessary
    if not closure.state.recursed then
        closure.state.recursed = true
        table.insert(stack, closure)
        closure = {
            logic = closure.logic[op][1],
            data = closure.data,
            state = {},
            opts = closure.opts
        }
        return closure, last_child_result
    end
    if not closure.state.scoped then
        if type(last_child_result) ~= 'table' then
            return table.remove(stack), nil
        end
        closure.state.scoped = true
        closure.state.normalized[op][1] = last_child_result
        closure.state.length = #closure.state.normalized[op][1]
    end
    --

    -- filter and recurse if necessary
    local scoped_data = closure.state.normalized[op][1]
    if closure.state.length < 1 then
        closure = table.remove(stack)
        return closure, nil
    end
    if not closure.state.checked[closure.state.index] then
        closure.state.checked[closure.state.index] = true
        table.insert(stack, closure)
        closure = {
            logic = closure.logic[op][2],
            data = scoped_data[closure.state.index],
            state = {},
            opts = closure.opts
        }
        return closure, last_child_result
    end
    --

    if js_to_boolean(closure, last_child_result) and closure.state.index < closure.state.length then
        closure.state.index = closure.state.index + 1
    else
        last_child_result = js_to_boolean(closure, last_child_result)
        closure = table.remove(stack)
    end
    return closure, last_child_result
end

recurser['some'] = function(stack, closure, last_child_result)
    local op = get_operator(closure.logic)

    -- zero length
    if #closure.logic[op] == 0 then
        return table.remove(stack), nil
    end

    -- state initialization
    closure.state.index = closure.state.index or 1
    closure.state.recursed = closure.state.recursed or false
    closure.state.scoped = closure.state.scoped or false
    closure.state.checked = closure.state.checked or {}
    closure.state.normalized[op] = closure.state.normalized[op] or closure.opts.array()
    --

    -- recurse scoped_data if necessary
    if not closure.state.recursed then
        closure.state.recursed = true
        table.insert(stack, closure)
        closure = {
            logic = closure.logic[op][1],
            data = closure.data,
            state = {},
            opts = closure.opts
        }
        return closure, last_child_result
    end
    if not closure.state.scoped then
        if type(last_child_result) ~= 'table' then
            return table.remove(stack), nil
        end
        closure.state.scoped = true
        closure.state.normalized[op][1] = last_child_result
        closure.state.length = #closure.state.normalized[op][1]
    end
    --

    -- filter and recurse if necessary
    local scoped_data = closure.state.normalized[op][1]
    if closure.state.length < 1 then
        return table.remove(stack), nil
    end
    if not closure.state.checked[closure.state.index] then
        closure.state.checked[closure.state.index] = true
        table.insert(stack, closure)
        closure = {
            logic = closure.logic[op][2],
            data = scoped_data[closure.state.index],
            state = {},
            opts = closure.opts
        }
        return closure, last_child_result
    end
    --

    if not js_to_boolean(closure, last_child_result) and closure.state.index < closure.state.length then
        closure.state.index = closure.state.index + 1
    else
        last_child_result = js_to_boolean(closure, last_child_result)
        closure = table.remove(stack)
    end
    return closure, last_child_result
end

recurser['none'] = function(stack, closure, last_child_result)
    local op = get_operator(closure.logic)
    -- zero length
    if #closure.logic[op] == 0 then
        closure = table.remove(stack)
        return closure, nil
    end

    -- state initialization
    closure.state.index = closure.state.index or 1
    closure.state.recursed = closure.state.recursed or false
    closure.state.scoped = closure.state.scoped or false
    closure.state.checked = closure.state.checked or {}
    closure.state.normalized[op] = closure.state.normalized[op] or closure.opts.array()
    --

    -- recurse scoped_data if necessary
    if not closure.state.recursed then
        closure.state.recursed = true
        table.insert(stack, closure)
        closure = {
            logic = closure.logic[op][1],
            data = closure.data,
            state = {},
            opts = closure.opts
        }
        return closure, last_child_result
    end
    if not closure.state.scoped then
        if type(last_child_result) ~= 'table' then
            return table.remove(stack), nil
        end
        closure.state.scoped = true
        closure.state.normalized[op][1] = last_child_result
        closure.state.length = #closure.state.normalized[op][1]
    end
    --

    -- filter and recurse if necessary
    local scoped_data = closure.state.normalized[op][1]
    if closure.state.length < 1 then
        return table.remove(stack), nil
    end
    if not closure.state.checked[closure.state.index] then
        closure.state.checked[closure.state.index] = true
        table.insert(stack, closure)
        closure = {
            logic = closure.logic[op][2],
            data = scoped_data[closure.state.index],
            state = {},
            opts = closure.opts
        }
        return closure, last_child_result
    end
    --

    if not js_to_boolean(closure, last_child_result) and closure.state.index < closure.state.length then
        closure.state.index = closure.state.index + 1
    else
        last_child_result = not js_to_boolean(closure, last_child_result)
        closure = table.remove(stack)
    end
    return closure, last_child_result
end

local function is_sub_operation(op)
    return type(op) == 'string' and string.find(op, '.', 1, true) and not string_starts(op, '.') and
        not string_ends(op, '.')
end

local function get_operation(op_string, available_operations)
    if type(available_operations[op_string]) == 'function' then
        return available_operations[op_string]
    elseif not is_sub_operation(op_string) then
        return nil
    end

    -- op string contain "."
    -- WARN: untested
    local new_op = available_operations
    for sub_op_string in op_string:gmatch('([^\\.]+)') do
        new_op = new_op[sub_op_string]
        if new_op == nil then
            return nil
        end
    end
    if type(new_op) ~= 'function' then
        return nil
    end
    return new_op
    --
end

local function recurse_others(stack, closure, last_child_result)
    local err = nil
    local operation_name = get_operator(closure.logic)
    local available_operations
    if type(closure.opts.custom_operations) == 'table' then
        available_operations = setmetatable(closure.opts.custom_operations, operations)
    else
        available_operations = operations
    end
    local operation = get_operation(operation_name, available_operations)
    if operation == nil then
        return table.remove(stack), closure.logic, 'invalid operations'
    end

    -- recurse if haven't
    if not closure.state.recursed then
        closure.state.recursed = {}
        table.insert(stack, closure)
        closure = {
            logic = closure.logic[operation_name],
            data = closure.data,
            state = {},
            opts = closure.opts
        }
        return closure, last_child_result
    end
    --

    if not closure.opts.is_array(last_child_result) then
        last_child_result = closure.opts.mark_as_array({last_child_result})
    end
    closure.state.normalized[operation_name] = last_child_result

    last_child_result = operation(closure, unpack(closure.state.normalized[operation_name]))
    return table.remove(stack), last_child_result, err
end

local JsonLogic = {}
--- function sum description.
-- apply the json-logic with the given data
-- some behavior of json-logic can be influenced by 'opts' table
-- 'opts' can include the following attribute:
--   is_array = (function), determine wether a table is an array or not
--   mark_as_array = (function), mark a lua table as an array
--   null = (function), return value that represent json nill value
--   custom_operations = (table), a table contains custom operations
--   blacklist = (table), an array contains list of operations to be blacklisted.
--   whitelist = (table), an array contains list of operations to be whitelisted.
-- @tparam table logic description
-- @tparam table data description
-- @tparam table opts is a table containing keys:
-- @return value result of the logic.
-- @author
function JsonLogic.apply(logic, data, opts)
    local stack = {}
    local closure = {
        logic = logic,
        data = data,
        state = {
            normalized = nil
        },
        opts = nil
    }
    opts = opts or nil
    if type(opts.is_array) ~= 'function' then
        opts.is_array = is_array
    end
    if type(opts.mark_as_array) ~= 'function' then
        opts.mark_as_array = mark_as_array
    end
    opts.array = function(...)
        return opts.mark_as_array({...})
    end
    if type(opts.null) ~= 'function' then
        opts.null = null
    end
    opts.is_nil = function(v)
        return v == opts.null() or v == nil
    end
    closure.opts = opts

    local last_child_result = opts.null()
    local err = nil

    -- since lua does not have "continue" like statement, we use two loops
    while closure do
        while closure do
            -- recurse array
            if closure.opts.is_array(closure.logic) then
                closure, last_child_result = recurse_array(stack, closure, last_child_result)
                break
            end

            -- You've recursed to a primitive, stop!
            if not is_logic(closure, closure.logic) then
                last_child_result = closure.logic
                closure = table.remove(stack)
                break
            end
            --

            -- literal operator
            local op = get_operator(closure.logic)
            if op == '_' then
                last_child_result = closure.logic[op]
                closure = table.remove(stack)
                break
            end

            -- check for blacklist or non-whitelisted operations
            if type(closure.opts.blacklist) == 'table' and closure.opts.blacklist[op] then
                return closure.logic, 'blacklisted operations'
            elseif type(closure.opts.whitelist) == 'table' and not closure.opts.whitelist[op] then
                return closure.logic, 'non-whitelisted operations'
            end
            --

            closure.data = closure.data or {}
            closure.state.normalized = closure.state.normalized or {}
            if type(recurser[op]) == 'function' then
                closure, last_child_result, err = recurser[op](stack, closure, last_child_result)
            else
                closure, last_child_result, err = recurse_others(stack, closure, last_child_result)
            end

            -- if the result is nil then return the specified null value
            if last_child_result == nil then
                last_child_result = opts.null()
            end
        end
    end

    return last_child_result, err
end

function JsonLogic.new_logic(operation, params)
    local lgc = {}
    if operation ~= nil then
        lgc[operation] = params
    end
    return lgc
end

JsonLogic.is_array = is_array
JsonLogic.mark_as_array = mark_as_array
JsonLogic.array = array

return JsonLogic
