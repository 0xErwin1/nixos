[
  (block)
] @indent.begin

(block
  "}" @indent.end)

(_ "[" "]" @end) @indent
(_ "{" "}" @end) @indent
(_ "(" ")" @end) @indent

[
  (comment)
  (doc_comment)
] @indent.ignore
