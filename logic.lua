local function string_starts(String, Start)
    return string.sub(String, 1, string.len(Start)) == Start
end

local function string_ends(String, End)
    return End == '' or string.sub(String, -string.len(End)) == End
end

local array_mt = {}

local function mark_as_array(tab)
    return setmetatable(tab, array_mt)
end

local function array(...)
    return mark_as_array({unpack(arg)})
end

local function is_array(tab)
    return getmetatable(tab) == array_mt
end

local function is_logic(tab)
    local is_object = type(tab) == 'table' and tab ~= nil and is_array(tab) == false
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

local function js_to_boolean(value)
    if value == 0 or value == '' or value == "" then
        return false
    end
    if type(value) == 'number' and value ~= value then
        return false
    end
    return not (not value)
end

local function js_reducible_array_to_string(value)
    if is_array(value) then
        local newval = value
        while #newval == 1 and is_array(newval[1]) do
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

local function js_to_number(value)
    value = js_reducible_array_to_string(value)

    if value == 0 or value == '' or value == '0' or value == false then
        return 0
    end
    -- if type(value) == 'table' and #value == 0 then
    --     return 0
    -- end

    if value == true then
        return 1
    end

    local n = tonumber(value)
    if type(n) ~= 'number' then
        return 0 / 0
    end
    return n
end

local function js_is_equal(a, b)
    if type(a) == type(b) then
        return a == b
    end
    if a == nil or b == nil then
        return a == b
    end

    -- handle empty or single item array
    if is_array(a) or is_array(b) then
        local a_ar = js_reducible_array_to_string(a)
        local b_ar = js_reducible_array_to_string(b)
        if type(a_ar) == 'string' and type(b_ar) == 'string' then
            return a_ar == b_ar
        end
    end

    -- convert to number
    local a_num = js_to_number(a)
    local b_num = js_to_number(b)
    return a_num == b_num
end

local function js_array_to_string(a)
    local res = ''
    local stack = {}
    local current = {
        table = a,
        index = 1
    }
    while current ~= nil do
        local i = 1
        local fully_iterated = true
        for _, v in pairs(current.table) do
            if i >= current.index then
                if is_array(v) then
                    -- prevent recursive
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
                    current.index = i + 1
                    table.insert(stack, current)
                    current = {
                        table = v,
                        index = 1
                    }
                    fully_iterated = false
                    --
                    break
                elseif type(v) == 'table' then
                    res = res .. '[object object]'
                else
                    res = res .. tostring(v)
                end
            end
            i = i + 1
        end

        if fully_iterated then
            current = table.remove(stack)
        end
    end
    return res
end

local function js_to_string(a)
    if is_array(a) then
        return js_array_to_string(a)
    elseif type(a) == 'table' then
        -- object
        return '[object object]'
    end 

    -- others
    return tostring(a)
end

local function get_operator(tab)
    for k, _ in pairs(tab) do
        return k
    end
    return nil
end

local JsonLogic = {}

local operations = {}

operations['!!'] = function(_, a)
    return js_to_boolean(a)
end
operations['!'] = function(_, a)
    return not js_to_boolean(a)
end
operations['=='] = function(_, a, b)
    return js_is_equal(a, b)
end
operations['==='] = function(_, a, b)
    return a == b
end
operations['!='] = function(_, a, b)
    return not js_is_equal(a, b)
end
operations['!=='] = function(_, a, b)
    return a ~= b
end
operations['>'] = function(_, a, b)
    a = js_to_number(a)
    b = js_to_number(b)
    return a > b
end
operations['>='] = function(_, a, b)
    a = js_to_number(a)
    b = js_to_number(b)
    return a >= b
end
operations['<'] = function(_, a, b, c)
    if c == nil then 
        return js_to_number(a) < js_to_number(b) 
    else
        return js_to_number(a) < js_to_number(b) and  js_to_number(b) < js_to_number(c)
    end
end
operations['<='] = function(_, a, b, c)
    if c == nil then 
        return js_to_number(a) <= js_to_number(b) 
    else
        return js_to_number(a) <= js_to_number(b) and  js_to_number(b) <= js_to_number(c)
    end
end
operations['+'] = function(_, ...)
    local a = 0
    for _, v in ipairs(arg) do
        a = a + js_to_number(v)
    end
    return a
end
operations['*'] = function(_, ...)
    local a = 1
    for _, v in ipairs(arg) do
        a = a * js_to_number(v)
    end
    return a
