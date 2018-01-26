local array_mt = {}
local function array(...)
    return setmetatable({...}, array_mt)
end
local function is_array(tab)
    return getmetatable(tab) == array_mt
end

local logic = require('logic')
local function logic_apply(lgc, data, options)
    if type(options) ~= 'table' or options == nil then
        options = {}
    end
    options.is_array = is_array
    return logic.apply(lgc, data, options)
end

describe(
    "json-logic 'var' testing",
    function()
        local kv_data = {attr1 = 'val1', attr2 = 'val2', sub_attr = {attr = 'val1'}}
        local arr_data = array('val1', 'val2', array('val1'))
        local str_data = 'other data'
        local num_data = 2
        local def_data = 'test'

        local function logic_test(test_table)
            for i, t in ipairs(test_table) do
                assert.message('failed at index: ' .. i).are.equal(t.expected, logic_apply({var = t.params}, t.data))
            end
        end

        describe(
            'given key-valued or arrary data and a key or index (starting from zero)',
            function()
                it(
                    'should return the value of the coresponding key or index',
                    function()
                        local test_table = {
                            {data = kv_data, params = 'attr1', expected = kv_data.attr1},
                            {data = kv_data, params = 'attr2', expected = kv_data.attr2},
                            {data = kv_data, params = 'sub_attr', expected = kv_data.sub_attr},
                            {data = kv_data, params = 'sub_attr.attr1', expected = kv_data.sub_attr.attr1},
                            {data = kv_data, params = array('attr1'), expected = kv_data.attr1},
                            {data = kv_data, params = array('attr2'), expected = kv_data.attr2},
                            {data = kv_data, params = array('sub_attr'), expected = kv_data.sub_attr},
                            {data = kv_data, params = array('sub_attr.attr1'), expected = kv_data.sub_attr.attr1},
                            {data = arr_data, params = 0, expected = arr_data[1]},
                            {data = arr_data, params = 1, expected = arr_data[2]},
                            {data = arr_data, params = 2, expected = arr_data[3]},
                            {data = arr_data, params = array(0), expected = arr_data[1]},
                            {data = arr_data, params = array(1), expected = arr_data[2]},
                            {data = arr_data, params = array(2), expected = arr_data[3]}
                        }
                        logic_test(test_table)
                    end
                )

                it(
                    'should return nil when the key or index are not found in data',
                    function()
                        local test_table = {
                            {data = kv_data, params = 'attr3', expected = nil},
                            {data = kv_data, params = 'attr12', expected = nil},
                            {data = kv_data, params = array('attr3'), expected = nil},
                            {data = kv_data, params = array('attr10'), expected = nil},
                            {data = arr_data, params = 3, expected = nil},
                            {data = arr_data, params = 4, expected = nil},
                            {data = arr_data, params = array(100), expected = nil},
                            {data = arr_data, params = (50), expected = nil}
                        }
                        logic_test(test_table)
                    end
                )
            end
        )

        describe(
            'given data but without key or index',
            function()
                it(
                    'should return the whole data',
                    function()
                        local test_table = {
                            -- "" is the only way to denote the absent of key or index
                            -- using nil will result in the logic becomes an empty table
                            {data = kv_data, params = '', expected = kv_data},
                            {data = arr_data, params = '', expected = arr_data},
                            {data = str_data, params = '', expected = str_data},
                            {data = num_data, params = '', expected = num_data},
                            -- unless ofcourse using nil wrapped in arr_data
                            {data = kv_data, params = array(), expected = kv_data},
                            {data = arr_data, params = array(), expected = arr_data},
                            {data = str_data, params = array(''), expected = str_data},
                            {data = num_data, params = array(''), expected = num_data}
                        }
                        logic_test(test_table)
                    end
                )
            end
        )

        describe(
            'given key-valued or array data, a key or index (starting from zero), and a default value',
            function()
                it(
                    'should return the value of the coresponding key or index',
                    function()
                        local test_table = {
                            {data = kv_data, params = array('attr1', def_data), expected = kv_data.attr1},
                            {data = kv_data, params = array('attr2', def_data), expected = kv_data.attr2},
                            {data = arr_data, params = array(0, def_data), expected = arr_data[1]},
                            {data = arr_data, params = array(1, def_data), expected = arr_data[2]}
                        }
                        logic_test(test_table)
                    end
                )

                it(
                    'should return the default value when the key or index are not found in data',
                    function()
                        local test_table = {
                            {data = kv_data, params = array('attr3', def_data), expected = def_data},
                            {data = kv_data, params = array('attr100', def_data), expected = def_data},
                            {data = arr_data, params = array(3, def_data), expected = def_data},
                            {data = arr_data, params = array(90, def_data), expected = def_data}
                        }
                        logic_test(test_table)
                    end
                )
            end
        )
    end
)

describe(
    "json-logic 'missing' testing",
    function()
        local function logic_test(test_table)
            for i, t in ipairs(test_table) do
                local res = logic_apply({missing = t.params}, t.data)
                assert.message('failed at index: ' .. i).is_true(logic.is_array(res))
                assert.message('failed at index: ' .. i).are.same(t.expected, res)
            end
        end
        local test_table = {
            {data = {a = 'apple', c = 'carrot'}, params = array(), expected = {}},
            {data = {a = 'apple', c = 'carrot'}, params = array('a', 'c'), expected = {}},
            {data = {a = 'apple', c = 'carrot', d = 'dragonfruit'}, params = array('a', 'c'), expected = {}},
            {data = array('apple', 'carrot'), params = array(), expected = {}},
            {data = array('apple', 'carrot'), params = array(0, 1), expected = {}},
            {data = array('apple', 'carrot', 'dragonfruit'), params = array(0, 2), expected = {}},
            {data = {}, params = array('a', 'c'), expected = {'a', 'c'}},
            {data = {a = 'apple'}, params = array('a', 'c'), expected = {'c'}},
            {data = {a = 'apple', c = 'carrot'}, params = array('a', 'b'), expected = {'b'}},
            {data = {a = 'apple'}, params = array('a', 'b', 'c'), expected = {'b', 'c'}},
            {data = {a = 'apple'}, params = array('a', 'b', {'c', 'd'}), expected = {'b', {'c', 'd'}}},
            {data = {a = 'apple'}, params = array('a', {c = 'c'}), expected = {{c = 'c'}}},
            {data = {a = 'apple'}, params = array('a', {c = 'c', d = 'd'}), expected = {{c = 'c', d = 'd'}}},
            {data = array(), params = array(0, 1), expected = {0, 1}},
            {data = array('apple'), params = array(0, 1), expected = {1}},
            {data = array('apple', 'carrot'), params = array(0, 2), expected = {2}},
            {data = array('apple'), params = array(0, 1, 2), expected = {1, 2}},
            {data = array('apple'), params = array(0, 1, array({0, 1})), expected = {1, array({0, 1})}},
            {data = array('apple'), params = array(0, {c = 'c'}), expected = {{c = 'c'}}},
            {data = array('apple'), params = array(0, {c = 'c', d = 'd'}), expected = {{c = 'c', d = 'd'}}}
        }

        describe(
            'given data and a list of keys/indices (maybe empty)',
            function()
                it(
                    'should return list of keys/indices (maybe empty) that are not available (missing) on the given data',
                    function()
                        logic_test(test_table)
                    end
                )
            end
        )
        describe(
            'given data and a list that contain a list of keys/indices (maybe empty)',
            function()
                it(
                    'should return list of keys/indices (maybe empty) that are not available (missing) on the given data',
                    function()
                        for _, t in ipairs(test_table) do
                            t.params = array(t.params)
                        end
                        logic_test(test_table)
                    end
                )
            end
        )
    end
)

describe(
    "json-logic 'missing-some' test",
    function()
        local function logic_test(test_table)
            for i, t in ipairs(test_table) do
                local res = logic_apply({missing_some = t.params}, t.data)
                assert.message('failed at index: ' .. i).is_true(logic.is_array(res))
                assert.message('failed at index: ' .. i).are.same(t.expected, res)
            end
        end

        describe(
            'given data, a list of keys/indices (maybe empty), and minimum number of keys/indices required',
            function()
                it(
                    'should return empty array if minimum number of keys/indices met',
                    function()
                        local test_table = {
                            {data = {}, params = array(0, array('a', 'b', 'c')), expected = array()},
                            {data = {a = 'apple'}, params = array(1, array()), expected = array()},
                            {data = {a = 'apple'}, params = array(1, array('a', 'b', 'c', 'd')), expected = array()},
                            {
                                data = {a = 'apple', c = 'carrot'},
                                params = array(2, array('a', 'b', 'c', 'd')),
                                expected = array()
                            },
                            {
                                data = {a = 'apple', sub = {a = 'apple', b = 'berry'}},
                                params = array(3, array('a', 'sub.a', 'sub.b')),
                                expected = array()
                            }
                        }
                        logic_test(test_table)
                        -- do test
                    end
                )

                it(
                    'should return list of missing keys/indices if requirement is not met',
                    function()
                        local test_table = {
                            {
                                data = {a = 'apple', c = 'carrot'},
                                params = array(3, array('a', 'b', 'c', 'd')),
                                expected = array('b', 'd')
                            },
                            {
                                data = {},
                                params = array(2, array('a', 'b', 'c', 'd')),
                                expected = array('a', 'b', 'c', 'd')
                            },
                            {
                                data = {a = 'apple'},
                                params = array(2, array('a', 'b', 'c', 'd')),
                                expected = array('b', 'c', 'd')
                            }
                        }
                        logic_test(test_table)
                    end
                )
            end
        )
    end
)

describe(
    "json-logic 'if' test",
    function()
        local truthee = {}
        local falsee = {}
        assert.are_not.equals(truthee, falsee)

        local function logic_test(test_table)
            for i, t in ipairs(test_table) do
                local res = logic_apply(logic.new_logic('if', unpack(t.params)), t.data)
                assert.message('failed at index: ' .. i).are.equal(t.expected, res)
            end
        end
        describe(
            'given array containing condition and two values ',
            function()
                it(
                    'should return the first value when condition true',
                    function()
                        local test_table = {
                            {params = array(true, 'true', 'false'), expected = 'true'},
                            {params = array(true, truthee, falsee), expected = truthee}
                        }
                        logic_test(test_table)
                    end
                )
                it(
                    'should return the second value when condition false',
                    function()
                        local test_table = {
                            {params = array(false, 'true', 'false'), expected = 'false'},
                            {params = array(false, truthee, falsee), expected = falsee}
                        }
                        logic_test(test_table)
                    end
                )
            end
        )

        describe(
            'given falsy-javascript value',
            function()
                -- https://developer.mozilla.org/en-US/docs/Glossary/Falsy
                it(
                    'should treat it as false condition ',
                    function()
                        local test_table = {
                            {params = array(false, truthee, falsee), expected = falsee},
                            {params = array(nil, truthee, falsee), expected = falsee},
                            {params = array('', truthee, falsee), expected = falsee},
                            {params = array('', truthee, falsee), expected = falsee},
                            {params = array(undefined, truthee, falsee), expected = falsee},
                            {params = array(0, truthee, falsee), expected = falsee},
                            {params = array(0 / 0, truthee, falsee), expected = falsee}
                        }
                        logic_test(test_table)
                    end
                )
            end
        )

        describe(
            'given truthy-javascript value',
            function()
                -- https://developer.mozilla.org/en-US/docs/Glossary/Truthy
                it(
                    'should treat it as false condition ',
                    function()
                        local test_table = {
                            {params = array(true, truthee, falsee), expected = truthee},
                            {params = array({}, truthee, falsee), expected = truthee},
                            {params = array(array(), truthee, falsee), expected = truthee},
                            {params = array(42, truthee, falsee), expected = truthee},
                            {params = array('foo', truthee, falsee), expected = truthee},
                            {params = array(-42, truthee, falsee), expected = truthee},
                            {params = array(1 / 0, truthee, falsee), expected = truthee},
                            {params = array(-1 / 0, truthee, falsee), expected = truthee}
                        }
                        logic_test(test_table)
                    end
                )
            end
        )

        describe(
            'given more than one actions',
            function()
                it(
                    'should return values next to the first a true condition',
                    function()
                        -- do test
                        local test_table = {
                            {params = array(false, 'false', true, truthee, falsee), expected = truthee},
                            {
                                data = nil,
                                params = array(false, 'false', false, falsee, true, truthee, falsee),
                                expected = truthee
                            },
                            {
                                data = nil,
                                params = array(false, 'false', true, truthee, true, 'true', falsee),
                                expected = truthee
                            }
                        }
                        logic_test(test_table)
                    end
                )
                it(
                    'should return the last values when no true condition',
                    function()
                        local test_table = {
                            {params = array(false, 'false', false, falsee, truthee), expected = truthee},
                            {
                                params = array(false, 'false', false, falsee, false, falsee, truthee),
                                expected = truthee
                            },
                            {
                                params = array(
                                    false,
                                    falsee,
                                    nil,
                                    falsee,
                                    0,
                                    falsee,
                                    '',
                                    falsee,
                                    0 / 0,
                                    falsee,
                                    undefined,
                                    falsee,
                                    truthee
                                ),
                                expected = truthee
                            }
                        }
                        logic_test(test_table)
                    end
                )
            end
        )
        describe(
            'given not enough values',
            function()
                it(
                    'should return nil when no values are associated with matching condition',
                    function()
                        local test_table = {
                            {params = array(false, 'false'), expected = nil},
                            {params = array(false, 'false', false, falsee), expected = nil},
                            {params = array(true), expected = nil},
                            {params = array(false), expected = nil}
                        }
                        logic_test(test_table)
                    end
                )
            end
        )
    end
)

