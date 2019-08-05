# JSON-LOGIC

Lua port of <https://github.com/jwadhams/json-logic-js>.  
Luarocks url: <https://luarocks.org/modules/rucciva/json-logic-lua>.  

## Differentiation with the original json-logic:

1. Empty array is evaluated to true, unlike the original json-logic which evaluate empty array to false.
1. The library accept a third parameter in the form of lua table that can alter the behavior of json-logic
1. To include additional operations:
    - includes a lua table in the third parameter  under **custom_operations** key
    - the tables contains the operation name as the key and a function as a value
    - the first parameter of the function is a table with the following format
    ```lua
    {
        data = data_passed_to_Apply_function
        opts = options_passed_to_Apply_function
    }
    ```
1. For working with a certain json library that try to distinguish between array and object, user of this library should add following functions under the third parameter:
    - a function to determine wether a table is an array or object
        - key : **is_array**
        - parameters : a lua table
        - return value : boolean
    - a function to mark a lua table as an array
        - key : **mark_as_array**
        - parameters : a lua table
        - return value : a lua table
1. One or more operation can be disabled. If an operation is disabled, than it is considered as data and will be returned as is. To control which operations are enabled, use one of the following mode and add appropriate data under the third parameter:
    - blacklist mode
        - key : **blacklist**
        - contents: a lua table that contains list of operation names that will be disabled. **all else will be enabled**
    - whitelist mode (can only be activated when **blacklist** key does not exist in the third parameter)
        - key : **whitelist**
        - contents: a lua table that contains list of operation names that will be enabled. **all else will be disabled**
1. operator `_` are used to escape operand and treat it as literal. e.g.: 

```javascript
    {
        "_" : {
            "map" : [
                41.40338,
                2.17403
            ]
        }
    }
```

# API

- [cat](#cat)
- [in](#in)
- [is_array](#is_array)
- [isArray](#isarray)
- [join](#join)
- [length](#length)
- [log](#max)
- [max](#max)
- [merge](#merge)
- [min](#min)
- [missing](#missing)
- [missing_some](#missing_some)
- [missingSome](#missingsome)
- [substr](#substr)
- [toLowerCase](#tolowercase)
- [toUpperCase](#touppercase)
- [typeof](#typeof)
- [var](#var)


cat
---
**syntax:** `{"cat": ["I love", " pie"]}`

Concatenate all the supplied arguments.

in
---
**syntax:** `{"in":[ "Ringo", ["John", "Paul", "George", "Ringo"] ]}`

**syntax:** `{"in":["Spring", "Springfield"]}`

If the second argument is an array, tests that the first argument is a member of the array.
If the second argument is a string, tests that the first argument is a substring.

is_array
--------
See [isArray](#isarray)

isArray
-------
**syntax:** `{"isArray": [a]}`

Returns `true` if the given param is an array.

join
----
**syntax:** `{"join": ["a", "b", "c", ...]}`

length
------
**syntax:** `{"length": ["Hello, World!"]}`

**syntax:** `{"length": [[a, b, c, ...]]}`

Return length of the given string or table.

log
---
**syntax:** `{"log": a}`

Writes to standard output.

max
---
**syntax:** `{"max": [a, b, c, ...]}`

Find the minimum value from the given params.

merge
-----
**syntax:** `{"merge": [a, b, c, ...]}`

**syntax:** `{"merge": [ [1,2], [3,4] ]}`

Takes one or more arrays, and merges them into one array. If arguments aren’t arrays, they get cast to arrays.

min
---
**syntax:** `{"min": [a, b, c, ...]}`

Find the minimum value from the given params.

missing
-------
**syntax:** `{"missing":["a", "b"]}`

Takes an array of data keys to search for (same format as `var`). Returns an array of any keys that are missing from the data object, or an empty array.

missing_some
------------
See [missingSome](#missingsome)

missingSome
-----------
**syntax:** `{"missing_some":[1, ["a", "b", "c"]]}`

Takes a minimum number of data keys that are required, and an array of keys to search for (same format as var or missing). Returns an empty array if the minimum is met, or an array of the missing keys otherwise.

substr
------
**syntax:** `{"substr": [source, st, en]}`

Returns a part of `source`, from specified `st` to `en`.

toLowerCase
-----------
**syntax:** `{"toLowerCase": [str]}`

Returns the lower-cased letters of the given string.

toUpperCase
-----------
**syntax:** `{"toUpperCase": [str]}`

Returns the upper-cased letters of the given string.

typeof
------
**syntax:** `{"typeof": [a]}`

Returns type of `a`.

var
---
**syntax:** `{"var": ["a"]}`

Retrieve data from the provided data object.