end
operations['-'] = function(_, a,b)
    if b == nil then
        return - js_to_number(a)
    end
    return js_to_number(a) - js_to_number(b) 
end
operations['/'] = function(_, a,b)
    return js_to_number(a) / js_to_number(b) 
end
operations['%'] = function(_, a,b)
    return js_to_number(a) % js_to_number(b) 
end
operations["min"] = function(_, ...)
    for i,v in ipairs(arg) do
        v = js_to_number(v)
        if v ~= v then
            return nil
        end
        arg[i] = v
    end
    return math.min( unpack(arg) )
end
operations["max"] = function(_, ...)
    for i,v in ipairs(arg) do
        v = js_to_number(v)
        if v ~= v then
            return nil
        end
        arg[i] = v
    end
    return math.max( unpack(arg) )
end
operations['log'] = function(_, a)
    print(a)
    return a
end
operations['in'] = function(_, a, b)
    if is_array(b) then
        for i, v in ipairs(b) do
            if v == a then
                return true
            end
        end
    elseif type(b) == 'table' then
        for i, v in pairs(b) do
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
operations['cat'] = function(_, ...)
    arg["n"] = nil
    return js_to_string(mark_as_array(arg))
end
operations['substr'] = function(_, source, st, en)
    if st == nil then
        return source
    end
    if st >= 0 then st = st + 1 end
    if en == nil then
        return string.sub(source, st)
    end
    if en >= 0 then 
        en = st + en - 1 
    else
        en = string.len( source ) + en
    end
    return string.sub(source, st, en)
end
operations['merge'] = function(_, ...)
    if #arg < 1 then
        return array()
    end

    local res = array()
    for _, v in ipairs(arg) do
        if not is_array(v) then
            table.insert(res, v)
        else
            for _, sv in ipairs(v) do
                table.insert(res, sv)
            end
        end
    end
    return res
end
operations['var'] = function(data, attr, default)
    if attr == nil or attr == '' then
        return data
    end

    if data == nil or type(data) ~= 'table' then
        return data
    end

    if type(attr) == 'number' then
        local val = data[attr + 1]
        if val == nil then
            return default
        end
        return val
    end

    if type(attr) ~= 'string' then
        return nil
    end

    if (string_starts(attr, '.') or string_ends(attr, '.')) then
        return nil
    end

    for sub in attr:gmatch('([^\\.]+)') do
        data = data[sub]
        if data == nil then
            return default
        end
    end
    return data
end
operations['missing'] = function(data, ...)
    local missing = array()
    local keys = arg
    if is_array(keys[1]) then
        keys = keys[1]
    end

    for _, attr in ipairs(keys) do
        local val = operations.var(data, attr)
        if val == nil or val == '' then
            table.insert(missing, attr)
        end
    end
    return missing
end
operations['missing_some'] = function(data, minimum, keys)
    local missing = operations.missing(data, unpack(keys))
    if #keys - #missing >= minimum then
        return array()
    else
        return missing
    end
end
operations['method'] = function(_, obj, method, ...)
    if obj ~= nil and method ~= nil then
        return obj[method](obj, unpack(arg))
    end
    return nil
end
operations['join'] = function(_, separator, ...)
    if not js_to_boolean(separator) then
        table.remove(arg)
        return js_to_string(arg)
    end

    local res = ''
    for i, v in ipairs(arg) do
        if i > 1 then
            res = res .. js_to_string(separator)
        end
        res = res .. js_to_string(v)
    end
    return res
end
operations["length"] = function(_, obj)
    if type(obj) == "string" then
        return string.len( obj )
    end

    if type(obj) == "table" then
        return #obj
    end

    return 0
end