describe(
    "json-logic 'and' testing",
    function()
        local truthee = {}
        local function logic_test(test_table)
            for i, t in ipairs(test_table) do
                local res = logic_apply(logic.new_logic('and', unpack(t.params)), t.data)
                assert.message('failed at index: ' .. i).are.equal(t.expected, res)
            end
        end
        describe(
            'given a list of parameters',
            function()
                it(
                    'should return the first falsy parameter or the last one',
                    function()
                        local test_table = {
                            {params = array(), expected = nil},
                            {params = array(true), expected = true},
                            {params = array(false), expected = false},
                            {params = array(true, true), expected = true},
                            {params = array(true, false), expected = false},
                            {params = array(false, true), expected = false},
                            {params = array(false, false), expected = false},
                            {params = array(true, 1, '0'), expected = '0'},
                            {params = array(true, {}, array(), truthee), expected = truthee},
                            {params = array(true, '1', 1, false), expected = false},
                            {params = array('', true, true), expected = ''},
                            {params = array(true, '', true), expected = ''},
                            {params = array(true, true, 0), expected = 0},
                            {params = array(true, nil, 0), expected = nil},
                            {params = array(undefined, nil, 0), expected = undefined}
                        }
                        logic_test(test_table)
                    end
                )
            end
        )
    end
)

describe(
    "json-logic 'or' testing",
    function()
        local truthee = {}
        local function logic_test(test_table)
            for i, t in ipairs(test_table) do
                local res = logic_apply(logic.new_logic('or', unpack(t.params)), t.data)
                assert.message('failed at index: ' .. i).are.equal(t.expected, res)
            end
        end
        describe(
            'given a list of parameters',
            function()
                it(
                    'should return the first truthy parameter or the last one',
                    function()
                        local test_table = {
                            {params = array(), expected = nil},
                            {params = array(true), expected = true},
                            {params = array(false), expected = false},
                            {params = array(true, true), expected = true},
                            {params = array(true, false), expected = true},
                            {params = array(false, true), expected = true},
                            {params = array(false, false), expected = false},
                            {params = array(true, 1, '0'), expected = true},
                            {params = array(truthee, true, {}, array()), expected = truthee},
                            {params = array('1', 1, true, false), expected = '1'},
                            {params = array(false, 0, '', 0), expected = 0},
                            {params = array(false, 0, undefined, ''), expected = ''},
                            {params = array(false, 0, 0 / 0, ''), expected = ''}
                        }
                        logic_test(test_table)
                    end
                )
            end
        )
    end
)

describe(
    "json-logic 'filter' test",
    function()
        local function logic_test(test_table)
            for i, t in ipairs(test_table) do
                local res = logic_apply({filter = t.params}, t.data)
                assert.message('failed at index: ' .. i).are.same(t.expected, res)
            end
        end
        describe(
            'given an array and sub logic',
            function()
                it(
                    "should return array's element which evaluated as truthy by the sublogic",
                    function()
                        local test_table = {
                            {
                                params = array(array(1, 2, 3, 4, 5), logic.new_logic('%', {var = ''}, 2)),
                                expected = {1, 3, 5}
                            },
                            {
                                params = array(array(1, 2, 3, 4, 5), logic.new_logic('-', {var = ''}, 2)),
                                expected = {1, 3, 4, 5}
                            },
                            {
                                params = array(array(1, 2, 3, 4, 5), true),
                                expected = {1, 2, 3, 4, 5}
                            },
                            {
                                params = array(array(), logic.new_logic('-', {var = ''}, 2)),
                                expected = {}
                            },
                            {
                                params = array(array(), logic.new_logic()),
                                expected = {}
                            },
                            {
                                params = array(nil, logic.new_logic()),
                                expected = nil
                            },
                            {
                                params = array(nil, nil),
                                expected = nil
                            }
                        }
                        logic_test(test_table)
                        -- do test
                    end
                )
                -- do test
            end
        )
    end
)

describe(
    "json-logic 'map' test",
    function()
        local function logic_test(test_table)
            for i, t in ipairs(test_table) do
                local res = logic_apply({map = t.params}, t.data)
                assert.message('failed at index: ' .. i).are.same(t.expected, res)
            end
        end
        describe(
            'given an array and sub logic',
            function()
                it(
                    'should return new array containing the result of each previous item applied to the sub logic',
                    function()
                        local test_table = {
                            {
                                params = array(array(1, 2, 3, 4, 5), logic.new_logic('*', {var = ''}, 2)),
                                expected = array(2, 4, 6, 8, 10)
                            },
                            {
                                params = array({1, 2, 3, 4, 5}, logic.new_logic('*', {var = ''}, 2)),
                                expected = array(2, 4, 6, 8, 10)
                            },
                            {
                                params = array(array(), logic.new_logic('*', {var = ''}, 2)),
                                expected = array()
                            },
                            {
                                params = array(nil, logic.new_logic('*', {var = ''}, 2)),
                                expected = nil
                            },
                            {
                                params = array(nil, nil),
                                expected = nil
                            }
                        }
                        logic_test(test_table)
                    end
                )
            end
        )
    end
)

describe(
    "json-logic 'reduce' test",
    function()
        local function logic_test(test_table)
            for i, t in ipairs(test_table) do
                local res = logic_apply({reduce = t.params}, t.data)
                assert.message('failed at index: ' .. i).are.same(t.expected, res)
            end
        end
        describe(
            'given an array and sub logic',
            function()
                it(
                    'should combine all the array element into single element using sub logic',
                    function()
                        local test_table = {
                            {
                                params = array(
                                    array(1, 2, 3, 4, 5),
                                    logic.new_logic('+', {var = 'current'}, {var = 'accumulator'})
                                ),
                                expected = 15
                            },
                            {
                                params = array(
                                    array(1, 2, 3, 4, 5),
                                    logic.new_logic('*', {var = 'current'}, {var = 'accumulator'})
                                ),
                                expected = 120
                            },
                            {
                                params = array(
                                    array(1, 2, 3, 4, 5),
                                    logic.new_logic('+', {var = 'current'}, {var = 'accumulator'}),
                                    10
                                ),
                                expected = 25
                            },
                            {
                                params = array(array(1, 2, 3, 4, 5), logic.new_logic(), 10),
                                expected = {}
                            },
                            {
                                params = array(array(), logic.new_logic('+', {var = 'current'}, {var = 'accumulator'})),
                                expected = nil
                            },
                            {
                                params = array(nil, logic.new_logic('+', {var = 'current'}, {var = 'accumulator'})),
                                expected = nil
                            },
                            {
                                params = array(nil, nil),
                                expected = nil
                            },
                            {
                                params = array(nil, logic.new_logic('+', {var = 'current'}, {var = 'accumulator'}), 0),
                                expected = 0
                            }
                        }
                        logic_test(test_table)
                    end
                )
            end
        )
    end
)

describe(
    "json-logic 'all' test",
    function()
        local function logic_test(test_table)
            for i, t in ipairs(test_table) do
                local res = logic_apply({all = t.params}, t.data)
                assert.message('failed at index: ' .. i).are.same(t.expected, res)
            end
        end
        describe(
            'given an array and sub logic',
            function()
                it(
                    'should return wether all of the array element evaluated to true by the sub logic',
                    function()
                        -- do test
                        local test_table = {
                            {params = array(array(1, 2, 3, 4, 5), logic.new_logic('>', {var = ''}, 0)), expected = true},
                            {
                                params = array(array(1, 2, 3, 4, 5), logic.new_logic('==', {var = ''}, 2)),
                                expected = false
                            },
                            {params = array(array(1, 2, 3, 4, 5), logic.new_logic()), expected = true},
                            {params = array(array(), logic.new_logic('==', {var = ''}, 2)), expected = nil},
                            {params = array(nil, logic.new_logic('==', {var = ''}, 2)), expected = nil},
                            {params = array(nil, nil), expected = nil}
                        }
                        logic_test(test_table)
                    end
                )
            end
        )
    end
)
describe(
    "json-logic 'some' test",
    function()
        local function logic_test(test_table)
            for i, t in ipairs(test_table) do
                local res = logic_apply({some = t.params}, t.data)
                assert.message('failed at index: ' .. i).are.same(t.expected, res)
            end
        end
        describe(
            'given an array and sub logic',
            function()
                it(
                    'should return wether some of the array element evaluated to true by the sub logic',
                    function()
                        -- do test
                        local test_table = {
                            {params = array(array(1, 2, 3, 4, 5), logic.new_logic('>', {var = ''}, 0)), expected = true},
                            {
                                params = array(array(1, 2, 3, 4, 5), logic.new_logic('<', {var = ''}, 0)),
                                expected = false
                            },
                            {
                                params = array(array(1, 2, 3, 4, 5), logic.new_logic('==', {var = ''}, 2)),
                                expected = true
                            },
                            {params = array(array(1, 2, 3, 4, 5), logic.new_logic()), expected = true},
                            {params = array(array(), logic.new_logic('==', {var = ''}, 2)), expected = nil},
                            {params = array(nil, logic.new_logic('==', {var = ''}, 2)), expected = nil},
                            {params = array(nil, nil), expected = nil}
                        }
                        logic_test(test_table)
                    end
                )
            end
        )
    end
)

describe(
    "json-logic 'none' test",
    function()
        local function logic_test(test_table)
            for i, t in ipairs(test_table) do
                local res = logic_apply({none = t.params}, t.data)
                assert.message('failed at index: ' .. i).are.same(t.expected, res)
            end
        end
        describe(
            'given an array and sub logic',
            function()
                it(
                    'should return wether none of the array element evaluated to true by the sub logic',
                    function()
                        -- do test
                        local test_table = {
                            {
                                params = array(array(1, 2, 3, 4, 5), logic.new_logic('>', {var = ''}, 0)),
                                expected = false
                            },
                            {params = array(array(1, 2, 3, 4, 5), logic.new_logic('<', {var = ''}, 0)), expected = true},
                            {
                                params = array(array(1, 2, 3, 4, 5), logic.new_logic('==', {var = ''}, 2)),
                                expected = false
                            },
                            {params = array(array(1, 2, 3, 4, 5), logic.new_logic()), expected = false},
                            {params = array(array(), logic.new_logic('==', {var = ''}, 2)), expected = nil},
                            {params = array(nil, logic.new_logic('==', {var = ''}, 2)), expected = nil},
                            {params = array(nil, nil), expected = nil}
                        }
                        logic_test(test_table)
                    end
                )
            end
        )
    end
)

