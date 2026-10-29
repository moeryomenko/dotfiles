; Go assembly is parsed with the `gas` grammar for now (see languages.toml),
; so it reuses the stock Helix GAS queries. Swap these for tree-sitter-goasm
; queries if that grammar is added later.

(comment) @comment
(number) @constant.numeric
(directive_name) @keyword.directive
(symbol) @variable
(label) @function
(label)
(instruction_prefix) @keyword
(instruction_name) @function.special
(register) @constant.builtin
(string) @string
(char) @constant.character
(type) @type
(constant "$" @constant)
(operand_modifier) @attribute

(expression
  ["-" "+" "*" "/" "="] @operator)

["(" ")"] @punctuation.bracket

["," ":"] @punctuation.delimiter
