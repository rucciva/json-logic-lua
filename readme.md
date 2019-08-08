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

# Supported Operations

- [Accessing Data](#accessing-data)
    - [`missing`](#missing)
    - [`missing_some`](#missing_some)
    - [`missingSome`](#missingsome)
    - [`typeof`](#typeof)
    - [`var`](#var)
- [Logic and Boolean Operations](#logic-and-boolean-operations)
    - [`if`](#if)
    - [`==`](#equality)
    - [`===`](#strict-equality)
    - [`!=`](#not-equal)
    - [`!==`](#strict-not-equal)
    - [`!`](#negation)
    - [`!!`](#double-negation)
    - [`or`](#or)
    - [`and`](#and)
- [Numeric Operations](#numeric-operations)
    - [Arithmetic, `+` `-` `*` `/`](#arithmetic)
    - [`%`](#modulo)
    - [`>`, `>=`, `<`, `<=`](#comparison)
    - [Between](#between)
    - [`max`](#max)
    - [`min`](#min)
- [Array Operations](#array-operations)
    - [`all`](#all-some-and-none)
    - [`filter`](#map-reduce-and-filter)
    - [`in`](#in-array)
    - [`is_array`](#is_array)
    - [`isArray`](#isarray)
    - [`join`](#join)
    - [`length`](#length-array)
    - [`map`](#map-reduce-and-filter)
    - [`merge`](#merge)
    - [`none`](#all-some-and-none)
    - [`reduce`](#map-reduce-and-filter)
    - [`some`](#all-some-and-none)
- [String Operations](#string-operations)
    - [`cat`](#cat)
    - [`in`](#in-string)
    - [`length`](#length-string)
    - [`substr`](#substr)
    - [`toLowerCase`](#tolowercase)
    - [`toUpperCase`](#touppercase)
- [Miscellanous](#miscellanous)
    - [`log`](#log)


Accessing Data
--------------

### `missing`
**syntax:** `{"missing":["a", "b"]}`

Takes an array of data keys to search for (same format as `var`). Returns an array of any keys that are missing from the data object, or an empty array.

<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"missing":["a", "b"]}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>{"a":"apple", "c":"carrot"}</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>["b"]</code></td>
  </tr>
</table>


<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"missing":["a", "b"]}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>{"a":"apple", "b":"banana"}</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>[]</code></td>
  </tr>
</table>

Note, in JsonLogic, empty arrays are falsy. So you can use `missing` with `if` like:

<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
<pre><code>{"if":[
  {"missing":["a", "b"]},
  "Not enough fruit",
  "OK to proceed"
]}</code></pre>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>{"a":"apple", "b":"banana"}</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>"OK to proceed"</code></td>
  </tr>
</table>

### `missing_some`
See [missingSome](#missingsome)

### `missingSome`
**syntax:** `{"missing_some":[1, ["a", "b", "c"]]}`

Takes a minimum number of data keys that are required, and an array of keys to search for (same format as `var` or `missing`). Returns an empty array if the minimum is met, or an array of the missing keys otherwise.

<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"missing_some":[1, ["a", "b", "c"]]}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>{"a":"apple"}</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>[]</code></td>
  </tr>
</table>


<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"missing_some":[2, ["a", "b", "c"]]}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>{"a":"apple"}</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>["b", "c"]</code></td>
  </tr>
</table>

This is useful if you’re using `missing` to track required fields, but occasionally need to require N of M fields.

<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
<pre><code>{"if" :[
  {"merge": [
    {"missing":["first_name", "last_name"]},
    {"missing_some":[1, ["cell_phone", "home_phone"] ]}
  ]},
  "We require first name, last name, and one phone number.",
  "OK to proceed"
]}</code></pre>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>{"first_name":"Bruce", "last_name":"Wayne"}</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>"We require first name, last name, and one phone number."</code></td>
  </tr>
</table>

### `typeof`
**syntax:** `{"typeof": [a]}`

Returns type of `a`.

### `var`
**syntax:** `{"var": ["a"]}`

Retrieve data from the provided data object.

<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{ "var" : ["a"] }</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>{ "a":1, "b":2 }</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>1</code></td>
  </tr>
</table>


Logic and Boolean Operations
----------------------------

### `if`
**syntax:** `{"if" : [ true, "yes", "no" ]}`

The if statement typically takes 3 arguments: a condition (if), what to do if it’s true (then), and what to do if it’s false (else), like:

<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"if" : [ true, "yes", "no" ]}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>null</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>"yes"</code></td>
  </tr>
</table>


<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"if" : [ false, "yes", "no" ]}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>null</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>"no"</code></td>
  </tr>
</table>

If can also take more than 3 arguments, and will pair up arguments like if/then elseif/then elseif/then else. Like:

<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <pre><code>{"if" : [
  {"<": [{"var":"temp"}, 0] }, "freezing",
  {"<": [{"var":"temp"}, 100] }, "liquid",
  "gas"
]}</code></pre>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>{"temp":55}</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>"liquid"</code></td>
  </tr>
</table>


### <a id="equality"></a>`==`
**syntax:** `{"==" : [1, 1]}`

Tests equality, with type coercion. Requires two arguments.

<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"==" : [1, 1]}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>null</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>true</code></td>
  </tr>
</table>


<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"==" : [1, "1"]}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>null</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>true</code></td>
  </tr>
</table>


<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"==" : [0, false]}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>null</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>true</code></td>
  </tr>
</table>

### <a id="strict-equality"></a>`===`
**syntax:** `{"===" : [1, 1]}`

**syntax:** `{"===" : [1, "1"]}`

Tests strict equality. Requires two arguments.

<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"===" : [1, 1]}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>null</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>true</code></td>
  </tr>
</table>


<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"===" : [1, "1"]}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>null</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>false</code></td>
  </tr>
</table>

### <a id="not-equal"></a>`!=`
**syntax:** `{"!=" : [1, 2]}`

**syntax:** `{"!=" : [1, "1"]}`

Tests not-equal, with type coercion.

<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"!=" : [1, 2]}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>null</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>true</code></td>
  </tr>
</table>


<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"!=" : [1, "1"]}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>null</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>false</code></td>
  </tr>
</table>

### <a id="strict-not-equal"></a>`!==`
**syntax:** `{"!==" : [1, 2]}`

**syntax:** `{"!==" : [1, "1"]}`

Tests strict not-equal.

<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"!==" : [1, 2]}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>null</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>true</code></td>
  </tr>
</table>


<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"!==" : [1, "1"]}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>null</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>true</code></td>
  </tr>
</table>

### <a id="negation"></a>`!`
**syntax:** `{"!": [true]}`

**syntax:** `{"!": true}`

Logical negation ("not"). Takes just one argument.

<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"!": [true]}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>null</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>false</code></td>
  </tr>
</table>


<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"!": true}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>null</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>false</code></td>
  </tr>
</table>

### <a id="double-negation"></a>`!!`
**syntax:** `{"!!": [ [] ] }`

**syntax:** `{"!!": ["0"] }`

Double negation, or "cast to a boolean." Takes a single argument.

Note that JsonLogic has its own spec for truthy to ensure that rules will run consistently across interpreters. (e.g., empty arrays are falsy, string `"0"` is truthy.)

<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"!!": [ [] ] }</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>null</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>false</code></td>
  </tr>
</table>


<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"!!": ["0"] }</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>null</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>true</code></td>
  </tr>
</table>

### `or`
**syntax:** `{"or": [true, false]}`

`or` can be used for simple boolean tests, with 1 or more arguments.

<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"or": [true, false]}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>null</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>true</code></td>
  </tr>
</table>

At a more sophisticated level, or returns the first truthy argument, or the last argument.

<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"or":[false, true]}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>null</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>true</code></td>
  </tr>
</table>


<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"or":[false, "a"]}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>null</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>"a"</code></td>
  </tr>
</table>


<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"or":[false, 0, "a"]}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>null</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>"a"</code></td>
  </tr>
</table>

### `and`
**syntax:** `{"and": [true, true]}`

`and` can be used for simple boolean tests, with 1 or more arguments.

<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"and": [true, true]}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>null</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>true</code></td>
  </tr>
</table>


<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"and": [true, false]}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>null</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>false</code></td>
  </tr>
</table>

At a more sophisticated level, `and` returns the first falsy argument, or the last argument.

<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"and":[true,"a",3]}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>null</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>3</code></td>
  </tr>
</table>


<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"and": [true,"",3]}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>null</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>""</code></td>
  </tr>
</table>


Numeric Operations
------------------

### <a id="arithmetic"></a>Arithmetic `+` `-` `*` `/`
**syntax:** `{"+":[4,2]}`

**syntax:** `{"-":[4,2]}`

**syntax:** `{"*":[4,2]}`

**syntax:** `{"/":[4,2]}`

Addition, subtraction, multiplication, and division.

<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"+":[4,2]}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>null</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>6</code></td>
  </tr>
</table>


<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"-":[4,2]}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>null</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>2</code></td>
  </tr>
</table>


<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"*":[4,2]}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>null</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>8</code></td>
  </tr>
</table>


<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"/":[4,2]}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>null</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>2</code></td>
  </tr>
</table>

Because addition and multiplication are associative, they happily take as many args as you want:

<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"+":[2,2,2,2,2]}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>null</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>10</code></td>
  </tr>
</table>


<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"*":[2,2,2,2,2]}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>null</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>32</code></td>
  </tr>
</table>

Passing just one argument to `-` returns its arithmetic negative (additive inverse).

<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"-": 2}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>null</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>-2</code></td>
  </tr>
</table>


<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"-": -2}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>null</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>2</code></td>
  </tr>
</table>

Passing just one argument to `+` casts it to a number.

<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"+" : "3.14"}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>null</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>3.14</code></td>
  </tr>
</table>

### <a id="modulo"></a>`%`
**syntax:** `{"%": [101,2]}`

Finds the remainder after the first argument is divided by the second argument.

<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"%": [101,2]}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>null</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>1</code></td>
  </tr>
</table>

This can be paired with a loop in the language that parses JsonLogic to create stripes or other effects.

In Javascript:

```javascript
var rule = {"if": [{"%": [{"var":"i"}, 2]}, "odd", "even"]};
for(var i = 1; i <= 4 ; i++){
  console.log(i, jsonLogic.apply(rule, {"i":i}));
}
/* Outputs:
1 "odd"
2 "even"
3 "odd"
4 "even"
*/
```

### <a id="comparison"></a>`>`, `>=`, `<`, and `<=`
**syntax:** `{">" : [2, 1]}`

**syntax:** `{">=" : [1, 1]}`

**syntax:** `{"<" : [1, 2]}`

**syntax:** `{"<=" : [1, 1]}`

### Between

You can use a special case of `<` and `<=` to test that one value is between two others:

Between exclusive:

<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"<" : [1, 2, 3]}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>null</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>true</code></td>
  </tr>
</table>


<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"<" : [1, 1, 3]}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>null</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>false</code></td>
  </tr>
</table>


<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"<" : [1, 4, 3]}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>null</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>false</code></td>
  </tr>
</table>

Between inclusive:

<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"<=" : [1, 2, 3]}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>null</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>true</code></td>
  </tr>
</table>


<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"<=" : [1, 1, 3]}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>null</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>true</code></td>
  </tr>
</table>


<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"<=" : [1, 4, 3]}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>null</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>false</code></td>
  </tr>
</table>

This is most useful with data:

<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{ "<": [0, {"var":"temp"}, 100]}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>{"temp" : 37}</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>true</code></td>
  </tr>
</table>

### `max`
**syntax:** `{"max": [a, b, c, ...]}`

Return the maximum from a list of values.

### `min`
**syntax:** `{"min": [a, b, c, ...]}`

Return the minimum from a list of values.


Array Operations
----------------

### `all`, `some` and `none`
**syntax:** `{"all" : [ [1,2,3], {">":[{"var":""}, 0]} ]}`

These operations take an array, and perform a test on each member of that array.

The most interesting part of these operations is that inside the test code, `var` operations are relative to the array element being tested.

It can be useful to use `{"var":""}` to get the entire array element within the test.

<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"all" : [ [1,2,3], {">":[{"var":""}, 0]} ]}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>null</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>true</code></td>
  </tr>
</table>


<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"some" : [ [-1,0,1], {">":[{"var":""}, 0]} ]}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>null</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>true</code></td>
  </tr>
</table>


<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"none" : [ [-3,-2,-1], {">":[{"var":""}, 0]} ]}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>null</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>true</code></td>
  </tr>