describe(
    "json-logic 'merge' function",
    function()
        local function logic_test(test_table)
            for i, t in ipairs(test_table) do
                local res = logic_apply({merge = t.params}, t.data)
                assert.message('failed at index: ' .. i).are.same(t.expected, res)
            end
        end
        describe(
            'given array of items',
            function()
                it(
                    'should return a single array containing all of the given items',
                    function()
                        local test_table = {
                            {params = array(1, 2, 3, 4, 5, 6), expected = array(1, 2, 3, 4, 5, 6)},
                            {
                                params = array('1', '2', '3', '4', '5', '6'),
                                expected = array('1', '2', '3', '4', '5', '6')
                            },
                            {params = array(1, '2', 3, '4', 5, '6'), expected = array(1, '2', 3, '4', 5, '6')},
                            {params = array(), expected = array()}
                        }
                        logic_test(test_table)
                    end
                )
            end
        )
        describe(
            'given array that contains another array',
            function()
                it(
                    'should return a single array by unpacking first level array if any ',
                    function()
                        local test_table = {
                            {params = array(array(1, 2, 3), array(5, 6, 7)), expected = array(1, 2, 3, 5, 6, 7)},
                            {params = array(array(1, 2, 3), 4, array(5, 6, 7)), expected = array(1, 2, 3, 4, 5, 6, 7)},
                            {
                                params = array(array(1, 2, 3), array(4, 5, 6), array(7, 8, 9)),
                                expected = array(1, 2, 3, 4, 5, 6, 7, 8, 9)
                            },
                            {
                                params = array(array('1', '2', '3'), array('4', '5', '6'), array(7, 8, 9)),
                                expected = array('1', '2', '3', '4', '5', '6', 7, 8, 9)
                            },
                            {
                                params = array(
                                    array(1, 2, 3),
                                    array(4, 5, 6),
                                    array(7, 8, 9),
                                    array(10, array(1, 2, 3), 4, 5, 6)
                                ),
                                expected = array(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, array(1, 2, 3), 4, 5, 6)
                            },
                            {params = array(array(), array(), array(array())), expected = array(array())}
                        }
                        logic_test(test_table)
                    end
                )
            end
        )
    end
)

describe(
    "json-logic 'cat' test",
    function()
        local function logic_test(test_table)
            for i, t in ipairs(test_table) do
                local res = logic_apply({cat = t.params}, t.data)
                assert.message('failed at index: ' .. i).are.equal(t.expected, res)
            end
        end
        describe(
            'given an array of string',
            function()
                it(
                    'should join the element into one string',
                    function()
                        local test_table = {
                            {params = array('I Love', ' Apple ', 'Pie'), expected = 'I Love Apple Pie'},
                            {params = array('I Love'), expected = 'I Love'},
                            {params = array(), expected = ''}
                        }
                        logic_test(test_table)
                    end
                )
                -- do test
            end
        )
    end
)

describe(
    "json-logic 'in' test",
    function()
        local function logic_test(test_table)
            for i, t in ipairs(test_table) do
                local res = logic_apply(logic.new_logic('in', unpack(t.params)), t.data)
                assert.message('failed at index: ' .. i).are.equal(t.expected, res)
            end
        end
        describe(
            'given two strings',
            function()
                it(
                    'should return wether the second string contains the first one',
                    function()
                        local test_table = {
                            {params = array('Spring', 'Springfield'), expected = true},
                            {params = array('Sprung', 'Springfield'), expected = false},
                            {params = array('', 'Springfield'), expected = true}
                        }
                        logic_test(test_table)
                    end
                )
            end
        )
        describe(
            'given array as the second argument',
            function()
                it(
                    'should return wether the array contains the first argument',
                    function()
                        local test_table = {
                            {params = array('Spring', array('Spring', 'Field', 'City')), expected = true},
                            {params = array(1, array(1, 2, 3, 4, 5, 6, 7)), expected = true},
                            {params = array('spring', array('Spring', 'Field', 'City')), expected = false},
                            {params = array(0, array(1, 2, 3, 4, 5, 6, 7)), expected = false},
                            {params = array('Spring', array()), expected = false},
                            {params = array(1, array()), expected = false}
                        }
                        logic_test(test_table)
                    end
                )
            end
        )
    end
)

describe(
    "json-logic 'substr' test",
    function()
        local function logic_test(test_table)
            for i, t in ipairs(test_table) do
                local res = logic_apply({substr = t.params}, t.data)
                assert.message('failed at index: ' .. i).are.equal(t.expected, res)
            end
        end
        describe(
            'given a string and a positive position',
            function()
                it(
                    'should return sub-string begining at that position',
                    function()
                        local test_table = {
                            {params = array('jsonlogic', 4), expected = 'logic'},
                            {params = array('jsonlogic', 0), expected = 'jsonlogic'},
                            {params = array('json', 1), expected = 'son'},
                            {params = array('json', 4), expected = ''}
                        }
                        logic_test(test_table)
                    end
                )
            end
        )
        describe(
            'given a string and a negative position',
            function()
                it(
                    'should return sub-string begining at that position',
                    function()
                        local test_table = {
                            {params = array('jsonlogic', -5), expected = 'logic'},
                            {params = array('jsonlogic', -1), expected = 'c'},
                            {params = array('jsonlogic-test', -9), expected = 'ogic-test'},
                            {params = array('jsonlogic-test', -20), expected = 'jsonlogic-test'}
                        }
                        logic_test(test_table)
                    end
                )
            end
        )
        describe(
            'given a string and two positions',
            function()
                it(
                    'should return sub-string between the positions',
                    function()
                        local test_table = {
                            {params = array('jsonlogic', 2, 3), expected = 'onl'},
                            {params = array('jsonlogic', 1, 10), expected = 'sonlogic'},
                            {params = array('jsonlogic', 4, -2), expected = 'log'},
                            {params = array('jsonlogic', 5, -6), expected = ''},
                            {params = array('jsonlogic', 4, -20), expected = ''},
                        }
                        logic_test(test_table)
                    end
                )
            end
        )
    end
)

describe(
    "json-logic 'join' test",
    function()
        local function logic_test(test_table)
            for i, t in ipairs(test_table) do
                local res = logic_apply({join = t.params}, t.data)
                assert.message('failed at index: ' .. i).are.same(t.expected, res)
            end
        end
        describe(
            'given an array and separator',
            function()
                it(
                    'should join all the elements separated by separator into strings',
                    function()
                        local test_table = {
                            {params = array(",", array('')), expected = ""},
                            {params = array(",", array('Fire')), expected = "Fire"},
                            {params = array(",", array('Fire', 'Wind', 'Rain')), expected = "Fire,Wind,Rain"},
                            {params = array(",", array(1, 2, 3)), expected = "1,2,3"},
                            {params = array("-", array('Fire', 'Wind', 'Rain')), expected = "Fire-Wind-Rain"},
                            {params = array("-", array(1, 2, 3)), expected = "1-2-3"},
                            {params = array("-", array(1, 2, 3, array(4,5,6), 7, 8)), expected = "1-2-3-4,5,6-7-8"},
                            {params = array("-", array(1, 2, 3, array(4,5,6,array(7,8,9),10,11))), expected = "1-2-3-4,5,6,7,8,9,10,11"},
                            {params = array("-", array(1, 2, 3, array(4,5,6,array(7,8,9, array(10,11))),12,13)), expected = "1-2-3-4,5,6,7,8,9,10,11-12-13"},
                            {params = array("", array('Fire', 'Wind', 'Rain')), expected = "Fire,Wind,Rain"},
                            {params = array(nil, array('Fire', 'Wind', 'Rain')), expected = "Fire,Wind,Rain"},
                            {params = array(array(1,2,3), array(1, 2, 3)), expected = "11,2,321,2,33"},
                            {params = array(array("a",array("m","n","o"),"z"), array(1, 2, 3)), expected = "1a,m,n,o,z2a,m,n,o,z3"},
                        }
                        logic_test(test_table)
                    end
                )
            end
        )
        describe("given non array", function ()
            it("should return nil", function ()
                local test_table = {
                    {params = array(",", 1), expected = nil},
                    {params = array(",", "{1,2,3}"), expected = nil},
                    {params = array(",", {1,2,3}), expected = nil},
                    {params = array(",", true), expected = nil},
                    {params = array(","), expected = nil},
                    {params = array(), expected = nil},
                }
                logic_test(test_table)
            end)
        end)
    end
)

describe("json-logic 'length' test", function ()
    local function logic_test(test_table)
        for i, t in ipairs(test_table) do
            local res = logic_apply({length = t.params}, t.data)
            assert.message('failed at index: ' .. i).are.equal(t.expected, res)
        end
    end
    describe("given table", function ()
        it("should return number of element in the table", function ()
            local test_table = {
                {params = array({}), expected = 0},
                {params = array({1,2,3,4,5}), expected = 5},
                {params = array({1,2,3,4,5,{1,2,3,4,5}}), expected = 6},
                {params = array(array()), expected = 0},
                {params = array(array(1,2,3,4,5, array(1,2,3,4,5))), expected = 6},
            }
            logic_test(test_table)
        end)
    end)
    describe("given string", function ()
        it("should return the length of the string", function ()
            local test_table = {
                {params = array(""), expected = 0},
                {params = array("12345"), expected = 5},
                {params = array("1234567890"), expected = 10},
                {params = "", expected = 0},
                {params = "12345", expected = 5},
                {params = "1234567890", expected = 10},
            }
            logic_test(test_table)
        end)
    end)
    describe("given parameters other than table and string", function ()
        it("should return 0", function ()
            local test_table = {
                {params = array(1), expected = 0},
                {params = array(true), expected = 0},
                {params = 1, expected = 0},
                {params = true, expected = 0},
            }
            logic_test(test_table)
        end)
    end)
end)

describe("json-logic number test", function ()
    local function logic_test( test_table)
        for i, t in ipairs(test_table) do
            local res = logic_apply(logic.new_logic(t.operator, unpack(t.params)), t.data)
            assert.message('failed at index: ' .. i).are.equal(t.expected, res)
        end
    end
    describe("given two or more numbers", function ()
        it("should do the math :)", function ()
            local test_table = {
                {operator = "max", params = array(1,10,3), expected = 10},
                {operator = "min", params = array(-1,15,10), expected = -1},
                {operator = "+", params = array(4,2), expected = 6},
                {operator = "-", params = array(4,2), expected = 2},
                {operator = "*", params = array(4,2), expected = 8},
                {operator = "/", params = array(4,2), expected = 2},
                {operator = "+", params = array(4,2,1,3,5), expected = 15},
                {operator = "*", params = array(2,2,2,2,2), expected = 32},
                {operator = "-", params = array(2), expected = -2},
                {operator = "-", params = array(-2), expected = 2},
                {operator = "+", params = array("3.14"), expected = 3.14},
                {operator = "%", params = array(101,2), expected = 1},
                {operator = ">", params = array(2,1), expected = true},
                {operator = ">", params = array(3,4), expected = false},
                {operator = ">=", params = array(1,1), expected = true},
                {operator = ">=", params = array(-1,1), expected = false},
                {operator = "<", params = array(1,2), expected = true},
                {operator = "<", params = array(3,2), expected = false},
                {operator = "<=", params = array(1,1), expected = true},
                {operator = "<=", params = array(10,1), expected = false},
                {operator = "<", params = array(1,2,3), expected = true},
                {operator = "<", params = array(1,2,1), expected = false},
                {operator = "<", params = array(1,4,3), expected = false},
                {operator = "<", params = array(1,1,3), expected = false},
                {operator = "<=", params = array(1,2,3), expected = true},
                {operator = "<=", params = array(1,1,3), expected = true},
                {operator = "<=", params = array(1,4,3), expected = false},
            }
            logic_test(test_table)
        end)
    end)
    describe("given two or more non numbers", function ()
        it("should convert it to numbers and do the math", function ()
            local test_table = {
                {operator = "max", params = array(array(1),array(array(10)),3), expected = 10},
                {operator = "max", params = array(array(1),array(array("a","b")),3), expected = nil},
                {operator = "max", params = array(array(1),{10},3), expected = nil},
                {operator = "min", params = array(array(1),array(array(10)),3), expected = 1},
                {operator = "min", params = array(array(1),array(array("a","b")),3), expected = nil},
                {operator = "min", params = array(array(1),{10},3), expected = nil},
                {operator = "+", params = array(array(4),"2"), expected = 6},
                {operator = "+", params = array("4",array()), expected = 4},
                {operator = "-", params = array(array("2")), expected = -2},
                {operator = "-", params = array(array("2") , array(1)), expected = 1},
                {operator = "*", params = array(2,array(2),"2",array("2"),array(array(2))), expected = 32},
                {operator = "/", params = array(array("4"),2), expected = 2},
                {operator = "%", params = array(array(101),"2"), expected = 1},
                {operator = ">", params = array("2",array(1)), expected = true},
                {operator = ">", params = array("3","4"), expected = false},
                {operator = ">=", params = array(array(1),array()), expected = true},
                {operator = ">=", params = array("-1",1), expected = false},
                {operator = "<", params = array(array(1),"2"), expected = true},
                {operator = "<", params = array("3",array(array(2))), expected = false},
                {operator = "<=", params = array(array(1),array(1)), expected = true},
                {operator = "<=", params = array("10","1"), expected = false},
                {operator = "<", params = array("1","2",array("3")), expected = true},
                {operator = "<", params = array(array(1),"2",array(1)), expected = false},
                {operator = "<", params = array("1",4,array("3")), expected = false},
                {operator = "<", params = array(1,"1",3), expected = false},
                {operator = "<=", params = array(array(array(1)),2,"3"), expected = true},
                {operator = "<=", params = array(1,array(array("1")),3), expected = true},
                {operator = "<=", params = array(1,array(array(4)),3), expected = false},
            }
            logic_test(test_table)
        end)
    end)
end)

