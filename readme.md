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