</table>

Or it can be useful to test an object based on its properties:

<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"some" : [ {"var":"pies"}, {"==":[{"var":"filling"}, "apple"]} ]}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>{"pies":[ {"filling":"pumpkin","temp":110}, {"filling":"rhubarb","temp":210}, {"filling":"apple","temp":310} ]}</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>true</code></td>
  </tr>
</table>

Note that `none` will return `true` for an empty array, while `all` and `some` will return `false`.

### <a id="in-array"></a>`in`
**syntax:** `{"in":[ "Ringo", ["John", "Paul", "George", "Ringo"] ]}`

If the second argument is an array, tests that the first argument is a member of the array.

<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"in":[ "Ringo", ["John", "Paul", "George", "Ringo"] ]}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>null</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>true</code></td>
  </tr>
</table>


### `is_array`
See [`isArray`](#isarray)

### `isArray`
**syntax:** `{"isArray": [a]}`

Returns `true` if the given param is an array.

### `join`
**syntax:** `{"join": [",", ["a", "b", "c", ...] ]}`

Convert the elements of an array into a string.

<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"join": [",", ["a", "b", "c"] ]}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>null</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>"a,b,c"</code></td>
  </tr>
</table>

### <a id="length-array"></a>`length`

**syntax:** `{"length": [[a, b, c, ...]]}`

