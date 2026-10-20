; SELinux Type Enforcement — syntax highlighting
; Scopes follow the nvim-treesitter / Helix conventions.

; Comments ---------------------------------------------------------------

(comment) @comment
(m4_dnl) @comment

; Keywords ---------------------------------------------------------------

[
  "type"
  "typealias"
  "typeattribute"
  "attribute"
  "expandattribute"
  "permissive"
  "typebounds"
  "type_transition"
  "type_change"
  "type_member"
  "role"
  "attribute_role"
  "roleattribute"
  "roleallow"
  "role_transition"
  "range_transition"
  "class"
  "common"
  "inherits"
  "alias"
  "types"
  "bool"
  "if"
  "else"
  "require"
  "optional"
  "module"
  "policycap"
  "constrain"
  "validatetrans"
  "mlsconstrain"
  "mlsvalidatetrans"
  "sensitivity"
  "dominance"
  "category"
  "level"
  "sid"
  "genfscon"
  "portcon"
  "nodecon"
  "netifcon"
  "ibpkeycon"
  "ibendportcon"
  "iomemcon"
  "ioportcon"
  "pcidevicecon"
  "devicetreecon"
] @keyword

; Policy rule families are directives
(av_rule_kind) @keyword.directive
(xperm_rule_kind) @keyword.directive
(require_kind) @keyword.directive
(fs_use_kind) @keyword.directive

(portcon_statement
  protocol: [
    "tcp"
    "udp"
    "sctp"
    "dccp"
  ] @constant.builtin)

; m4 / refpolicy macros --------------------------------------------------

(macro_call
  name: (identifier) @function.macro)

(expansion) @variable.parameter

"`" @punctuation.special
"'" @punctuation.special
(m4_quoted) @string.special

; Identifiers ------------------------------------------------------------

; Declared names
(type_declaration name: (identifier) @type)
(typealias_declaration name: (identifier) @type)
(typeattribute_declaration name: (identifier) @type)
(attribute_declaration name: (identifier) @type)
(permissive_declaration name: (identifier) @type)
(typebounds_declaration bounded: (identifier) @type)
(type_transition_declaration default: (identifier) @type)
(type_change_declaration change: (identifier) @type)
(type_member_declaration member: (identifier) @type)
(alias_set (identifier) @type)
(role_declaration name: (identifier) @type)
(attribute_role_declaration name: (identifier) @type)
(class_declaration name: (identifier) @type)
(common_declaration name: (identifier) @type)
(boolean_declaration name: (identifier) @variable)
(sensitivity_declaration name: (identifier) @constant)
(category_declaration name: (identifier) @constant)
(level_statement name: (identifier) @constant)
(require_declaration name: (identifier) @type)
(require_class_declaration name: (identifier) @type)
(module_declaration name: (identifier) @namespace)
(policycap_declaration name: (identifier) @constant)
(sid_statement name: (identifier) @constant)

; References
(type_set (identifier) @type)
(class_set (identifier) @type)
(permission_set (identifier) @attribute)
(roleattribute_declaration attribute: (identifier) @type)
(typeattribute_declaration attribute: (identifier) @type)
(type_declaration attribute: (identifier) @type)
(require_declaration kind: (require_kind) @_kind
  (#any-of? @_kind "role" "attribute_role")
  name: (identifier) @type)

"self" @variable.builtin

; Object classes inside labeling statements
(genfscon_statement filesystem: (identifier) @type)
(fs_use_statement filesystem: (identifier) @type)
(netifcon_statement interface: (identifier) @type)

; Literals ---------------------------------------------------------------

(boolean) @constant.builtin
(number) @constant.numeric
(string) @string
(mls_sensitivity) @constant.numeric
(xperm_range) @constant.numeric
(port_range) @constant.numeric
(memory_range) @constant.numeric
(net_addr) @constant.numeric
(category_range (identifier) @constant.numeric)

; Operators and punctuation ---------------------------------------------

(conditional_operator) @operator
(constraint_operator) @operator

[
  ":"
  "-"
  "~"
  "*"
  "="
] @operator

["{" "}"] @punctuation.bracket
["(" ")"] @punctuation.bracket
["," ";"] @punctuation.delimiter