describe("json-logic equality test", function ()
    local function logic_test( test_table)
        for i, t in ipairs(test_table) do
            local res = logic_apply(logic.new_logic(t.operator, unpack(t.params)), t.data)
            assert.message('failed at index: ' .. i).are.equal(t.expected, res)
        end
    end
    describe("given two items", function ()
        it("should return result of loose equality evaluation when using '==' operator", function ()
            local test_table = {
                {operator = "==" , params = array(true, true), expected = true},
                {operator = "==" , params = array(true, false), expected = false},
                {operator = "==" , params = array(true, 1), expected = true},
                {operator = "==" , params = array(true, 0), expected = false},
                {operator = "==" , params = array(true, -1), expected = false},
                {operator = "==" , params = array(true, "true"), expected =false },
                {operator = "==" , params = array(true, "false"), expected =false },
                {operator = "==" , params = array(true, "1"), expected = true},
                {operator = "==" , params = array(true, "0"), expected = false},
                {operator = "==" , params = array(true, "-1"), expected = false},
                {operator = "==" , params = array(true, ""), expected = false},
                {operator = "==" , params = array(true, nil), expected = false},
                {operator = "==" , params = array(true, undefined), expected = false},
                {operator = "==" , params = array(true, 1/0), expected = false},
                {operator = "==" , params = array(true, -1/0), expected = false},
                {operator = "==" , params = array(true, array()), expected = false},
                {operator = "==" , params = array(true, {}), expected = false},
                {operator = "==" , params = array(true, array(array())), expected = false},
                {operator = "==" , params = array(true, array(0)), expected = false},
                {operator = "==" , params = array(true, array(1)), expected = true},
                {operator = "==" , params = array(true, 0/0), expected = false},
                {operator = "==" , params = array(false, true), expected = false},
                {operator = "==" , params = array(false, false), expected = true},
                {operator = "==" , params = array(false, 1), expected = false},
                {operator = "==" , params = array(false, 0), expected = true},
                {operator = "==" , params = array(false, -1), expected = false},
                {operator = "==" , params = array(false, "true"), expected =false },
                {operator = "==" , params = array(false, "false"), expected =false },
                {operator = "==" , params = array(false, "1"), expected = false},
                {operator = "==" , params = array(false, "0"), expected = true},
                {operator = "==" , params = array(false, "-1"), expected = false},
                {operator = "==" , params = array(false, ""), expected = true},
                {operator = "==" , params = array(false, nil), expected = false},
                {operator = "==" , params = array(false, undefined), expected = false},
                {operator = "==" , params = array(false, 1/0), expected = false},
                {operator = "==" , params = array(false, -1/0), expected = false},
                {operator = "==" , params = array(false, array()), expected = true},
                {operator = "==" , params = array(false, {}), expected = false},
                {operator = "==" , params = array(false, array(array())), expected = true},
                {operator = "==" , params = array(false, array(0)), expected = true},
                {operator = "==" , params = array(false, array(1)), expected = false},
                {operator = "==" , params = array(false, 0/0), expected = false},
                {operator = "==" , params = array(1, true), expected = true},
                {operator = "==" , params = array(1, false), expected = false},
                {operator = "==" , params = array(1, 1), expected = true},
                {operator = "==" , params = array(1, 0), expected = false},
                {operator = "==" , params = array(1, -1), expected = false},
                {operator = "==" , params = array(1, "true"), expected =false },
                {operator = "==" , params = array(1, "false"), expected =false },
                {operator = "==" , params = array(1, "1"), expected = true},
                {operator = "==" , params = array(1, "0"), expected = false},
                {operator = "==" , params = array(1, "-1"), expected = false},
                {operator = "==" , params = array(1, ""), expected = false},
                {operator = "==" , params = array(1, nil), expected = false},
                {operator = "==" , params = array(1, undefined), expected = false},
                {operator = "==" , params = array(1, 1/0), expected = false},
                {operator = "==" , params = array(1, -1/0), expected = false},
                {operator = "==" , params = array(1, array()), expected = false},
                {operator = "==" , params = array(1, {}), expected = false},
                {operator = "==" , params = array(1, array(array())), expected = false},
                {operator = "==" , params = array(1, array(0)), expected = false},
                {operator = "==" , params = array(1, array(1)), expected = true},
                {operator = "==" , params = array(1, 0/0), expected = false},
                {operator = "==" , params = array(0, true), expected = false},
                {operator = "==" , params = array(0, false), expected = true},
                {operator = "==" , params = array(0, 1), expected = false},
                {operator = "==" , params = array(0, 0), expected = true},
                {operator = "==" , params = array(0, -1), expected = false},
                {operator = "==" , params = array(0, "true"), expected =false },
                {operator = "==" , params = array(0, "false"), expected =false },
                {operator = "==" , params = array(0, "1"), expected = false},
                {operator = "==" , params = array(0, "0"), expected = true},
                {operator = "==" , params = array(0, "-1"), expected = false},
                {operator = "==" , params = array(0, ""), expected = true},
                {operator = "==" , params = array(0, nil), expected = false},
                {operator = "==" , params = array(0, undefined), expected = false},
                {operator = "==" , params = array(0, 1/0), expected = false},
                {operator = "==" , params = array(0, -1/0), expected = false},
                {operator = "==" , params = array(0, array()), expected = true},
                {operator = "==" , params = array(0, {}), expected = false},
                {operator = "==" , params = array(0, array(array())), expected = true},
                {operator = "==" , params = array(0, array(0)), expected = true},
                {operator = "==" , params = array(0, array(1)), expected = false},
                {operator = "==" , params = array(0, 0/0), expected = false},
                {operator = "==" , params = array(-1, true), expected = false},
                {operator = "==" , params = array(-1, false), expected = false},
                {operator = "==" , params = array(-1, 1), expected = false},
                {operator = "==" , params = array(-1, 0), expected = false},
                {operator = "==" , params = array(-1, -1), expected = true},
                {operator = "==" , params = array(-1, "true"), expected =false },
                {operator = "==" , params = array(-1, "false"), expected =false },
                {operator = "==" , params = array(-1, "1"), expected = false},
                {operator = "==" , params = array(-1, "0"), expected = false},
                {operator = "==" , params = array(-1, "-1"), expected = true},
                {operator = "==" , params = array(-1, ""), expected = false},
                {operator = "==" , params = array(-1, nil), expected = false},
                {operator = "==" , params = array(-1, undefined), expected = false},
                {operator = "==" , params = array(-1, 1/0), expected = false},
                {operator = "==" , params = array(-1, -1/0), expected = false},
                {operator = "==" , params = array(-1, array()), expected = false},
                {operator = "==" , params = array(-1, {}), expected = false},
                {operator = "==" , params = array(-1, array(array())), expected = false},
                {operator = "==" , params = array(-1, array(0)), expected = false},
                {operator = "==" , params = array(-1, array(1)), expected = false},
                {operator = "==" , params = array(-1, 0/0), expected = false},
                {operator = "==" , params = array("true", true), expected = false},
                {operator = "==" , params = array("true", false), expected = false},
                {operator = "==" , params = array("true", 1), expected = false},
                {operator = "==" , params = array("true", 0), expected = false},
                {operator = "==" , params = array("true", -1), expected = false},
                {operator = "==" , params = array("true", "true"), expected =true },
                {operator = "==" , params = array("true", "false"), expected =false },
                {operator = "==" , params = array("true", "1"), expected = false},
                {operator = "==" , params = array("true", "0"), expected = false},
                {operator = "==" , params = array("true", "-1"), expected = false},
                {operator = "==" , params = array("true", ""), expected = false},
                {operator = "==" , params = array("true", nil), expected = false},
                {operator = "==" , params = array("true", undefined), expected = false},
                {operator = "==" , params = array("true", 1/0), expected = false},
                {operator = "==" , params = array("true", -1/0), expected = false},
                {operator = "==" , params = array("true", array()), expected = false},
                {operator = "==" , params = array("true", {}), expected = false},
                {operator = "==" , params = array("true", array(array())), expected = false},
                {operator = "==" , params = array("true", array(0)), expected = false},
                {operator = "==" , params = array("true", array(1)), expected = false},
                {operator = "==" , params = array("true", 0/0), expected = false},
                {operator = "==" , params = array("false", true), expected = false},
                {operator = "==" , params = array("false", false), expected = false},
                {operator = "==" , params = array("false", 1), expected = false},
                {operator = "==" , params = array("false", 0), expected = false},
                {operator = "==" , params = array("false", -1), expected = false},
                {operator = "==" , params = array("false", "true"), expected =false },
                {operator = "==" , params = array("false", "false"), expected =true },
                {operator = "==" , params = array("false", "1"), expected = false},
                {operator = "==" , params = array("false", "0"), expected = false},
                {operator = "==" , params = array("false", "-1"), expected = false},
                {operator = "==" , params = array("false", ""), expected = false},
                {operator = "==" , params = array("false", nil), expected = false},
                {operator = "==" , params = array("false", undefined), expected = false},
                {operator = "==" , params = array("false", 1/0), expected = false},
                {operator = "==" , params = array("false", -1/0), expected = false},
                {operator = "==" , params = array("false", array()), expected = false},
                {operator = "==" , params = array("false", {}), expected = false},
                {operator = "==" , params = array("false", array(array())), expected = false},
                {operator = "==" , params = array("false", array(0)), expected = false},
                {operator = "==" , params = array("false", array(1)), expected = false},
                {operator = "==" , params = array("false", 0/0), expected = false},
                {operator = "==" , params = array("1", true), expected = true},
                {operator = "==" , params = array("1", false), expected = false},
                {operator = "==" , params = array("1", 1), expected = true},
                {operator = "==" , params = array("1", 0), expected = false},
                {operator = "==" , params = array("1", -1), expected = false},
                {operator = "==" , params = array("1", "true"), expected =false },
                {operator = "==" , params = array("1", "false"), expected =false },
                {operator = "==" , params = array("1", "1"), expected = true},
                {operator = "==" , params = array("1", "0"), expected = false},
                {operator = "==" , params = array("1", "-1"), expected = false},
                {operator = "==" , params = array("1", ""), expected = false},
                {operator = "==" , params = array("1", nil), expected = false},
                {operator = "==" , params = array("1", undefined), expected = false},
                {operator = "==" , params = array("1", 1/0), expected = false},
                {operator = "==" , params = array("1", -1/0), expected = false},
                {operator = "==" , params = array("1", array()), expected = false},
                {operator = "==" , params = array("1", {}), expected = false},
                {operator = "==" , params = array("1", array(array())), expected = false},
                {operator = "==" , params = array("1", array(0)), expected = false},
                {operator = "==" , params = array("1", array(1)), expected = true},
                {operator = "==" , params = array("1", 0/0), expected = false},
                {operator = "==" , params = array("0", true), expected = false},
                {operator = "==" , params = array("0", false), expected = true},
                {operator = "==" , params = array("0", 1), expected = false},
                {operator = "==" , params = array("0", 0), expected = true},
                {operator = "==" , params = array("0", -1), expected = false},
                {operator = "==" , params = array("0", "true"), expected =false },
                {operator = "==" , params = array("0", "false"), expected =false },
                {operator = "==" , params = array("0", "1"), expected = false},
                {operator = "==" , params = array("0", "0"), expected = true},
                {operator = "==" , params = array("0", "-1"), expected = false},
                {operator = "==" , params = array("0", ""), expected = false},
                {operator = "==" , params = array("0", nil), expected = false},
                {operator = "==" , params = array("0", undefined), expected = false},
                {operator = "==" , params = array("0", 1/0), expected = false},
                {operator = "==" , params = array("0", -1/0), expected = false},
                {operator = "==" , params = array("0", array()), expected = false},
                {operator = "==" , params = array("0", {}), expected = false},
                {operator = "==" , params = array("0", array(array())), expected = false},
                {operator = "==" , params = array("0", array(0)), expected = true},
                {operator = "==" , params = array("0", array(1)), expected = false},
                {operator = "==" , params = array("0", 0/0), expected = false},
                {operator = "==" , params = array("-1", true), expected = false},
                {operator = "==" , params = array("-1", false), expected = false},
                {operator = "==" , params = array("-1", 1), expected = false},
                {operator = "==" , params = array("-1", 0), expected = false},
                {operator = "==" , params = array("-1", -1), expected = true},
                {operator = "==" , params = array("-1", "true"), expected =false },
                {operator = "==" , params = array("-1", "false"), expected =false },
                {operator = "==" , params = array("-1", "1"), expected = false},
                {operator = "==" , params = array("-1", "0"), expected = false},
                {operator = "==" , params = array("-1", "-1"), expected = true},
                {operator = "==" , params = array("-1", ""), expected = false},
                {operator = "==" , params = array("-1", nil), expected = false},
                {operator = "==" , params = array("-1", undefined), expected = false},
                {operator = "==" , params = array("-1", 1/0), expected = false},
                {operator = "==" , params = array("-1", -1/0), expected = false},
                {operator = "==" , params = array("-1", array()), expected = false},
                {operator = "==" , params = array("-1", {}), expected = false},
                {operator = "==" , params = array("-1", array(array())), expected = false},
                {operator = "==" , params = array("-1", array(0)), expected = false},
                {operator = "==" , params = array("-1", array(1)), expected = false},
                {operator = "==" , params = array("-1", 0/0), expected = false},
                {operator = "==" , params = array("", true), expected = false},
                {operator = "==" , params = array("", false), expected = true},
                {operator = "==" , params = array("", 1), expected = false},
                {operator = "==" , params = array("", 0), expected = true},
                {operator = "==" , params = array("", -1), expected = false},
                {operator = "==" , params = array("", "true"), expected =false },
                {operator = "==" , params = array("", "false"), expected =false },
                {operator = "==" , params = array("", "1"), expected = false},
                {operator = "==" , params = array("", "0"), expected = false},
                {operator = "==" , params = array("", "-1"), expected = false},
                {operator = "==" , params = array("", ""), expected = true},
                {operator = "==" , params = array("", nil), expected = false},
                {operator = "==" , params = array("", undefined), expected = false},
                {operator = "==" , params = array("", 1/0), expected = false},
                {operator = "==" , params = array("", -1/0), expected = false},
                {operator = "==" , params = array("", array()), expected = true},
                {operator = "==" , params = array("", {}), expected = false},
                {operator = "==" , params = array("", array(array())), expected = true},
                {operator = "==" , params = array("", array(0)), expected = false},
                {operator = "==" , params = array("", array(1)), expected = false},
                {operator = "==" , params = array("", 0/0), expected = false},
                {operator = "==" , params = array(nil, true), expected = false},
                {operator = "==" , params = array(nil, false), expected = false},
                {operator = "==" , params = array(nil, 1), expected = false},
                {operator = "==" , params = array(nil, 0), expected = false},
                {operator = "==" , params = array(nil, -1), expected = false},
                {operator = "==" , params = array(nil, "true"), expected =false },
                {operator = "==" , params = array(nil, "false"), expected =false },
                {operator = "==" , params = array(nil, "1"), expected = false},
                {operator = "==" , params = array(nil, "0"), expected = false},
                {operator = "==" , params = array(nil, "-1"), expected = false},
                {operator = "==" , params = array(nil, ""), expected = false},
                {operator = "==" , params = array(nil, nil), expected = true},
                {operator = "==" , params = array(nil, undefined), expected = true},
                {operator = "==" , params = array(nil, 1/0), expected = false},
                {operator = "==" , params = array(nil, -1/0), expected = false},
                {operator = "==" , params = array(nil, array()), expected = false},
                {operator = "==" , params = array(nil, {}), expected = false},
                {operator = "==" , params = array(nil, array(array())), expected = false},
                {operator = "==" , params = array(nil, array(0)), expected = false},
                {operator = "==" , params = array(nil, array(1)), expected = false},
                {operator = "==" , params = array(nil, 0/0), expected = false},
                {operator = "==" , params = array(undefined, true), expected = false},
                {operator = "==" , params = array(undefined, false), expected = false},
                {operator = "==" , params = array(undefined, 1), expected = false},
                {operator = "==" , params = array(undefined, 0), expected = false},
                {operator = "==" , params = array(undefined, -1), expected = false},
                {operator = "==" , params = array(undefined, "true"), expected =false },
                {operator = "==" , params = array(undefined, "false"), expected =false },
                {operator = "==" , params = array(undefined, "1"), expected = false},
                {operator = "==" , params = array(undefined, "0"), expected = false},
                {operator = "==" , params = array(undefined, "-1"), expected = false},
                {operator = "==" , params = array(undefined, ""), expected = false},
                {operator = "==" , params = array(undefined, nil), expected = true},
                {operator = "==" , params = array(undefined, undefined), expected = true},
                {operator = "==" , params = array(undefined, 1/0), expected = false},
                {operator = "==" , params = array(undefined, -1/0), expected = false},
                {operator = "==" , params = array(undefined, array()), expected = false},
                {operator = "==" , params = array(undefined, {}), expected = false},
                {operator = "==" , params = array(undefined, array(array())), expected = false},
                {operator = "==" , params = array(undefined, array(0)), expected = false},
                {operator = "==" , params = array(undefined, array(1)), expected = false},
                {operator = "==" , params = array(undefined, 0/0), expected = false},
                {operator = "==" , params = array(1/0, true), expected = false},
                {operator = "==" , params = array(1/0, false), expected = false},
                {operator = "==" , params = array(1/0, 1), expected = false},
                {operator = "==" , params = array(1/0, 0), expected = false},
                {operator = "==" , params = array(1/0, -1), expected = false},
                {operator = "==" , params = array(1/0, "true"), expected =false },
                {operator = "==" , params = array(1/0, "false"), expected =false },
                {operator = "==" , params = array(1/0, "1"), expected = false},
                {operator = "==" , params = array(1/0, "0"), expected = false},
                {operator = "==" , params = array(1/0, "-1"), expected = false},
                {operator = "==" , params = array(1/0, ""), expected = false},
                {operator = "==" , params = array(1/0, nil), expected = false},
                {operator = "==" , params = array(1/0, undefined), expected = false},
                {operator = "==" , params = array(1/0, 1/0), expected = true},
                {operator = "==" , params = array(1/0, -1/0), expected = false},
                {operator = "==" , params = array(1/0, array()), expected = false},
                {operator = "==" , params = array(1/0, {}), expected = false},
                {operator = "==" , params = array(1/0, array(array())), expected = false},
                {operator = "==" , params = array(1/0, array(0)), expected = false},
                {operator = "==" , params = array(1/0, array(1)), expected = false},
                {operator = "==" , params = array(1/0, 0/0), expected = false},
                {operator = "==" , params = array(-1/0, true), expected = false},
                {operator = "==" , params = array(-1/0, false), expected = false},
                {operator = "==" , params = array(-1/0, 1), expected = false},
                {operator = "==" , params = array(-1/0, 0), expected = false},
                {operator = "==" , params = array(-1/0, -1), expected = false},
                {operator = "==" , params = array(-1/0, "true"), expected =false },
                {operator = "==" , params = array(-1/0, "false"), expected =false },
                {operator = "==" , params = array(-1/0, "1"), expected = false},
                {operator = "==" , params = array(-1/0, "0"), expected = false},
                {operator = "==" , params = array(-1/0, "-1"), expected = false},
                {operator = "==" , params = array(-1/0, ""), expected = false},
                {operator = "==" , params = array(-1/0, nil), expected = false},
                {operator = "==" , params = array(-1/0, undefined), expected = false},
                {operator = "==" , params = array(-1/0, 1/0), expected = false},
                {operator = "==" , params = array(-1/0, -1/0), expected = true},
                {operator = "==" , params = array(-1/0, array()), expected = false},
                {operator = "==" , params = array(-1/0, {}), expected = false},
                {operator = "==" , params = array(-1/0, array(array())), expected = false},
                {operator = "==" , params = array(-1/0, array(0)), expected = false},
                {operator = "==" , params = array(-1/0, array(1)), expected = false},
                {operator = "==" , params = array(-1/0, 0/0), expected = false},
                {operator = "==" , params = array(array(), true), expected = false},
                {operator = "==" , params = array(array(), false), expected = true},
                {operator = "==" , params = array(array(), 1), expected = false},
                {operator = "==" , params = array(array(), 0), expected = true},
                {operator = "==" , params = array(array(), -1), expected = false},
                {operator = "==" , params = array(array(), "true"), expected =false },
                {operator = "==" , params = array(array(), "false"), expected =false },
                {operator = "==" , params = array(array(), "1"), expected = false},
                {operator = "==" , params = array(array(), "0"), expected = false},
                {operator = "==" , params = array(array(), "-1"), expected = false},
                {operator = "==" , params = array(array(), ""), expected = true},
                {operator = "==" , params = array(array(), nil), expected = false},
                {operator = "==" , params = array(array(), undefined), expected = false},
                {operator = "==" , params = array(array(), 1/0), expected = false},
                {operator = "==" , params = array(array(), -1/0), expected = false},
                {operator = "==" , params = array(array(), array()), expected = false},
                {operator = "==" , params = array(array(), {}), expected = false},
                {operator = "==" , params = array(array(), array(array())), expected = false},
                {operator = "==" , params = array(array(), array(0)), expected = false},
                {operator = "==" , params = array(array(), array(1)), expected = false},
                {operator = "==" , params = array(array(), 0/0), expected = false},
                {operator = "==" , params = array({}, true), expected = false},
                {operator = "==" , params = array({}, false), expected = false},
                {operator = "==" , params = array({}, 1), expected = false},
                {operator = "==" , params = array({}, 0), expected = false},
                {operator = "==" , params = array({}, -1), expected = false},
                {operator = "==" , params = array({}, "true"), expected =false },
                {operator = "==" , params = array({}, "false"), expected =false },
                {operator = "==" , params = array({}, "1"), expected = false},
                {operator = "==" , params = array({}, "0"), expected = false},
                {operator = "==" , params = array({}, "-1"), expected = false},
                {operator = "==" , params = array({}, ""), expected = false},
                {operator = "==" , params = array({}, nil), expected = false},
                {operator = "==" , params = array({}, undefined), expected = false},
                {operator = "==" , params = array({}, 1/0), expected = false},
                {operator = "==" , params = array({}, -1/0), expected = false},
                {operator = "==" , params = array({}, array()), expected = false},
                {operator = "==" , params = array({}, {}), expected = false},
                {operator = "==" , params = array({}, array(array())), expected = false},
                {operator = "==" , params = array({}, array(0)), expected = false},
                {operator = "==" , params = array({}, array(1)), expected = false},
                {operator = "==" , params = array({}, 0/0), expected = false},
                {operator = "==" , params = array(array(array()), true), expected = false},
                {operator = "==" , params = array(array(array()), false), expected = true},
                {operator = "==" , params = array(array(array()), 1), expected = false},
                {operator = "==" , params = array(array(array()), 0), expected = true},
                {operator = "==" , params = array(array(array()), -1), expected = false},
                {operator = "==" , params = array(array(array()), "true"), expected =false },
                {operator = "==" , params = array(array(array()), "false"), expected =false },
                {operator = "==" , params = array(array(array()), "1"), expected = false},
                {operator = "==" , params = array(array(array()), "0"), expected = false},
                {operator = "==" , params = array(array(array()), "-1"), expected = false},
                {operator = "==" , params = array(array(array()), ""), expected = true},
                {operator = "==" , params = array(array(array()), nil), expected = false},
                {operator = "==" , params = array(array(array()), undefined), expected = false},
                {operator = "==" , params = array(array(array()), 1/0), expected = false},
                {operator = "==" , params = array(array(array()), -1/0), expected = false},
                {operator = "==" , params = array(array(array()), array()), expected = false},
                {operator = "==" , params = array(array(array()), {}), expected = false},
                {operator = "==" , params = array(array(array()), array(array())), expected = false},
                {operator = "==" , params = array(array(array()), array(0)), expected = false},
                {operator = "==" , params = array(array(array()), array(1)), expected = false},
                {operator = "==" , params = array(array(array()), 0/0), expected = false},
                {operator = "==" , params = array(array(0), true), expected = false},
                {operator = "==" , params = array(array(0), false), expected = true},
                {operator = "==" , params = array(array(0), 1), expected = false},
                {operator = "==" , params = array(array(0), 0), expected = true},
                {operator = "==" , params = array(array(0), -1), expected = false},
                {operator = "==" , params = array(array(0), "true"), expected =false },
                {operator = "==" , params = array(array(0), "false"), expected =false },
                {operator = "==" , params = array(array(0), "1"), expected = false},
                {operator = "==" , params = array(array(0), "0"), expected = true},
                {operator = "==" , params = array(array(0), "-1"), expected = false},
                {operator = "==" , params = array(array(0), ""), expected = false},
                {operator = "==" , params = array(array(0), nil), expected = false},
                {operator = "==" , params = array(array(0), undefined), expected = false},
                {operator = "==" , params = array(array(0), 1/0), expected = false},
                {operator = "==" , params = array(array(0), -1/0), expected = false},
                {operator = "==" , params = array(array(0), array()), expected = false},
                {operator = "==" , params = array(array(0), {}), expected = false},
                {operator = "==" , params = array(array(0), array(array())), expected = false},
                {operator = "==" , params = array(array(0), array(0)), expected = false},
                {operator = "==" , params = array(array(0), array(1)), expected = false},
                {operator = "==" , params = array(array(0), 0/0), expected = false},
                {operator = "==" , params = array(array(1), true), expected = true},
                {operator = "==" , params = array(array(1), false), expected = false},
                {operator = "==" , params = array(array(1), 1), expected = true},
                {operator = "==" , params = array(array(1), 0), expected = false},
                {operator = "==" , params = array(array(1), -1), expected = false},
                {operator = "==" , params = array(array(1), "true"), expected =false },
                {operator = "==" , params = array(array(1), "false"), expected =false },
                {operator = "==" , params = array(array(1), "1"), expected = true},
                {operator = "==" , params = array(array(1), "0"), expected = false},
                {operator = "==" , params = array(array(1), "-1"), expected = false},
                {operator = "==" , params = array(array(1), ""), expected = false},
                {operator = "==" , params = array(array(1), nil), expected = false},
                {operator = "==" , params = array(array(1), undefined), expected = false},
                {operator = "==" , params = array(array(1), 1/0), expected = false},
                {operator = "==" , params = array(array(1), -1/0), expected = false},
                {operator = "==" , params = array(array(1), array()), expected = false},
                {operator = "==" , params = array(array(1), {}), expected = false},
                {operator = "==" , params = array(array(1), array(array())), expected = false},
                {operator = "==" , params = array(array(1), array(0)), expected = false},
                {operator = "==" , params = array(array(1), array(1)), expected = false},
                {operator = "==" , params = array(array(1), 0/0), expected = false},
                {operator = "==" , params = array(0/0, true), expected = false},
                {operator = "==" , params = array(0/0, false), expected = false},
                {operator = "==" , params = array(0/0, 1), expected = false},
                {operator = "==" , params = array(0/0, 0), expected = false},
                {operator = "==" , params = array(0/0, -1), expected = false},
                {operator = "==" , params = array(0/0, "true"), expected =false },
                {operator = "==" , params = array(0/0, "false"), expected =false },
                {operator = "==" , params = array(0/0, "1"), expected = false},
                {operator = "==" , params = array(0/0, "0"), expected = false},
                {operator = "==" , params = array(0/0, "-1"), expected = false},
                {operator = "==" , params = array(0/0, ""), expected = false},
                {operator = "==" , params = array(0/0, nil), expected = false},
                {operator = "==" , params = array(0/0, undefined), expected = false},
                {operator = "==" , params = array(0/0, 1/0), expected = false},
                {operator = "==" , params = array(0/0, -1/0), expected = false},
                {operator = "==" , params = array(0/0, array()), expected = false},
                {operator = "==" , params = array(0/0, {}), expected = false},
                {operator = "==" , params = array(0/0, array(array())), expected = false},
                {operator = "==" , params = array(0/0, array(0)), expected = false},
                {operator = "==" , params = array(0/0, array(1)), expected = false},
                {operator = "==" , params = array(0/0, 0/0), expected = false},
            }
            logic_test(test_table)
        end)
        it("should return result of loose inequality evaluation when using '!=' operator", function ()
            local test_table = {
                {operator = "!=" , params = array(true, true), expected = false},
                {operator = "!=" , params = array(true, false), expected = true},
                {operator = "!=" , params = array(true, 1), expected = false},
                {operator = "!=" , params = array(true, 0), expected = true},
                {operator = "!=" , params = array(true, -1), expected = true},
                {operator = "!=" , params = array(true, "true"), expected = true },
                {operator = "!=" , params = array(true, "false"), expected = true },
                {operator = "!=" , params = array(true, "1"), expected = false},
                {operator = "!=" , params = array(true, "0"), expected = true},
                {operator = "!=" , params = array(true, "-1"), expected = true},
                {operator = "!=" , params = array(true, ""), expected = true},
                {operator = "!=" , params = array(true, nil), expected = true},
                {operator = "!=" , params = array(true, undefined), expected = true},
                {operator = "!=" , params = array(true, 1/0), expected = true},
                {operator = "!=" , params = array(true, -1/0), expected = true},
                {operator = "!=" , params = array(true, array()), expected = true},
                {operator = "!=" , params = array(true, {}), expected = true},
                {operator = "!=" , params = array(true, array(array())), expected = true},
                {operator = "!=" , params = array(true, array(0)), expected = true},
                {operator = "!=" , params = array(true, array(1)), expected = false},
                {operator = "!=" , params = array(true, 0/0), expected = true},
                {operator = "!=" , params = array(false, true), expected = true},
                {operator = "!=" , params = array(false, false), expected = false},
                {operator = "!=" , params = array(false, 1), expected = true},
                {operator = "!=" , params = array(false, 0), expected = false},
                {operator = "!=" , params = array(false, -1), expected = true},
                {operator = "!=" , params = array(false, "true"), expected = true },
                {operator = "!=" , params = array(false, "false"), expected = true },
                {operator = "!=" , params = array(false, "1"), expected = true},
                {operator = "!=" , params = array(false, "0"), expected = false},
                {operator = "!=" , params = array(false, "-1"), expected = true},
                {operator = "!=" , params = array(false, ""), expected = false},
                {operator = "!=" , params = array(false, nil), expected = true},
                {operator = "!=" , params = array(false, undefined), expected = true},
                {operator = "!=" , params = array(false, 1/0), expected = true},
                {operator = "!=" , params = array(false, -1/0), expected = true},
                {operator = "!=" , params = array(false, array()), expected = false},
                {operator = "!=" , params = array(false, {}), expected = true},
                {operator = "!=" , params = array(false, array(array())), expected = false},
                {operator = "!=" , params = array(false, array(0)), expected = false},
                {operator = "!=" , params = array(false, array(1)), expected = true},
                {operator = "!=" , params = array(false, 0/0), expected = true},
                {operator = "!=" , params = array(1, true), expected = false},
                {operator = "!=" , params = array(1, false), expected = true},
                {operator = "!=" , params = array(1, 1), expected = false},
                {operator = "!=" , params = array(1, 0), expected = true},
                {operator = "!=" , params = array(1, -1), expected = true},
                {operator = "!=" , params = array(1, "true"), expected = true },
                {operator = "!=" , params = array(1, "false"), expected = true },
                {operator = "!=" , params = array(1, "1"), expected = false},
                {operator = "!=" , params = array(1, "0"), expected = true},
                {operator = "!=" , params = array(1, "-1"), expected = true},
                {operator = "!=" , params = array(1, ""), expected = true},
                {operator = "!=" , params = array(1, nil), expected = true},
                {operator = "!=" , params = array(1, undefined), expected = true},
                {operator = "!=" , params = array(1, 1/0), expected = true},
                {operator = "!=" , params = array(1, -1/0), expected = true},
                {operator = "!=" , params = array(1, array()), expected = true},
                {operator = "!=" , params = array(1, {}), expected = true},
                {operator = "!=" , params = array(1, array(array())), expected = true},
                {operator = "!=" , params = array(1, array(0)), expected = true},
                {operator = "!=" , params = array(1, array(1)), expected = false},
                {operator = "!=" , params = array(1, 0/0), expected = true},
                {operator = "!=" , params = array(0, true), expected = true},
                {operator = "!=" , params = array(0, false), expected = false},
                {operator = "!=" , params = array(0, 1), expected = true},
                {operator = "!=" , params = array(0, 0), expected = false},
                {operator = "!=" , params = array(0, -1), expected = true},
                {operator = "!=" , params = array(0, "true"), expected = true },
                {operator = "!=" , params = array(0, "false"), expected = true },
                {operator = "!=" , params = array(0, "1"), expected = true},
                {operator = "!=" , params = array(0, "0"), expected = false},
                {operator = "!=" , params = array(0, "-1"), expected = true},
                {operator = "!=" , params = array(0, ""), expected = false},
                {operator = "!=" , params = array(0, nil), expected = true},
                {operator = "!=" , params = array(0, undefined), expected = true},
                {operator = "!=" , params = array(0, 1/0), expected = true},
                {operator = "!=" , params = array(0, -1/0), expected = true},
                {operator = "!=" , params = array(0, array()), expected = false},
                {operator = "!=" , params = array(0, {}), expected = true},
                {operator = "!=" , params = array(0, array(array())), expected = false},
                {operator = "!=" , params = array(0, array(0)), expected = false},
                {operator = "!=" , params = array(0, array(1)), expected = true},
                {operator = "!=" , params = array(0, 0/0), expected = true},
                {operator = "!=" , params = array(-1, true), expected = true},
                {operator = "!=" , params = array(-1, false), expected = true},
                {operator = "!=" , params = array(-1, 1), expected = true},
                {operator = "!=" , params = array(-1, 0), expected = true},
                {operator = "!=" , params = array(-1, -1), expected = false},
                {operator = "!=" , params = array(-1, "true"), expected = true },
                {operator = "!=" , params = array(-1, "false"), expected = true },
                {operator = "!=" , params = array(-1, "1"), expected = true},
                {operator = "!=" , params = array(-1, "0"), expected = true},
                {operator = "!=" , params = array(-1, "-1"), expected = false},
                {operator = "!=" , params = array(-1, ""), expected = true},
                {operator = "!=" , params = array(-1, nil), expected = true},
                {operator = "!=" , params = array(-1, undefined), expected = true},
                {operator = "!=" , params = array(-1, 1/0), expected = true},
                {operator = "!=" , params = array(-1, -1/0), expected = true},
                {operator = "!=" , params = array(-1, array()), expected = true},
                {operator = "!=" , params = array(-1, {}), expected = true},
                {operator = "!=" , params = array(-1, array(array())), expected = true},
                {operator = "!=" , params = array(-1, array(0)), expected = true},
                {operator = "!=" , params = array(-1, array(1)), expected = true},
                {operator = "!=" , params = array(-1, 0/0), expected = true},
                {operator = "!=" , params = array("true", true), expected = true},
                {operator = "!=" , params = array("true", false), expected = true},
                {operator = "!=" , params = array("true", 1), expected = true},
                {operator = "!=" , params = array("true", 0), expected = true},
                {operator = "!=" , params = array("true", -1), expected = true},
                {operator = "!=" , params = array("true", "true"), expected = false },
                {operator = "!=" , params = array("true", "false"), expected = true },
                {operator = "!=" , params = array("true", "1"), expected = true},
                {operator = "!=" , params = array("true", "0"), expected = true},
                {operator = "!=" , params = array("true", "-1"), expected = true},
                {operator = "!=" , params = array("true", ""), expected = true},
                {operator = "!=" , params = array("true", nil), expected = true},
                {operator = "!=" , params = array("true", undefined), expected = true},
                {operator = "!=" , params = array("true", 1/0), expected = true},
                {operator = "!=" , params = array("true", -1/0), expected = true},
                {operator = "!=" , params = array("true", array()), expected = true},
                {operator = "!=" , params = array("true", {}), expected = true},
                {operator = "!=" , params = array("true", array(array())), expected = true},
                {operator = "!=" , params = array("true", array(0)), expected = true},
                {operator = "!=" , params = array("true", array(1)), expected = true},
                {operator = "!=" , params = array("true", 0/0), expected = true},
                {operator = "!=" , params = array("false", true), expected = true},
                {operator = "!=" , params = array("false", false), expected = true},
                {operator = "!=" , params = array("false", 1), expected = true},
                {operator = "!=" , params = array("false", 0), expected = true},
                {operator = "!=" , params = array("false", -1), expected = true},
                {operator = "!=" , params = array("false", "true"), expected = true },
                {operator = "!=" , params = array("false", "false"), expected = false },
                {operator = "!=" , params = array("false", "1"), expected = true},
                {operator = "!=" , params = array("false", "0"), expected = true},
                {operator = "!=" , params = array("false", "-1"), expected = true},
                {operator = "!=" , params = array("false", ""), expected = true},
                {operator = "!=" , params = array("false", nil), expected = true},
                {operator = "!=" , params = array("false", undefined), expected = true},
                {operator = "!=" , params = array("false", 1/0), expected = true},
                {operator = "!=" , params = array("false", -1/0), expected = true},
                {operator = "!=" , params = array("false", array()), expected = true},
                {operator = "!=" , params = array("false", {}), expected = true},
                {operator = "!=" , params = array("false", array(array())), expected = true},
                {operator = "!=" , params = array("false", array(0)), expected = true},
                {operator = "!=" , params = array("false", array(1)), expected = true},
                {operator = "!=" , params = array("false", 0/0), expected = true},
                {operator = "!=" , params = array("1", true), expected = false},
                {operator = "!=" , params = array("1", false), expected = true},
                {operator = "!=" , params = array("1", 1), expected = false},
                {operator = "!=" , params = array("1", 0), expected = true},
                {operator = "!=" , params = array("1", -1), expected = true},
                {operator = "!=" , params = array("1", "true"), expected = true },
                {operator = "!=" , params = array("1", "false"), expected = true },
                {operator = "!=" , params = array("1", "1"), expected = false},
                {operator = "!=" , params = array("1", "0"), expected = true},
                {operator = "!=" , params = array("1", "-1"), expected = true},
                {operator = "!=" , params = array("1", ""), expected = true},
                {operator = "!=" , params = array("1", nil), expected = true},
                {operator = "!=" , params = array("1", undefined), expected = true},
                {operator = "!=" , params = array("1", 1/0), expected = true},
                {operator = "!=" , params = array("1", -1/0), expected = true},
                {operator = "!=" , params = array("1", array()), expected = true},
                {operator = "!=" , params = array("1", {}), expected = true},
                {operator = "!=" , params = array("1", array(array())), expected = true},
                {operator = "!=" , params = array("1", array(0)), expected = true},
                {operator = "!=" , params = array("1", array(1)), expected = false},
                {operator = "!=" , params = array("1", 0/0), expected = true},
                {operator = "!=" , params = array("0", true), expected = true},
                {operator = "!=" , params = array("0", false), expected = false},
                {operator = "!=" , params = array("0", 1), expected = true},
                {operator = "!=" , params = array("0", 0), expected = false},
                {operator = "!=" , params = array("0", -1), expected = true},
                {operator = "!=" , params = array("0", "true"), expected = true },
                {operator = "!=" , params = array("0", "false"), expected = true },
                {operator = "!=" , params = array("0", "1"), expected = true},
                {operator = "!=" , params = array("0", "0"), expected = false},
                {operator = "!=" , params = array("0", "-1"), expected = true},
                {operator = "!=" , params = array("0", ""), expected = true},
                {operator = "!=" , params = array("0", nil), expected = true},
                {operator = "!=" , params = array("0", undefined), expected = true},
                {operator = "!=" , params = array("0", 1/0), expected = true},
                {operator = "!=" , params = array("0", -1/0), expected = true},
                {operator = "!=" , params = array("0", array()), expected = true},
                {operator = "!=" , params = array("0", {}), expected = true},
                {operator = "!=" , params = array("0", array(array())), expected = true},
                {operator = "!=" , params = array("0", array(0)), expected = false},
                {operator = "!=" , params = array("0", array(1)), expected = true},
                {operator = "!=" , params = array("0", 0/0), expected = true},
                {operator = "!=" , params = array("-1", true), expected = true},
                {operator = "!=" , params = array("-1", false), expected = true},
                {operator = "!=" , params = array("-1", 1), expected = true},
                {operator = "!=" , params = array("-1", 0), expected = true},
                {operator = "!=" , params = array("-1", -1), expected = false},
                {operator = "!=" , params = array("-1", "true"), expected = true },
                {operator = "!=" , params = array("-1", "false"), expected = true },
                {operator = "!=" , params = array("-1", "1"), expected = true},
                {operator = "!=" , params = array("-1", "0"), expected = true},
                {operator = "!=" , params = array("-1", "-1"), expected = false},
                {operator = "!=" , params = array("-1", ""), expected = true},
                {operator = "!=" , params = array("-1", nil), expected = true},
                {operator = "!=" , params = array("-1", undefined), expected = true},
                {operator = "!=" , params = array("-1", 1/0), expected = true},
                {operator = "!=" , params = array("-1", -1/0), expected = true},
                {operator = "!=" , params = array("-1", array()), expected = true},
                {operator = "!=" , params = array("-1", {}), expected = true},
                {operator = "!=" , params = array("-1", array(array())), expected = true},
                {operator = "!=" , params = array("-1", array(0)), expected = true},
                {operator = "!=" , params = array("-1", array(1)), expected = true},
                {operator = "!=" , params = array("-1", 0/0), expected = true},
                {operator = "!=" , params = array("", true), expected = true},
                {operator = "!=" , params = array("", false), expected = false},
                {operator = "!=" , params = array("", 1), expected = true},
                {operator = "!=" , params = array("", 0), expected = false},
                {operator = "!=" , params = array("", -1), expected = true},
                {operator = "!=" , params = array("", "true"), expected = true },
                {operator = "!=" , params = array("", "false"), expected = true },
                {operator = "!=" , params = array("", "1"), expected = true},
                {operator = "!=" , params = array("", "0"), expected = true},
                {operator = "!=" , params = array("", "-1"), expected = true},
                {operator = "!=" , params = array("", ""), expected = false},
                {operator = "!=" , params = array("", nil), expected = true},
                {operator = "!=" , params = array("", undefined), expected = true},
                {operator = "!=" , params = array("", 1/0), expected = true},
                {operator = "!=" , params = array("", -1/0), expected = true},
                {operator = "!=" , params = array("", array()), expected = false},
                {operator = "!=" , params = array("", {}), expected = true},
                {operator = "!=" , params = array("", array(array())), expected = false},
                {operator = "!=" , params = array("", array(0)), expected = true},
                {operator = "!=" , params = array("", array(1)), expected = true},
                {operator = "!=" , params = array("", 0/0), expected = true},
                {operator = "!=" , params = array(nil, true), expected = true},
                {operator = "!=" , params = array(nil, false), expected = true},
                {operator = "!=" , params = array(nil, 1), expected = true},
                {operator = "!=" , params = array(nil, 0), expected = true},
                {operator = "!=" , params = array(nil, -1), expected = true},
                {operator = "!=" , params = array(nil, "true"), expected = true },
                {operator = "!=" , params = array(nil, "false"), expected = true },
                {operator = "!=" , params = array(nil, "1"), expected = true},
                {operator = "!=" , params = array(nil, "0"), expected = true},
                {operator = "!=" , params = array(nil, "-1"), expected = true},
                {operator = "!=" , params = array(nil, ""), expected = true},
                {operator = "!=" , params = array(nil, nil), expected = false},
                {operator = "!=" , params = array(nil, undefined), expected = false},
                {operator = "!=" , params = array(nil, 1/0), expected = true},
                {operator = "!=" , params = array(nil, -1/0), expected = true},
                {operator = "!=" , params = array(nil, array()), expected = true},
                {operator = "!=" , params = array(nil, {}), expected = true},
                {operator = "!=" , params = array(nil, array(array())), expected = true},
                {operator = "!=" , params = array(nil, array(0)), expected = true},
                {operator = "!=" , params = array(nil, array(1)), expected = true},
                {operator = "!=" , params = array(nil, 0/0), expected = true},
                {operator = "!=" , params = array(undefined, true), expected = true},
                {operator = "!=" , params = array(undefined, false), expected = true},
                {operator = "!=" , params = array(undefined, 1), expected = true},
                {operator = "!=" , params = array(undefined, 0), expected = true},
                {operator = "!=" , params = array(undefined, -1), expected = true},
                {operator = "!=" , params = array(undefined, "true"), expected = true },
                {operator = "!=" , params = array(undefined, "false"), expected = true },
                {operator = "!=" , params = array(undefined, "1"), expected = true},
                {operator = "!=" , params = array(undefined, "0"), expected = true},
                {operator = "!=" , params = array(undefined, "-1"), expected = true},
                {operator = "!=" , params = array(undefined, ""), expected = true},
                {operator = "!=" , params = array(undefined, nil), expected = false},
                {operator = "!=" , params = array(undefined, undefined), expected = false},
                {operator = "!=" , params = array(undefined, 1/0), expected = true},
                {operator = "!=" , params = array(undefined, -1/0), expected = true},
                {operator = "!=" , params = array(undefined, array()), expected = true},
                {operator = "!=" , params = array(undefined, {}), expected = true},
                {operator = "!=" , params = array(undefined, array(array())), expected = true},
                {operator = "!=" , params = array(undefined, array(0)), expected = true},
                {operator = "!=" , params = array(undefined, array(1)), expected = true},
                {operator = "!=" , params = array(undefined, 0/0), expected = true},
                {operator = "!=" , params = array(1/0, true), expected = true},
                {operator = "!=" , params = array(1/0, false), expected = true},
                {operator = "!=" , params = array(1/0, 1), expected = true},
                {operator = "!=" , params = array(1/0, 0), expected = true},
                {operator = "!=" , params = array(1/0, -1), expected = true},
                {operator = "!=" , params = array(1/0, "true"), expected = true },
                {operator = "!=" , params = array(1/0, "false"), expected = true },
                {operator = "!=" , params = array(1/0, "1"), expected = true},
                {operator = "!=" , params = array(1/0, "0"), expected = true},
                {operator = "!=" , params = array(1/0, "-1"), expected = true},
                {operator = "!=" , params = array(1/0, ""), expected = true},
                {operator = "!=" , params = array(1/0, nil), expected = true},
                {operator = "!=" , params = array(1/0, undefined), expected = true},
                {operator = "!=" , params = array(1/0, 1/0), expected = false},
                {operator = "!=" , params = array(1/0, -1/0), expected = true},
                {operator = "!=" , params = array(1/0, array()), expected = true},
                {operator = "!=" , params = array(1/0, {}), expected = true},
                {operator = "!=" , params = array(1/0, array(array())), expected = true},
                {operator = "!=" , params = array(1/0, array(0)), expected = true},
                {operator = "!=" , params = array(1/0, array(1)), expected = true},
                {operator = "!=" , params = array(1/0, 0/0), expected = true},
                {operator = "!=" , params = array(-1/0, true), expected = true},
                {operator = "!=" , params = array(-1/0, false), expected = true},
                {operator = "!=" , params = array(-1/0, 1), expected = true},
                {operator = "!=" , params = array(-1/0, 0), expected = true},
                {operator = "!=" , params = array(-1/0, -1), expected = true},
                {operator = "!=" , params = array(-1/0, "true"), expected = true },
                {operator = "!=" , params = array(-1/0, "false"), expected = true },
                {operator = "!=" , params = array(-1/0, "1"), expected = true},
                {operator = "!=" , params = array(-1/0, "0"), expected = true},
                {operator = "!=" , params = array(-1/0, "-1"), expected = true},
                {operator = "!=" , params = array(-1/0, ""), expected = true},
                {operator = "!=" , params = array(-1/0, nil), expected = true},
                {operator = "!=" , params = array(-1/0, undefined), expected = true},
                {operator = "!=" , params = array(-1/0, 1/0), expected = true},
                {operator = "!=" , params = array(-1/0, -1/0), expected = false},
                {operator = "!=" , params = array(-1/0, array()), expected = true},
                {operator = "!=" , params = array(-1/0, {}), expected = true},
                {operator = "!=" , params = array(-1/0, array(array())), expected = true},
                {operator = "!=" , params = array(-1/0, array(0)), expected = true},
                {operator = "!=" , params = array(-1/0, array(1)), expected = true},
                {operator = "!=" , params = array(-1/0, 0/0), expected = true},
                {operator = "!=" , params = array(array(), true), expected = true},
                {operator = "!=" , params = array(array(), false), expected = false},
                {operator = "!=" , params = array(array(), 1), expected = true},
                {operator = "!=" , params = array(array(), 0), expected = false},
                {operator = "!=" , params = array(array(), -1), expected = true},
                {operator = "!=" , params = array(array(), "true"), expected = true },
                {operator = "!=" , params = array(array(), "false"), expected = true },
                {operator = "!=" , params = array(array(), "1"), expected = true},
                {operator = "!=" , params = array(array(), "0"), expected = true},
                {operator = "!=" , params = array(array(), "-1"), expected = true},
                {operator = "!=" , params = array(array(), ""), expected = false},
                {operator = "!=" , params = array(array(), nil), expected = true},
                {operator = "!=" , params = array(array(), undefined), expected = true},
                {operator = "!=" , params = array(array(), 1/0), expected = true},
                {operator = "!=" , params = array(array(), -1/0), expected = true},
                {operator = "!=" , params = array(array(), array()), expected = true},
                {operator = "!=" , params = array(array(), {}), expected = true},
                {operator = "!=" , params = array(array(), array(array())), expected = true},
                {operator = "!=" , params = array(array(), array(0)), expected = true},
                {operator = "!=" , params = array(array(), array(1)), expected = true},
                {operator = "!=" , params = array(array(), 0/0), expected = true},
                {operator = "!=" , params = array({}, true), expected = true},
                {operator = "!=" , params = array({}, false), expected = true},
                {operator = "!=" , params = array({}, 1), expected = true},
                {operator = "!=" , params = array({}, 0), expected = true},
                {operator = "!=" , params = array({}, -1), expected = true},
                {operator = "!=" , params = array({}, "true"), expected = true },
                {operator = "!=" , params = array({}, "false"), expected = true },
                {operator = "!=" , params = array({}, "1"), expected = true},
                {operator = "!=" , params = array({}, "0"), expected = true},
                {operator = "!=" , params = array({}, "-1"), expected = true},
                {operator = "!=" , params = array({}, ""), expected = true},
                {operator = "!=" , params = array({}, nil), expected = true},
                {operator = "!=" , params = array({}, undefined), expected = true},
                {operator = "!=" , params = array({}, 1/0), expected = true},
                {operator = "!=" , params = array({}, -1/0), expected = true},
                {operator = "!=" , params = array({}, array()), expected = true},
                {operator = "!=" , params = array({}, {}), expected = true},
                {operator = "!=" , params = array({}, array(array())), expected = true},
                {operator = "!=" , params = array({}, array(0)), expected = true},
                {operator = "!=" , params = array({}, array(1)), expected = true},
                {operator = "!=" , params = array({}, 0/0), expected = true},
                {operator = "!=" , params = array(array(array()), true), expected = true},
                {operator = "!=" , params = array(array(array()), false), expected = false},
                {operator = "!=" , params = array(array(array()), 1), expected = true},
                {operator = "!=" , params = array(array(array()), 0), expected = false},
                {operator = "!=" , params = array(array(array()), -1), expected = true},
                {operator = "!=" , params = array(array(array()), "true"), expected = true },
                {operator = "!=" , params = array(array(array()), "false"), expected = true },
                {operator = "!=" , params = array(array(array()), "1"), expected = true},
                {operator = "!=" , params = array(array(array()), "0"), expected = true},
                {operator = "!=" , params = array(array(array()), "-1"), expected = true},
                {operator = "!=" , params = array(array(array()), ""), expected = false},
                {operator = "!=" , params = array(array(array()), nil), expected = true},
                {operator = "!=" , params = array(array(array()), undefined), expected = true},
                {operator = "!=" , params = array(array(array()), 1/0), expected = true},
                {operator = "!=" , params = array(array(array()), -1/0), expected = true},
                {operator = "!=" , params = array(array(array()), array()), expected = true},
                {operator = "!=" , params = array(array(array()), {}), expected = true},
                {operator = "!=" , params = array(array(array()), array(array())), expected = true},
                {operator = "!=" , params = array(array(array()), array(0)), expected = true},
                {operator = "!=" , params = array(array(array()), array(1)), expected = true},
                {operator = "!=" , params = array(array(array()), 0/0), expected = true},
                {operator = "!=" , params = array(array(0), true), expected = true},
                {operator = "!=" , params = array(array(0), false), expected = false},
                {operator = "!=" , params = array(array(0), 1), expected = true},
                {operator = "!=" , params = array(array(0), 0), expected = false},
                {operator = "!=" , params = array(array(0), -1), expected = true},
                {operator = "!=" , params = array(array(0), "true"), expected = true },
                {operator = "!=" , params = array(array(0), "false"), expected = true },
                {operator = "!=" , params = array(array(0), "1"), expected = true},
                {operator = "!=" , params = array(array(0), "0"), expected = false},
                {operator = "!=" , params = array(array(0), "-1"), expected = true},
                {operator = "!=" , params = array(array(0), ""), expected = true},
                {operator = "!=" , params = array(array(0), nil), expected = true},
                {operator = "!=" , params = array(array(0), undefined), expected = true},
                {operator = "!=" , params = array(array(0), 1/0), expected = true},
                {operator = "!=" , params = array(array(0), -1/0), expected = true},
                {operator = "!=" , params = array(array(0), array()), expected = true},
                {operator = "!=" , params = array(array(0), {}), expected = true},
                {operator = "!=" , params = array(array(0), array(array())), expected = true},
                {operator = "!=" , params = array(array(0), array(0)), expected = true},
                {operator = "!=" , params = array(array(0), array(1)), expected = true},
                {operator = "!=" , params = array(array(0), 0/0), expected = true},
                {operator = "!=" , params = array(array(1), true), expected = false},
                {operator = "!=" , params = array(array(1), false), expected = true},
                {operator = "!=" , params = array(array(1), 1), expected = false},
                {operator = "!=" , params = array(array(1), 0), expected = true},
                {operator = "!=" , params = array(array(1), -1), expected = true},
                {operator = "!=" , params = array(array(1), "true"), expected = true },
                {operator = "!=" , params = array(array(1), "false"), expected = true },
                {operator = "!=" , params = array(array(1), "1"), expected = false},
                {operator = "!=" , params = array(array(1), "0"), expected = true},
                {operator = "!=" , params = array(array(1), "-1"), expected = true},
                {operator = "!=" , params = array(array(1), ""), expected = true},
                {operator = "!=" , params = array(array(1), nil), expected = true},
                {operator = "!=" , params = array(array(1), undefined), expected = true},
                {operator = "!=" , params = array(array(1), 1/0), expected = true},
                {operator = "!=" , params = array(array(1), -1/0), expected = true},
                {operator = "!=" , params = array(array(1), array()), expected = true},
                {operator = "!=" , params = array(array(1), {}), expected = true},
                {operator = "!=" , params = array(array(1), array(array())), expected = true},
                {operator = "!=" , params = array(array(1), array(0)), expected = true},
                {operator = "!=" , params = array(array(1), array(1)), expected = true},
                {operator = "!=" , params = array(array(1), 0/0), expected = true},
                {operator = "!=" , params = array(0/0, true), expected = true},
                {operator = "!=" , params = array(0/0, false), expected = true},
                {operator = "!=" , params = array(0/0, 1), expected = true},
                {operator = "!=" , params = array(0/0, 0), expected = true},
                {operator = "!=" , params = array(0/0, -1), expected = true},
                {operator = "!=" , params = array(0/0, "true"), expected = true },
                {operator = "!=" , params = array(0/0, "false"), expected = true },
                {operator = "!=" , params = array(0/0, "1"), expected = true},
                {operator = "!=" , params = array(0/0, "0"), expected = true},
                {operator = "!=" , params = array(0/0, "-1"), expected = true},
                {operator = "!=" , params = array(0/0, ""), expected = true},
                {operator = "!=" , params = array(0/0, nil), expected = true},
                {operator = "!=" , params = array(0/0, undefined), expected = true},
                {operator = "!=" , params = array(0/0, 1/0), expected = true},
                {operator = "!=" , params = array(0/0, -1/0), expected = true},
                {operator = "!=" , params = array(0/0, array()), expected = true},
                {operator = "!=" , params = array(0/0, {}), expected = true},
                {operator = "!=" , params = array(0/0, array(array())), expected = true},
                {operator = "!=" , params = array(0/0, array(0)), expected = true},
                {operator = "!=" , params = array(0/0, array(1)), expected = true},
                {operator = "!=" , params = array(0/0, 0/0), expected = true},
            }
            logic_test(test_table)
        end)
        it("should return result of strict equality evaluation when using '===' operator", function ()
            local test_table={
                {operator = "===", params = array(true,true), expected = true},
                {operator = "===", params = array(true,1), expected = false},
                {operator = "===", params = array(false,false), expected = true},
                {operator = "===", params = array(false,0), expected = false},
                {operator = "===", params = array(false,""), expected = false},
                {operator = "===", params = array(1,"1"), expected = false},
                {operator = "===", params = array(0,"0"), expected = false},
                {operator = "===", params = array(0,array()), expected = false},
                {operator = "===", params = array(0,array(0)), expected = false},
                {operator = "===", params = array(array(),array()), expected = false},
            }
            logic_test(test_table)
        end)
        it("should return result of strict inequality evaluation when using '!==' operator", function ()
            local test_table={
                {operator = "!==", params = array(true,true), expected = false},
                {operator = "!==", params = array(true,1), expected = true},
                {operator = "!==", params = array(false,false), expected = false},
                {operator = "!==", params = array(false,0), expected = true},
                {operator = "!==", params = array(false,""), expected = true},
                {operator = "!==", params = array(1,"1"), expected = true},
                {operator = "!==", params = array(0,"0"), expected = true},
                {operator = "!==", params = array(0,array()), expected = true},
                {operator = "!==", params = array(0,array(0)), expected = true},
                {operator = "!==", params = array(array(),array()), expected = true},
            }
            logic_test(test_table)
        end)
    end)
    describe("given one item", function ()
        it("should return the negation of the item when using '!' operator", function ()
            local test_table={
                {operator = "!", params = array(false), expected = true},
                {operator = "!", params = array(nil), expected = true},
                {operator = "!", params = array(undefined), expected = true},
                {operator = "!", params = array(0), expected = true},
                {operator = "!", params = array(""), expected = true},
                {operator = "!", params = array(0/0), expected = true},
                {operator = "!", params = array(undefined), expected = true},
                {operator = "!", params = array("0"), expected = false},
                {operator = "!", params = array(true), expected = false},
                {operator = "!", params = array(1), expected = false},
                {operator = "!", params = array(-1), expected = false},
                {operator = "!", params = array("true"), expected = false},
                {operator = "!", params = array("false"), expected = false},
                {operator = "!", params = array("1"), expected = false},
                {operator = "!", params = array("-1"), expected = false},
                {operator = "!", params = array(1/0), expected = false},
                {operator = "!", params = array(-1/0), expected = false},
                {operator = "!", params = array(array()), expected = false},
                {operator = "!", params = array({}), expected = false},
            }
            logic_test(test_table)
        end)
        it("should return the double negation of the item when using '!!' operator", function ()
            local test_table={
                {operator = "!!", params = array(false), expected = false},
                {operator = "!!", params = array(nil), expected = false},
                {operator = "!!", params = array(undefined), expected = false},
                {operator = "!!", params = array(0), expected = false},
                {operator = "!!", params = array(""), expected = false},
                {operator = "!!", params = array(0/0), expected = false},
                {operator = "!!", params = array(undefined), expected = false},
                {operator = "!!", params = array("0"), expected = true},
                {operator = "!!", params = array(true), expected = true},
                {operator = "!!", params = array(1), expected = true},
                {operator = "!!", params = array(-1), expected = true},
                {operator = "!!", params = array("true"), expected = true},
                {operator = "!!", params = array("false"), expected = true},
                {operator = "!!", params = array("1"), expected = true},
                {operator = "!!", params = array("-1"), expected = true},
                {operator = "!!", params = array(1/0), expected = true},
                {operator = "!!", params = array(-1/0), expected = true},
                {operator = "!!", params = array(array()), expected = true},
                {operator = "!!", params = array({}), expected = true},
            }
            logic_test(test_table)
        end)
    end)
end)