Return length of array.

### `map`, `reduce`, and `filter`
**syntax:** `{"map":[ {"var":"integers"}, {"*":[{"var":""},2]} ]}`

**syntax:** `{"filter":[ {"var":"integers"}, {"%": [{"var":""},2]} ]}`

You can use `map` to perform an action on every member of an array. Note, that inside the logic being used to map, `var` operations are relative to the array element being worked on.

<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
<pre><code>{"map":[
  {"var":"integers"},
  {"*":[{"var":""},2]}
]}
</code></pre>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>{"integers":[1,2,3,4,5]}</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>[ 2, 4, 6, 8, 10 ]</code></td>
  </tr>
</table>

You can use `filter` to keep only elements of the array that pass a test. Note, that inside the logic being used to map, `var` operations are relative to the array element being worked on.

Also note, the returned array will have contiguous indexes starting at zero (typical for JavaScript, Python and Ruby) it will not preserve the source indexes (making it unlike PHP’s `array_filter`).

<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
<pre><code>{"filter":[
  {"var":"integers"},
  {"%":[{"var":""},2]}
]}
</code></pre>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>{"integers":[1,2,3,4,5]}</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>[ 1, 3, 5 ]</code></td>
  </tr>
</table>

You can use `reduce` to combine all the elements in an array into a single value, like adding up a list of numbers. Note, that inside the logic being used to reduce, `var` operations only have access to an object like:

```javascript
{
    "current" : // this element of the array,
    "accumulator" : // progress so far, or the initial value
}
```

<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
<pre><code>{"reduce":[
    {"var":"integers"},
    {"+":[{"var":"current"}, {"var":"accumulator"}]},
    0
]}
</code></pre>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>{"integers":[1,2,3,4,5]}</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>15</code></td>
  </tr>
</table>

### `merge`
**syntax:** `{"merge": [a, b, c, ...]}`

**syntax:** `{"merge": [ [1,2], [3,4] ]}`

Takes one or more arrays, and merges them into one array. If arguments aren’t arrays, they get cast to arrays.

<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"merge":[ [1,2], [3,4] ]}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>null</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>[1, 2, 3, 4]</code></td>
  </tr>
</table>

<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"merge":[ 1, 2, [3,4] ]}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>null</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>[1, 2, 3, 4]</code></td>
  </tr>
</table>


Merge can be especially useful when defining complex missing rules, like which fields are required in a document. For example, this vehicle paperwork always requires the car’s VIN, but only needs the APR and term if you’re financing.

<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
<pre><code>{"missing" :
  { "merge" : [
    "vin",
    {"if": [{"var":"financing"}, ["apr", "term"], [] ]}
  ]}
}
</code></pre>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>{"financing":true}</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>["vin", "apr", "term"]</code></td>
  </tr>
</table>


String Operations
-----------------

### `cat`
**syntax:** `{"cat": ["I love", " pie"]}`

Concatenate all the supplied arguments. Note that this is not a join or implode operation, there is no "glue" string.

<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"cat": ["I love", " pie"]}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>null</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>"I love pie"</code></td>
  </tr>
</table>


<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"cat": ["I love ", {"var":"filling"}, " pie"]}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>{"filling":"apple", "temp":110}</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>"I love apple pie"</code></td>
  </tr>
</table>

### <a id="in-string"></a>`in`
**syntax:** `{"in":["Spring", "Springfield"]}`

If the second argument is a string, tests that the first argument is a substring.

<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"in":["Spring", "Springfield"]}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>null</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>true</code></td>
  </tr>
</table>

### <a id="length-string"></a>`length`

**syntax:** `{"length": ["Hello, World!"]}`

Return length of string.

### `substr`
**syntax:** `{"substr": ["jsonlogic", 1, 3]}`

Get a portion of a string.

Give a positive start position to return everything beginning at that index. (Indexes of course start at zero.)

<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"substr": ["jsonlogic", 4]}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>null</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>"logic"</code></td>
  </tr>
</table>

Give a negative start position to work backwards from the end of the string, then return everything.

<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"substr": ["jsonlogic", -5]}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>null</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>"logic"</code></td>
  </tr>
</table>

Give a positive length to express how many characters to return.

<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"substr": ["jsonlogic", 1, 3]}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>null</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>"son"</code></td>
  </tr>
</table>

Give a negative length to stop that many characters before the end.

<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"substr": ["jsonlogic", 4, -2]}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>null</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>"log"</code></td>
  </tr>
</table>


### `toLowerCase`
**syntax:** `{"toLowerCase": [str]}`

Returns the lower-cased letters of the given string.

### `toUpperCase`
**syntax:** `{"toUpperCase": [str]}`

Returns the upper-cased letters of the given string.

Miscellaneous
-------------

### `log`
**syntax:** `{"log": a}`

Logs the first value to console, then passes it through unmodified.

This can be especially helpful when debugging a large rule.

<table>
  <tr>
    <td><b>Logic</b></td>
    <td>
      <code>{"log":"apple"}</code>
    </td>
  </tr>
  <tr>
    <td><b>Data</b></td>
    <td><code>null</code></td>
  </tr>
  <tr>
    <td><b>Result</b></td>
    <td><code>"apple"</code></td>
  </tr>
</table>
