; Git commit message highlights

; Subject line (first line)
(subject) @markup.heading.1

; Body text
(message_line) @markup.raw

; Comment lines (git status info)
(comment) @comment

; Section titles within comments (e.g. "Changes to be committed:")
(title) @markup.heading.2

; Comment marker (#)
(comment
  "#" @punctuation.special)
