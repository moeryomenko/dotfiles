; SELinux Type Enforcement — text objects

; Comments
(comment) @comment.inside
(comment) @comment.outside
(m4_dnl) @comment.inside
(m4_dnl) @comment.outside

; Policy rules select like functions (mif / maf on allow, neverallow, ...)
[
  (av_rule)
  (xperm_rule)
  (type_transition_declaration)
  (type_change_declaration)
  (type_member_declaration)
  (role_transition_declaration)
  (range_transition_declaration)
] @function.inside
[
  (av_rule)
  (xperm_rule)
  (type_transition_declaration)
  (type_change_declaration)
  (type_member_declaration)
  (role_transition_declaration)
  (range_transition_declaration)
] @function.outside

; Blocks (require, optional, if bodies) select like classes
[
  (require_block)
  (optional_block)
  (if_statement)
] @class.inside
[
  (require_block)
  (optional_block)
  (if_statement)
] @class.outside

; Macro arguments select like parameters
(macro_argument) @parameter.inside

(macro_call
  "(" @_start
  .
  (_) @parameter.outer
  .
  ","? @_end
  (#make-range! "parameter.outer" @_start @_end))? 

(macro_call
  "," @_start
  .
  (_) @parameter.outer
  (#make-range! "parameter.outer" @_start @parameter.outer))
