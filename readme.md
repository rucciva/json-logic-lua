# JSON-LOGIC

lua port of <https://github.com/jwadhams/json-logic-js>.  
luarocks url: <https://luarocks.org/modules/rucciva/json-logic-lua>.  
Differentiation with the original json-logic:

1. empty array is evaluated to true, unlike the original json-logic which evaluate empty array to false.
1. add_operation is simulated by using third parameter named options in Apply()