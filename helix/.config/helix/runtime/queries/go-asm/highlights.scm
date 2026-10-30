; From tree-sitter-goasm 79ce6dd3a7795030cb4d8a4266eecee272738560 (Apache-2.0).
; Capture names adapted to Helix theme scopes.
; Tree-sitter highlights for Go (Plan 9) assembly.
; Capture names follow the nvim-treesitter convention so they work in Neovim,
; Helix, Zed, and other editors that consume the standard set.
;
; Where two rules could match the same node, the more specific rule appears
; LAST. nvim-treesitter resolves ties by first-match, Helix by last-match, so
; the safer convention is to avoid double-tagging — every node here is captured
; at most once for a given highlight role.

; ----------------------------------------------------------------------------
; Comments
; ----------------------------------------------------------------------------

(comment) @comment

; Go toolchain build pragmas embedded in line comments — `//go:build`,
; `//go:generate`, `//go:cgo_*`, `//go:linkname`, `//go:nosplit`, etc. The
; grammar tokenizes the whole line as `(comment)`, so override at the query
; level. `//line` is a Plan-9 preprocessor pragma in its own right but also
; appears in comment form in some files.
((comment) @keyword.directive
  (#match? @keyword.directive "^//(go:[a-z_]+|line[: ])"))

; ----------------------------------------------------------------------------
; Preprocessor (#include / #define / #ifdef ...)
; ----------------------------------------------------------------------------

(preprocessor_directive
  "#" @keyword.directive)

(preprocessor_directive
  name: (preprocessor_name) @keyword.directive)

(preprocessor_directive
  name: (preprocessor_name) @keyword.import
  (#any-of? @keyword.import "include"))

(preprocessor_directive
  name: (preprocessor_name) @keyword.conditional
  (#any-of? @keyword.conditional "if" "ifdef" "ifndef" "elif" "else" "endif"))

(preprocessor_directive
  name: (preprocessor_name) @keyword.directive.define
  (#any-of? @keyword.directive.define "define" "undef" "line"))

; The grammar collapses #include / #define arguments into a single text token
; (no named child), so capture the wrapper and tint by text shape.
((preprocessor_directive
   name: (preprocessor_name) @keyword.import
   argument: (preprocessor_argument) @string.special.path)
  (#eq? @keyword.import "include")
  (#match? @string.special.path "^\""))

((preprocessor_directive
   name: (preprocessor_name) @keyword.directive
   argument: (preprocessor_argument) @constant.macro)
  (#any-of? @keyword.directive "define" "undef" "ifdef" "ifndef"))

; ----------------------------------------------------------------------------
; Labels
; ----------------------------------------------------------------------------

(label_definition) @label

; ----------------------------------------------------------------------------
; Directives — built-in keywords
; ----------------------------------------------------------------------------

(text_directive "TEXT" @keyword.function)
(data_directive "DATA" @keyword.directive)
(global_directive "GLOBL" @keyword.directive)
(funcdata_directive "FUNCDATA" @keyword.directive)
(pcdata_directive "PCDATA" @keyword.directive)
(pcalign_directive "PCALIGN" @keyword.directive)

(generic_directive
  name: (identifier) @keyword.directive)

; The function symbol named by TEXT is the function definition itself.
(text_directive
  symbol: (symbol_address
            base: (symbol_reference) @function))

(global_directive
  symbol: (symbol_address
            base: (symbol_reference) @variable))

(data_directive
  symbol: (symbol_address
            base: (symbol_reference) @variable))

(funcdata_directive
  symbol: (symbol_address
            base: (symbol_reference) @variable))

; ----------------------------------------------------------------------------
; Frame size and flags
; ----------------------------------------------------------------------------

(text_frame "$" @punctuation.special)
(text_frame "-" @operator)

; Known Plan 9 link-flag identifiers — `+` and `|` operators between them are
; handled by the operator rule below. Single rule with #any-of? avoids the
; double-capture footgun the reviewers flagged.
((flag_set
   first: (identifier) @constant.builtin)
  (#any-of? @constant.builtin
    "NOSPLIT" "NOFRAME" "WRAPPER" "NEEDCTXT" "TLSBSS" "NOPTR" "RODATA"
    "NOPROF" "DUPOK" "REFLECTMETHOD" "TOPFRAME" "ABIINTERNAL" "LOCAL"))

((flag_set
   more: (identifier) @constant.builtin)
  (#any-of? @constant.builtin
    "NOSPLIT" "NOFRAME" "WRAPPER" "NEEDCTXT" "TLSBSS" "NOPTR" "RODATA"
    "NOPROF" "DUPOK" "REFLECTMETHOD" "TOPFRAME" "ABIINTERNAL" "LOCAL"))

(flag_set operator: _ @operator)

; ----------------------------------------------------------------------------
; Instructions
; ----------------------------------------------------------------------------

(instruction
  mnemonic: (instruction_name) @function.call)

; Highlight RET / branch-style mnemonics specially. Plan 9 mnemonics vary per
; arch, so we match the most common control-flow shapes by name.
((instruction
   mnemonic: (instruction_name) @keyword.return)
  (#any-of? @keyword.return "RET" "RETURN" "IRET" "IRETQ"))

((instruction
   mnemonic: (instruction_name) @function.call
   (operand_list
     (operand
       (address
         (symbol_address
           base: (symbol_reference) @function)))))
  (#any-of? @function.call "CALL" "BL" "BLR" "JAL" "JALR"))

; ----------------------------------------------------------------------------
; Operands
; ----------------------------------------------------------------------------

(register) @variable.builtin
(pseudo_register) @variable.builtin

; The `g` goroutine pseudo and the special RISC-V `ZERO`/`RA` registers appear
; in operand position as bare symbol_references. Tag them as builtin so they
; don't render as ordinary identifiers.
((symbol_reference) @variable.builtin
  (#any-of? @variable.builtin "g" "ZERO" "RA"))

; Operand-position symbol_references for non-call instructions (data loads,
; branch targets, etc.) get @variable. Call mnemonics are handled separately
; below so their target reads as @function instead of @variable.
((instruction
   mnemonic: (instruction_name) @function.call
   (operand_list
     (operand
       (address
         (symbol_address
           base: (symbol_reference) @variable)))))
  (#not-any-of? @function.call "CALL" "BL" "BLR" "JAL" "JALR"))

(instruction
  (operand_list
    (operand
      (expression (symbol_reference) @variable))))

(expression
  (symbol_reference) @variable)

; Immediate values always lead with `$`.
(immediate "$" @punctuation.special)

; ----------------------------------------------------------------------------
; Literals
; ----------------------------------------------------------------------------

(number_literal) @constant.numeric
(string_literal) @string
(rune_literal) @constant.character

; ----------------------------------------------------------------------------
; Expressions / operators
; ----------------------------------------------------------------------------

(expression operator: _ @operator)
(offset ["+" "-"] @operator)

; ----------------------------------------------------------------------------
; Address forms
; ----------------------------------------------------------------------------

(address_width "/" @operator)
(address_index "*" @operator)

; ----------------------------------------------------------------------------
; Punctuation
; ----------------------------------------------------------------------------

["(" ")"] @punctuation.bracket
"," @punctuation.delimiter
