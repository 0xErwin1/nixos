;; ============================================================================
;; Comments
;; ============================================================================

(comment) @comment
(doc_comment) @comment.documentation

;; ============================================================================
;; Literals
;; ============================================================================

(string_literal) @string
(char_literal) @character
(integer_literal) @number
(float_literal) @number.float
(boolean_literal) @constant.builtin
(null_literal) @constant.builtin
(atom_literal) @string.special.symbol

;; ============================================================================
;; Punctuation
;; ============================================================================

["(" ")" "{" "}" "[" "]"] @punctuation.bracket

(generic_type_declaration
  "<" @punctuation.bracket
  ">" @punctuation.bracket)

[":" "," ";"] @punctuation.delimiter
"." @punctuation.delimiter
"::" @punctuation.delimiter

;; ============================================================================
;; Operators
;; ============================================================================

[
  "+" "-" "*" "/" "%"
  "&" "|" "^" "~"
  "<<" ">>"
  "!" "&&" "||"
  "++" "--"
] @operator

[
  "=" "+=" "-=" "*=" "/=" "%="
  "&=" "|=" "^=" "<<=" ">>="
] @operator

["==" "!=" "<" ">" "<=" ">="] @operator

[".." "..=" "|>" "->" "..." "?"] @operator

"#" @punctuation.special

;; ============================================================================
;; Keywords
;; ============================================================================

;; Control flow
["if" "else" "match" "when"] @keyword.conditional

["for" "while" "of" "break" "continue"] @keyword.repeat

"return" @keyword.return

;; Declaration keywords
["function" "record" "enum" "type" "namespace" "directive"] @keyword

;; Modifiers
[
  "const" "let" "mut" "static"
  "public" "private" "final"
  "inline" "extern" "export"
] @keyword.modifier

;; Other keywords
["import" "from" "as" "new"] @keyword

;; ============================================================================
;; Special identifiers
;; ============================================================================

(this_expression) @variable.builtin
(self_expression) @variable.builtin

;; Wildcard pattern
(pattern "_" @variable.builtin)

;; ============================================================================
;; Identifier conventions (like Rust)
;; ============================================================================

;; Assume all-caps names are constants (e.g., MAX_SIZE, PI)
((identifier) @constant
  (#match? @constant "^[A-Z][A-Z0-9_]+$"))

;; Assume PascalCase names are types/constructors (e.g., Ok, Err, Some, None)
((identifier) @constructor
  (#match? @constructor "^[A-Z][a-z]"))

;; ============================================================================
;; Types
;; ============================================================================

;; Primitive types
(primitive_keyword) @type.builtin

;; Type identifiers in type positions
(type_identifier
  (base_type
    (qualified_identifier) @type))

(type_identifier
  (base_type
    (primitive_keyword) @type.builtin))

;; Pointer and reference modifiers in types
(type_identifier
  (pointer_specifier) @operator)
(type_identifier
  (reference_operator) @operator)
(type_identifier
  (mutable_specifier) @keyword.modifier)

;; ============================================================================
;; Functions and Methods
;; ============================================================================

;; Function declarations
(function_declaration
  name: (identifier) @function)

;; Extern function declarations
(extern_function
  name: (identifier) @function)

;; Method declarations
(method_declaration
  name: (identifier) @function.method)
(record_method_declaration
  name: (identifier) @function.method)
(enum_method_declaration
  name: (identifier) @function.method)

;; Function calls
(call_expression
  function: (primary_expression
    (identifier) @function.call))

;; Method calls (including chained)
(method_call_expression
  function: (property_access
    name: (identifier) @function.method.call))

;; Lambda arrow
(lambda_expression
  "->" @operator)

;; ============================================================================
;; Variables, Constants, and Parameters
;; ============================================================================

;; Variable declarations
(variable_declaration
  name: (identifier) @variable)

;; Constant declarations
(const_declaration
  name: (identifier) @constant)

;; Parameter declarations
(parameter_declaration
  name: (identifier) @variable.parameter)

;; For loop variable
(for_variable_declaration
  (identifier) @variable)

;; ============================================================================
;; Records and Enums
;; ============================================================================

;; Record declarations
(record_declaration
  name: (identifier) @type)

;; Record properties/fields
(record_property_declaration
  name: (identifier) @property)

;; Enum declarations
(enum_declaration
  name: (identifier) @type)

;; Enum variants
(enum_variant_declaration
  name: (identifier) @constant)

;; ============================================================================
;; Type Definitions
;; ============================================================================

(type_definition
  (identifier) @type.definition)

;; ============================================================================
;; Namespaces and Modules
;; ============================================================================

(namespace_declaration
  (qualified_identifier
    (identifier) @module))

;; First part of qualified identifier is module/namespace
(qualified_identifier
  . (identifier) @module)

(scoped_identifier
  . (identifier) @module)

;; ============================================================================
;; Imports
;; ============================================================================

(import_statement
  (identifier) @type)

;; ============================================================================
;; Properties and Field Access
;; ============================================================================

;; Field/property access (not method calls - those are handled above)
(property_access
  name: (identifier) @property)

;; Vector/array access
(vector_access_expression
  (identifier) @variable)

;; Object literal keys
(object_literal
  (identifier) @property)

;; ============================================================================
;; Directives and Attributes
;; ============================================================================

(directive_attr
  "#" @punctuation.special)

(directive_attr_item
  (qualified_identifier) @attribute)

(directive_expression
  "#" @punctuation.special)

;; ============================================================================
;; Extern Declarations
;; ============================================================================

(extern_declaration
  "extern" @keyword.modifier)

;; Extern namespace name
(extern_declaration
  (qualified_identifier
    (identifier) @module))

;; ============================================================================
;; Match Expressions
;; ============================================================================

(match_expression
  "match" @keyword.conditional)

(match_arm
  "->" @operator)

;; ============================================================================
;; Fallback - General identifiers (lowest priority)
;; ============================================================================

(identifier) @variable