describe("json-logic operation test", function ()
    describe("given unregistered operation", function ()
        local test_table = {
            {logic = {echo = array(1,2,3)}},
            {logic = {first = array(1,2,3)}},
        }
        it("should return the original logic", function ()
            for i, t in ipairs(test_table) do
                local res = logic_apply(t.logic, nil)
                assert.message('failed at index: ' .. i).are.equal(t.logic, res)
            end
        end)
    end)

    describe("given new operation to be registered", function ()
        local test_table = {
            {
                new_op_name = "echo",
                new_op = function(_, ...)
                    arg["n"] = nil
                    return arg
                end,
                logic = {echo = array(array(1,2,3,4,5))},
                expected = array(array(1,2,3,4,5)),
             },
             {
                new_op_name = "first",
                new_op = function(_, ...)
                    -- return first parameter
                    return arg[1]
                end,
                logic = {first = array(1,2,3,4,5)},
                expected = 1,
             },
        }
        it("should call the new operation correctly", function ()
            for i, t in ipairs(test_table) do
                local called = 0
                local operation = function(data, ...)
                    local res =  t.new_op(data, ...)
                    called = called + 1
                    return res
                end
                local options = {custom_operations = {}}
                options.custom_operations[t.new_op_name] = operation
                local res = logic_apply(t.logic, nil, options)
                assert.message("the new operation was not called once").are.equal(1, called)
                assert.message('failed at index: ' .. i).are.same(t.expected, res)
            end
        end)
    end)
end)