function JsonLogic.apply(logic, data, options)
    local stack = {}
    local current = {
        logic = logic,
        logic_normalized = nil,
        data = data,
        state = {}
    }
    local last_child_result = nil
    local err = nil
    if type(options) ~= 'table' or options == nil then
        options = {}
    end

    -- since lua does not have "continue" like statement, we use two loops
    while current do
        while current do
            if type(options.is_array) == 'function' and options.is_array(current.logic) then
                mark_as_array(current.logic)
            end
            -- recurse array or primitive
            if is_array(current.logic) then
                if not current.logic_normalized then
                    current.logic_normalized = array()
                    for i,_ in pairs(current.logic) do
                        current.logic_normalized[i] = 0
                    end
                end
                -- zero length
                if #current.logic == 0 then
                    last_child_result = array()
                    current = table.remove(stack)
                    break
                end

                -- state initialization
                if current.state.length == nil then
                    current.state.length = #current.logic
                end
                if current.state.index == nil then
                    current.state.index = 1
                end
                if current.state.recursed == nil then
                    current.state.recursed = {}
                end
                --

                -- recurse if necessary
                if not current.state.recursed[current.state.index] then
                    -- the item has not been tried for primitivity

                    -- push the current array into stack and mark the current index
                    current.state.recursed[current.state.index] = true
                    table.insert(stack, current)

                    -- set the item as current
                    current = {
                        logic = current.logic[current.state.index],
                        data = current.data,
                        state = {}
                    }
                    break
                end
                current.logic_normalized[current.state.index] = last_child_result
                --

                -- process next item if available
                if current.state.index < current.state.length then
                    current.state.index = current.state.index + 1
                    break
                end

                last_child_result = current.logic_normalized
                current = table.remove(stack)
                break
            end

            -- You've recursed to a primitive, stop!
            if not is_logic(current.logic) then
                last_child_result = current.logic
                current = table.remove(stack)
                break
            end
            --

            current.data = current.data or {}
            local op = get_operator(current.logic)
            if current.logic_normalized == nil then
                current.logic_normalized = {}; current.logic_normalized[op] = {}
            end
            -- check for blacklist or non-whitelisted operations
            if type(options.blacklist) == 'table' and options.blacklist[op] then
                return current.logic, 'blacklisted operations'
            elseif type(options.whitelist) == 'table' and not options.whitelist[op] then
                return current.logic, 'non-whitelisted operations'
            end
            --

            -- 'if', 'and', and 'or' violate the normal rule of depth-first calculating consequents,
            -- let each manage recursion as needed.
            if op == 'if' or op == '?:' then
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

                -- zero ore one length
                if #current.logic[op] <= 1 then
                    last_child_result = nil
                    current = table.remove(stack)
                    break
                end

                -- state initialization
                if current.state.length == nil then
                    current.state.length = #current.logic[op]
                end
                if current.state.index == nil then
                    current.state.index = 1
                end
                if current.state.recursed == nil then
                    current.state.recursed = {}
                end
                --

                -- recurse if necessary
                if not current.state.recursed[current.state.index] then
                    current.state.recursed[current.state.index] = true
                    table.insert(stack, current)
                    current = {
                        logic = current.logic[op][current.state.index],
                        data = current.data,
                        state = {}
                    }
                    break
                end
                current.logic_normalized[op][current.state.index] = last_child_result
                --

                if current.state.index % 2 == 1 and current.state.index < current.state.length then
                    -- processing conditions
                    if js_to_boolean(current.logic_normalized[op][current.state.index]) then
                        current.state.index = current.state.index + 1
                    else
                        current.state.index = current.state.index + 2
                    end
                else
                    last_child_result = current.logic_normalized[op][current.state.index]
                    current = table.remove(stack)
                end
                break
            elseif op == 'and' then
                -- zero length
                if #current.logic[op] == 0 then
                    last_child_result = nil
                    current = table.remove(stack)
                    break
                end

                -- state initialization
                if current.state.length == nil then
                    current.state.length = #current.logic[op]
                end
                if current.state.index == nil then
                    current.state.index = 1
                end
                if current.state.recursed == nil then
                    current.state.recursed = {}
                end
                --

                -- recurse if necessary
                if not current.state.recursed[current.state.index] then
                    current.state.recursed[current.state.index] = true
                    table.insert(stack, current)
                    current = {
                        logic = current.logic[op][current.state.index],
                        data = current.data,
                        state = {}
                    }
                    break
                end
                current.logic_normalized[op][current.state.index] = last_child_result
                --

                if
                    js_to_boolean(current.logic_normalized[op][current.state.index]) and
                        current.state.index < current.state.length
                 then
                    -- if true then continue next
                    current.state.index = current.state.index + 1
                else
                    -- false or the last element
                    last_child_result = current.logic_normalized[op][current.state.index]
                    current = table.remove(stack)
                end
                break
            elseif op == 'or' then
                -- zero length
                if #current.logic[op] == 0 then
                    last_child_result = nil
                    current = table.remove(stack)
                    break
                end

                -- state initialization
                if current.state.length == nil then
                    current.state.length = #current.logic[op]
                end
                if current.state.index == nil then
                    current.state.index = 1
                end
                if current.state.recursed == nil then
                    current.state.recursed = {}
                end
                --

                -- recurse if necessary
                if not current.state.recursed[current.state.index] then
                    current.state.recursed[current.state.index] = true
                    table.insert(stack, current)
                    current = {
                        logic = current.logic[op][current.state.index],
                        data = current.data,
                        state = {}
                    }
                    break
                end
                current.logic_normalized[op][current.state.index] = last_child_result
                --

                if
                    not js_to_boolean(current.logic_normalized[op][current.state.index]) and
                        current.state.index < current.state.length
                 then
                    -- if true then continue next
                    current.state.index = current.state.index + 1
                else
                    -- false or the last element
                    last_child_result = current.logic_normalized[op][current.state.index]
                    current = table.remove(stack)
                end
                break
            elseif op == 'filter' then
                -- zero length
                if #current.logic[op] == 0 then
                    last_child_result = nil
                    current = table.remove(stack)
                    break
                end

                -- state initialization
                if current.state.index == nil then
                    current.state.index = 1
                end
                if current.state.recursed == nil then
                    current.state.recursed = false
                end
                if current.state.assigned == nil then
                    current.state.assigned = false
                end
                if current.state.filtered == nil then
                    current.state.filtered = {}
                end
                if current.state.result == nil then
                    current.state.result = array()
                end
                --

                -- recurse scoped_data if necessary
                if not current.state.recursed then
                    current.state.recursed = true
                    table.insert(stack, current)
                    current = {
                        logic = current.logic[op][1],
                        data = current.data,
                        state = {}
                    }
                    break
                end
                if not current.state.assigned and type(last_child_result) ~= "table" then
                    last_child_result = nil
                    current = table.remove(stack)
                    break
                end
                if not current.state.assigned then
                    current.state.assigned = true
                    current.logic_normalized[op][1] = last_child_result
                    current.state.length = #current.logic_normalized[op][1]
                end
                local scoped_data = current.logic_normalized[op][1]
                --

                -- filter and recurse if necessary
                if not current.state.filtered[current.state.index] then
                    current.state.filtered[current.state.index] = true
                    table.insert(stack, current)
                    current = {
                        logic = current.logic[op][2],
                        data = scoped_data[current.state.index],
                        state = {}
                    }
                    break
                end
                if js_to_boolean(last_child_result) then
                    table.insert(current.state.result, scoped_data[current.state.index])
                end
                --
                if current.state.index < current.state.length then
                    current.state.index = current.state.index + 1
                else
                    last_child_result = current.state.result
                    current = table.remove(stack)
                end
                break
            elseif op == 'map' then
                -- zero length
                if #current.logic[op] == 0 then
                    last_child_result = nil
                    current = table.remove(stack)
                    break
                end

                -- state initialization
                if current.state.index == nil then
                    current.state.index = 1
                end
                if current.state.recursed == nil then
                    current.state.recursed = false
                end
                if current.state.assigned == nil then
                    current.state.assigned = false
                end
                if current.state.mapped == nil then
                    current.state.mapped = {}
                end
                if current.state.result == nil then
                    current.state.result = array()
                    for i,_ in pairs(current.logic[op]) do
                        current.state.result[i] = 0
                    end
                end
                --

                -- recurse scoped_data if necessary
                if not current.state.recursed then
                    current.state.recursed = true
                    table.insert(stack, current)
                    current = {
                        logic = current.logic[op][1],
                        data = current.data,
                        state = {}
                    }
                    break
                end
                if not current.state.assigned and type(last_child_result) ~= "table" then
                    last_child_result = nil
                    current = table.remove(stack)
                    break
                end
                if not current.state.assigned then
                    current.state.assigned = true
                    current.logic_normalized[op][1] = last_child_result
                    current.state.length = #current.logic_normalized[op][1]
                end
                local scoped_data = current.logic_normalized[op][1]
                --

                -- map and recurse if necessary
                if current.state.length < 1 then
                    last_child_result = array()
                    current = table.remove(stack)
                    break
                end
                if not current.state.mapped[current.state.index] then
                    current.state.mapped[current.state.index] = true
                    table.insert(stack, current)
                    current = {
                        logic = current.logic[op][2],
                        data = scoped_data[current.state.index],
                        state = {}
                    }
                    break
                end
                current.state.result[current.state.index]= last_child_result
                --

                if current.state.index < current.state.length then
                    current.state.index = current.state.index + 1
                else
                    last_child_result = current.state.result
                    current = table.remove(stack)
                end
                break
            elseif op == 'reduce' then
                -- zero length
                if #current.logic[op] == 0 then
                    last_child_result = nil
                    current = table.remove(stack)
                    break
                end

                -- state initialization
                if current.state.index == nil then
                    current.state.index = 1
                end
                if current.state.recursed == nil then
                    current.state.recursed = false
                end
                if current.state.assigned == nil then
                    current.state.assigned = false
                end
                if current.state.reduced == nil then
                    current.state.reduced = {}
                end
                if current.state.result == nil then
                    current.state.result = current.logic[op][3]
                end
                --

                -- recurse scoped_data if necessary
                if not current.state.recursed then
                    current.state.recursed = true
                    table.insert(stack, current)
                    current = {
                        logic = current.logic[op][1],
                        data = current.data,
                        state = {}
                    }
                    break
                end
                if not current.state.assigned and type(last_child_result) ~= "table" then
                    last_child_result = current.state.result
                    current = table.remove(stack)
                    break
                end
                if not current.state.assigned then
                    current.state.assigned = true
                    current.logic_normalized[op][1] = last_child_result
                    current.state.length = #current.logic_normalized[op][1]
                end
                local scoped_data = current.logic_normalized[op][1]
                --

                -- filter and recurse if necessary
                if current.state.length < 1 then
                    last_child_result = current.state.result
                    current = table.remove(stack)
                    break
                end
                if not current.state.reduced[current.state.index] then
                    current.state.reduced[current.state.index] = true
                    table.insert(stack, current)
                    current = {
                        logic = current.logic[op][2],
                        data = {
                            current = scoped_data[current.state.index],
                            accumulator = current.state.result
                        },
                        state = {}
                    }
                    break
                end
                current.state.result = last_child_result
                --

                if current.state.index < current.state.length then
                    current.state.index = current.state.index + 1
                else
                    last_child_result = current.state.result
                    current = table.remove(stack)
                end
                break
            elseif op == 'all' then
                -- zero length
                if #current.logic[op] == 0 then
                    last_child_result = nil
                    current = table.remove(stack)
                    break
                end

                -- state initialization
                if current.state.index == nil then
                    current.state.index = 1
                end
                if current.state.recursed == nil then
                    current.state.recursed = false
                end
                if current.state.assigned == nil then
                    current.state.assigned = false
                end
                if current.state.checked == nil then
                    current.state.checked = {}
                end
                --

                -- recurse scoped_data if necessary
                if not current.state.recursed then
                    current.state.recursed = true
                    table.insert(stack, current)
                    current = {
                        logic = current.logic[op][1],
                        data = current.data,
                        state = {}
                    }
                    break
                end
                if not current.state.assigned and type(last_child_result) ~= "table" then
                    last_child_result = nil
                    current = table.remove(stack)
                    break
                end
                if not current.state.assigned then
                    current.state.assigned = true
                    current.logic_normalized[op][1] = last_child_result
                    current.state.length = #current.logic_normalized[op][1]
                end
                local scoped_data = current.logic_normalized[op][1]
                --

                -- filter and recurse if necessary
                if current.state.length < 1 then
                    last_child_result = nil
                    current = table.remove(stack)
                    break
                end
                if not current.state.checked[current.state.index] then
                    current.state.checked[current.state.index] = true
                    table.insert(stack, current)
                    current = {
                        logic = current.logic[op][2],
                        data = scoped_data[current.state.index],
                        state = {}
                    }
                    break
                end
                --

                if js_to_boolean(last_child_result) and current.state.index < current.state.length then
                    current.state.index = current.state.index + 1
                else
                    last_child_result = js_to_boolean(last_child_result)
                    current = table.remove(stack)
                end
                break
            elseif op == 'some' then
                -- zero length
                if #current.logic[op] == 0 then
                    last_child_result = nil
                    current = table.remove(stack)
                    break
                end

                -- state initialization
                if current.state.index == nil then
                    current.state.index = 1
                end
                if current.state.recursed == nil then
                    current.state.recursed = false
                end
                if current.state.assigned == nil then
                    current.state.assigned = false
                end
                if current.state.checked == nil then
                    current.state.checked = {}
                end
                --

                -- recurse scoped_data if necessary
                if not current.state.recursed then
                    current.state.recursed = true
                    table.insert(stack, current)
                    current = {
                        logic = current.logic[op][1],
                        data = current.data,
                        state = {}
                    }
                    break
                end
                if not current.state.assigned and type(last_child_result) ~= "table" then
                    last_child_result = nil
                    current = table.remove(stack)
                    break
                end
                if not current.state.assigned then
                    current.state.assigned = true
                    current.logic_normalized[op][1] = last_child_result
                    current.state.length = #current.logic_normalized[op][1]
                end
                local scoped_data = current.logic_normalized[op][1]
                --

                -- filter and recurse if necessary
                if current.state.length < 1 then
                    last_child_result = nil
                    current = table.remove(stack)
                    break
                end
                if not current.state.checked[current.state.index] then
                    current.state.checked[current.state.index] = true
                    table.insert(stack, current)
                    current = {
                        logic = current.logic[op][2],
                        data = scoped_data[current.state.index],
                        state = {}
                    }
                    break
                end
                --

                if not js_to_boolean(last_child_result) and current.state.index < current.state.length then
                    current.state.index = current.state.index + 1
                else
                    last_child_result = js_to_boolean(last_child_result)
                    current = table.remove(stack)
                end
                break
            elseif op == 'none' then
                -- zero length
                if #current.logic[op] == 0 then
                    last_child_result = nil
                    current = table.remove(stack)
                    break
                end

                -- state initialization
                if current.state.index == nil then
                    current.state.index = 1
                end
                if current.state.recursed == nil then
                    current.state.recursed = false
                end
                if current.state.assigned == nil then
                    current.state.assigned = false
                end
                if current.state.checked == nil then
                    current.state.checked = {}
                end
                --

                -- recurse scoped_data if necessary
                if not current.state.recursed then
                    current.state.recursed = true
                    table.insert(stack, current)
                    current = {
                        logic = current.logic[op][1],
                        data = current.data,
                        state = {}
                    }
                    break
                end
                if not current.state.assigned and type(last_child_result) ~= "table" then
                    last_child_result = nil
                    current = table.remove(stack)
                    break
                end
                if not current.state.assigned then
                    current.state.assigned = true
                    current.logic_normalized[op][1] = last_child_result
                    current.state.length = #current.logic_normalized[op][1]
                end
                local scoped_data = current.logic_normalized[op][1]
                --

                -- filter and recurse if necessary
                if current.state.length < 1 then
                    last_child_result = nil
                    current = table.remove(stack)
                    break
                end
                if not current.state.checked[current.state.index] then
                    current.state.checked[current.state.index] = true
                    table.insert(stack, current)
                    current = {
                        logic = current.logic[op][2],
                        data = scoped_data[current.state.index],
                        state = {}
                    }
                    break
                end
                --

                if not js_to_boolean(last_child_result) and current.state.index < current.state.length then
                    current.state.index = current.state.index + 1
                else
                    last_child_result = not js_to_boolean(last_child_result)
                    current = table.remove(stack)
                end
                break
            end

            -- Everyone else gets immediate depth-first recursion of it's value before invoked
            if not current.state.recursed then
                current.state.recursed = {}
                table.insert(stack, current)
                current = {
                    logic = current.logic[op],
                    data = current.data,
                    state = {}
                }
                break
            end
            if type(options.is_array) == 'function' and options.is_array(last_child_result) then
                mark_as_array(last_child_result)
            end
            current.logic_normalized[op] = last_child_result
            if not is_array(current.logic_normalized[op]) then
                current.logic_normalized[op] = mark_as_array({current.logic_normalized[op]})
            end
            --

            -- invoke the operator
            if type(operations[op]) == 'function' then
                last_child_result = operations[op](current.data, unpack(current.logic_normalized[op]))
            elseif
                type(op) == 'string' and string.find(op, '.', 1, true) and not string_starts(op, '.') and
                    not string_ends(op, '.')
             then
                local newOP = operations
                for subOP in op:gmatch('([^\\.]+)') do
                    newOP = newOP[subOP]
                    if newOP == nil or type(newOP) ~= 'function' then
                        return current.logic, 'invalid operations'
                    end
                end
                last_child_result = newOP(current.data, unpack(current.logic_normalized[op]))
            else
                last_child_result = current.logic
                err = 'invalid operations'
            end
            current = table.remove(stack)
            --
        end
    end

    return last_child_result, err
end

JsonLogic.new_logic = function (operation, ...)
    local lgc = {}
    if operation ~= nil then
        lgc[operation] = array(unpack(arg))
    end
    return lgc
end

JsonLogic.add_operation = function(name, code)
    operations[name] = code
end

JsonLogic.delete_operation = function(name)
    operations[name] = nil
end

JsonLogic.array = array
JsonLogic.is_array = is_array
JsonLogic.mark_as_array = mark_as_array

return JsonLogic
