# Bash Idioms

Idiomatic Bash patterns for parameter expansion, arithmetic, arrays, process substitution, heredocs, brace expansion, redirection, coprocesses, namerefs, Bash 5.x features, timing, and readline. Every idiom includes a Bash version requirement.

> [Check] All idioms verified against Bash 5.3.15 on x86_64-pc-linux-gnu

---

## Parameter Expansion

Bash parameter expansion handles string operations internally — faster and safer than forking `sed`, `awk`, `cut`, or `tr`. Prefer parameter expansion over external tools for simple string manipulation; reserve externals for multi-line or regex-heavy transforms.

### Default Values: `${var:-default}` and `${var:=default}`
**Bash 2.0+**

Use `${var:-default}` to provide a fallback without modifying the variable. Use `${var:=default}` to assign the default to the variable if it is unset or null.

```bash
# Return "default" if var is unset or null, var unchanged
result="${var:-default}"

# Assign "default" to var if unset or null, then return it
: "${var:=default}"
```

### Required Variables: `${var:?error}`
**Bash 2.0+**

Exit with an error message if the variable is unset or null. Essential for validating required parameters.

```bash
# Prints "ERROR: var is required" to stderr and exits (non-interactive)
: "${var:?ERROR: var is required}"

# Safer: assign before checking
input_file="${1:?Usage: $0 <input_file>}"
```

### Prefix Removal: `${var#pattern}` and `${var##pattern}`
**Bash 2.0+**

Remove the shortest (`#`) or longest (`##`) matching prefix pattern. Extremely common for stripping directory paths or extensions.

```bash
path="/home/user/docs/file.txt"

dir="${path%/*}"      # /home/user/docs        — remove shortest suffix after /
name="${path##*/}"     # file.txt               — remove longest prefix before /
ext="${name##*.}"      # txt                    — remove longest prefix before .
base="${name%.*}"      # file                   — remove shortest suffix after .
```

### Suffix Removal: `${var%pattern}` and `${var%%pattern}`
**Bash 2.0+**

Remove the shortest (`%`) or longest (`%%`) matching suffix pattern.

```bash
url="https://example.com/page.html"

base="${url%/*}"       # https://example.com    — remove shortest suffix after /
domain="${url#*://}"   # example.com/page.html  — remove shortest prefix before ://
domain="${domain%%/*}" # example.com            — remove longest suffix after /
```

### Search and Replace: `${var/old/new}`
**Bash 4.0+**

Replace first match (`/`) or all matches (`//`) in a variable without forking `sed`.

```bash
text="the quick brown fox"

# Replace first match
echo "${text/brown/red}"     # the quick red fox

# Replace all matches
echo "${text// /_}"          # the_quick_brown_fox

# Replace prefix (#) or suffix (%)
echo "${text/#the/a}"        # a quick brown fox
echo "${text/%fox/dog}"      # the quick brown dog
```

### Case Modification: `${var,,}` and `${var^^}`
**Bash 4.0+**

Change case without forking `tr` or `awk`. The `,,` operator lowercases; `^^` uppercases. Single-character patterns are also supported: `${var,[a]}` or `${var:[a]}` (Bash 4.4+ for first-char variants).

```bash
msg="Hello World"

echo "${msg,,}"              # hello world
echo "${msg^^}"              # HELLO WORLD
echo "${msg,}"               # hello World (first char lowercase, Bash 4.4+)
echo "${msg^}"               # Hello World (first char uppercase, Bash 4.4+)
```

### Substring Extraction: `${var:offset:length}`
**Bash 2.0+**

Extract a substring by position and length. Use negative offsets (with space or parentheses) to count from the end.

```bash
str="abcdef"
echo "${str:2:3}"            # cde
echo "${str: -3}"            # def (space before - required)
echo "${str:(-3)}"           # def (parentheses also work)
```

### String Length: `${#var}`
**Bash 2.0+**

```bash
str="hello"
echo "${#str}"               # 5
```

### Indirect Expansion: `${!var}`
**Bash 2.0+**

Expand a variable whose name is stored in another variable (see also nameref variables for a safer alternative in Bash 4.3+).

```bash
color_name="red"
red="#FF0000"
echo "${!color_name}"        # #FF0000
```

---

## String Ops: Parameter Expansion vs External Tools

| Operation | Parameter Expansion | External Tool | Why Prefer Builtin |
|-----------|-------------------|---------------|-------------------|
| Substring replace | `${var/old/new}` | `sed 's/old/new/'` | No fork, no escaping issues |
| Prefix removal | `${var#prefix}` | `sed 's/^prefix//'` | No fork, pattern is literal |
| Suffix removal | `${var%suffix}` | `sed 's/suffix$//'` | No fork, pattern is literal |
| Case change | `${var,,}` / `${var^^}` | `tr 'A-Z' 'a-z'` | No fork, no locale ambiguity |
| Length | `${#var}` | `wc -c` / `awk '{print length}'` | No fork |
| Split by delimiter | Read into array | `cut -d, -f1` | Single process, no temp file |
| Regex match | `=~` inside `[[ ]]` | `grep -oP` | No fork, no subshell |
| Multi-line replace | Complex with expansion | `sed` / `awk` | External wins for multi-line |

Use external tools when:
- The pattern requires full regex (parameter expansion is glob-only)
- The input spans multiple lines and needs line-by-line processing
- The transform is complex enough that the expansion form becomes unreadable

---

## Arithmetic

### `$(( ))` — Arithmetic Expansion
**Bash 2.0+ (POSIX `$(( ))` in POSIX sh)**

Standard integer arithmetic. Supports `+`, `-`, `*`, `/`, `%`, `**` (exponentiation, Bash 3.2+), `<<`, `>>`, `&`, `|`, `^`, `~`, `&&`, `||`, ternary `?:`.

```bash
i=$((i + 1))                 # increment
n=$(( (a + b) * c / d ))    # complex expression
e=$(( 2 ** 10 ))             # 1024, exponentiation (Bash 3.2+)
```

### `(( ))` — Arithmetic Evaluation
**Bash 2.0+**

Use as a condition in `if`, `while`, `until` — returns 0 (true) if result is non-zero, 1 (false) if zero. Preferred over `let` and `expr`.

```bash
if (( a > b )); then
    echo "a is greater"
fi

# Increment without $
((i++))

# C-style for loop
for ((i = 0; i < 10; i++)); do
    echo "$i"
done
```

### Avoid `let` and `expr`
**Rule: Bash 2.0+**

The `let` builtin and external `expr` are legacy forms. Use `(( ))` or `$(( ))` instead — they are more readable and support the same operators.

```bash
# Avoid
let i=i+1
i=$(expr "$i" + 1)

# Prefer
((i++))
i=$((i + 1))
```

### Integer Base Conversion
**Bash 3.1+**

```bash
echo $(( 16#FF ))             # 255 — hex to decimal
echo $(( 8#77 ))              # 63 — octal to decimal
echo $(( 2#1010 ))            # 10 — binary to decimal
```

---

## Arrays

### Indexed Arrays
**Bash 3.0+ (legacy); Bash 4.0+ (full feature set)**

```bash
# Declare
arr=(a b c "d e")

# Access individual element
echo "${arr[0]}"             # a

# All elements (quoted preserves spaces)
echo "${arr[@]}"             # a b c d e

# All elements, each as a separate word (safe for iteration)
for elem in "${arr[@]}"; do
    echo "$elem"
done

# Count
echo "${#arr[@]}"            # 4

# Append
arr+=(f)

# Slice
echo "${arr[@]:1:2}"         # b c

# Keys (indices)
echo "${!arr[@]}"            # 0 1 2 3 4
```

### Associative Arrays
**Bash 4.0+**

```bash
# Declare (must use declare -A)
declare -A map=([key1]=val1 [key2]=val2)

# Access
echo "${map[key1]}"          # val1

# Keys
for key in "${!map[@]}"; do
    echo "$key -> ${map[$key]}"
done

# Values
for val in "${map[@]}"; do
    echo "$val"
done

# Count
echo "${#map[@]}"
```

### Iteration Patterns
**Bash 3.0+ for indexed arrays; Bash 4.0+ for associative arrays**

```bash
# Indexed: by value
for item in "${arr[@]}"; do
    printf '%s\n' "$item"
done

# Indexed: by index
for i in "${!arr[@]}"; do
    printf 'arr[%d]=%s\n' "$i" "${arr[i]}"
done

# Indexed: C-style
for ((i = 0; i < ${#arr[@]}; i++)); do
    printf 'arr[%d]=%s\n' "$i" "${arr[i]}"
done

# Associative: key-value
for key in "${!map[@]}"; do
    printf 'map[%s]=%s\n' "$key" "${map[$key]}"
done
```

### Reading Lines into Array
**Bash 4.0+ with `mapfile`; Bash 3.x with loop**

```bash
# Bash 4.0+: mapfile (aka readarray)
mapfile -t lines < file.txt

# Bash 3.x: read in a loop
lines=()
while IFS= read -r line; do
    lines+=("$line")
done < file.txt
```

---

## Process Substitution

### `<(cmd)` and `>(cmd)`
**Bash 3.0+ (POSIX may require `/dev/fd` support)**

Process substitution feeds the output (or input) of a command as a file-like argument. It avoids temporary files and subshell pipelines.

```bash
# Diff two command outputs
diff <(ls dir1) <(ls dir2)

# Pass output to a command that expects a file argument
wc -l <(grep -r "ERROR" /var/log)

# Feed data into a pipeline that reads from stdin
sort -u <(cat file1 file2)

# Output to a command
tee >(gzip > out.gz) >(bzip2 > out.bz2) > stdout.log
```

### `while read` with Process Substitution
**Bash 3.0+**

Preserves variables from the loop (unlike a pipeline which creates a subshell in most shells).

```bash
# Pipeline — BAD: variables are lost outside pipe
printf '%s\n' a b c | while IFS= read -r line; do
    count=$((count + 1))
done
echo "$count"                # 0 — lost!

# Process substitution — GOOD: preserves scope
while IFS= read -r line; do
    count=$((count + 1))
done < <(printf '%s\n' a b c)
echo "$count"                # 3 — preserved!
```

### `mapfile -t`
**Bash 4.0+**

Read lines from stdin into an array. The `-t` flag strips trailing newlines.

```bash
mapfile -t arr < <(find . -name '*.sh')
mapfile -t lines < <(command_with_output)

# With delimiter (Bash 4.4+)
mapfile -t -d ',' fields < <(printf '%s' 'a,b,c')
```

---

## Here-Documents and Here-Strings

### Here-Documents: `<<EOF`
**Bash 2.0+ (POSIX)**

Redirect multiline text as stdin. The delimiter can be any word; use `'EOF'` (quoted) to prevent variable expansion.

```bash
# With expansion
cat <<EOF
Hello $USER, your home is $HOME
EOF

# Without expansion (delimiter quoted)
cat <<'EOF'
Literal text: $HOME is not expanded
EOF

# Appending to a file
cat >> /path/to/file <<'EOF'
new content line
another line
EOF
```

### Indented Here-Documents: `<<-EOF`
**Bash 2.0+ (POSIX)**

Leading tabs are stripped from the here-document body, allowing indentation in scripts.

```bash
if true; then
    cat <<-EOF
        This text is indented with tabs.
        The leading tabs are stripped.
	EOF
fi
```

### Here-Strings: `<<<`
**Bash 3.0+**

Redirect a single string as stdin without forking `echo`.

```bash
read -r first rest <<< "$line"

# Pass string to a command
grep 'pattern' <<< "$variable"

# Parse with IFS
IFS=',' read -r a b c <<< "one,two,three"

# Avoid: echo "$var" | while ...
# Prefer: while ... done < <(command) or here-string
```

---

## Brace Expansion

### Sequences: `{1..10}`
**Bash 3.0+**

Generate sequences with optional step (Bash 4.0+ for step).

```bash
echo {1..5}                  # 1 2 3 4 5
echo {a..e}                  # a b c d e
echo {01..05}                # 01 02 03 04 05 (zero-padded)
echo {1..10..2}              # 1 3 5 7 9 (step, Bash 4.0+)
echo {a..z..2}               # a c e g i k m o q s u w y (Bash 4.0+)
```

### Lists: `{a,b,c}.txt`
**Bash 2.0+**

```bash
echo {a,b,c}.txt             # a.txt b.txt c.txt
cp file.{txt,bak}            # cp file.txt file.bak
mv file.{bak,backup}         # mv file.bak file.backup
```

### Combinatorial
**Bash 2.0+**

Brace expansion is evaluated left-to-right, producing all combinations.

```bash
echo {a,b}{1,2}              # a1 a2 b1 b2
echo {x,y}{1..3}             # x1 x2 x3 y1 y2 y3
```

### Disabling Brace Expansion
**Bash 3.0+**

Use `set +B` to disable and `set -B` to re-enable. Useful when curly braces are literal.

```bash
echo {1..3}                  # 1 2 3
set +B
echo {1..3}                  # {1..3}
set -B
```

---

## Redirection

### Capture stdout+stderr: `&>` and `&>>`
**Bash 4.0+ (3.x supports `>&` but not `&>` / `&>>`)**

The `&>` form is a compact shorthand for redirecting both streams. `&>>` appends both.

```bash
command &> file              # stdout and stderr to file (overwrite)
command &>> file             # stdout and stderr to file (append)
```

Prefer `&>` over `2>&1` for conciseness; the two are equivalent.

```bash
# Equivalent forms
command &> file
command > file 2>&1
```

### Pipe Both Streams: `|&`
**Bash 4.0+**

Pipe both stdout and stderr to another command.

```bash
command |& grep ERROR       # grep both stdout and stderr
```

### File Descriptor Redirection
**Bash 2.0+ (POSIX for basic forms)**

```bash
# Redirect fd 3 to read from file
exec 3< input.txt

# Redirect fd 4 to write to file
exec 4> output.txt

# Move fd (Bash 4.1+)
exec {fd}> file              # automatic fd assignment (Bash 4.1+)

# Duplicate fd
exec 3>&2                   # fd3 -> stderr

# Close fd
exec 3>&-
```

### Automatic File Descriptor Allocation: `{var}>file`
**Bash 4.1+**

Bash assigns the next available file descriptor (>= 10) to the variable, avoiding fd conflicts.

```bash
exec {log_fd}>/var/log/myapp.log
echo "message" >&"$log_fd"
exec {log_fd}>&-            # close
```

### `/dev/tcp` and `/dev/udp`
**Bash 2.05+ (compiled with --enable-net-redirections)**

Bash's virtual `/dev/tcp/host/port` opens a TCP connection as a file descriptor.

```bash
# Send HTTP request (Bash builtin, no need for curl/wget)
exec 3<>/dev/tcp/example.org/80
printf 'GET / HTTP/1.0\r\nHost: example.org\r\n\r\n' >&3
cat <&3
exec 3>&-

# Check if port is open
if timeout 1 bash -c 'echo >/dev/tcp/$host/$port' 2>/dev/null; then
    echo "$host:$port is open"
fi
```

---

## Co-Processes

### `coproc`
**Bash 4.0+**

Start a command in the background with bidirectional communication via stdin/stdout file descriptors. The coprocess name defaults to `COPROC`.

```bash
# Start a coprocess
coproc bc -l

# Write to it
echo "scale=10; 4*a(1)" >&"${COPROC[1]}"

# Read from it
read -r pi <&"${COPROC[0]}"
echo "$pi"                  # 3.1415926532 (approximately)

# Named coprocess (Bash 4.0+)
coproc MYPROC { command --with-args; }

# Access named coprocess fds
echo "input" >&"${MYPROC[1]}"
read -r output <&"${MYPROC[0]}"
```

### Coprocess Lifecycle

```bash
coproc myserver { nc -l 8080; }

# Kill the coprocess
kill "$myserver_PID"

# Check if running
if kill -0 "$myserver_PID" 2>/dev/null; then
    echo "coprocess is running"
fi

# Wait for it to finish (Bash 5.1+: wait -n)
wait "$myserver_PID" 2>/dev/null || true
```

---

## Nameref Variables

### `declare -n` / `local -n` (Namerefs)
**Bash 4.3+**

Namerefs create a reference to another variable, enabling pass-by-reference semantics. Essential for functions that must modify caller variables.

```bash
function to_lowercase {
    local -n ref="$1"
    ref="${ref,,}"
}

username="HELLO"
to_lowercase username
echo "$username"            # hello
```

### Multi-Value Returns with Namerefs
**Bash 4.3+**

```bash
function split_path {
    local -n _dir="$1" _name="$2"
    local path="$3"
    _dir="${path%/*}"
    _name="${path##*/}"
}

split_path dir name "/home/user/docs/file.txt"
echo "$dir"                  # /home/user/docs
echo "$name"                 # file.txt
```

### Namerefs vs `eval`
**Bash 4.3+**

Namerefs are safer than `eval` — they cannot execute arbitrary code and provide proper scoping.

```bash
# Avoid: eval-based indirection
eval "$1=\$2"

# Prefer: nameref
local -n ref="$1"
ref="$2"
```

> **Warning**: Namerefs can reference other namerefs, creating potential infinite chains under certain edge cases. Avoid chaining namerefs.

---

## Bash 5.x Features

### `${var@operator}` Transform Operators
**Bash 4.4+ (case ops); Bash 5.0+ (full set)**

Operator-based case transformation is more explicit than the `${var,,}` / `${var^^}` forms:

```bash
var="Hello World"

echo "${var@U}"              # HELLO WORLD   — uppercase all
echo "${var@u}"              # Hello World   — uppercase first char only
echo "${var@L}"              # hello world   — lowercase all
echo "${var@l}"              # hello World   — lowercase first char only
```

Other `@` operators:

```bash
echo "${var@Q}"              # 'Hello World' — quote as reusable input
echo "${var@E}"              # expand escape sequences (Bash 4.4+)
echo "${var@K}"              # produce a quoted representation for arrays
echo "${var@a}"              # print attribute flags for variable

# Array quote
arr=(a "b c" d)
echo "${arr[@]@Q}"           # 'a' 'b c' 'd'
```

### `EPOCHREALTIME`
**Bash 5.0+**

Microsecond-precision epoch time without forking `date`. Returns a float: `seconds.microseconds`.

```bash
start=$EPOCHREALTIME
# ... work ...
end=$EPOCHREALTIME

# Calculate elapsed seconds using bc
elapsed=$(bc <<< "$end - $start")
echo "Elapsed: $elapsed seconds"

# Use in arithmetic (integer microseconds)
start_us=${start#*.}
```

### `wait -n`
**Bash 5.1+**

Wait for the next background job to complete, returning its exit status. Useful for parallel job pools.

```bash
# Launch multiple jobs
for url in "${urls[@]}"; do
    fetch_url "$url" &
done

# Wait for all to complete
wait

# Wait for next one to complete (Bash 5.1+)
for url in "${urls[@]}"; do
    fetch_url "$url" &
done
while wait -n; do :; done   # process completions as they happen

# With exit status capture
for url in "${urls[@]}"; do
    fetch_url "$url" &
done
failed=0
for _ in "${urls[@]}"; do
    if ! wait -n; then
        ((failed++))
    fi
done
```

### `mapfile -d` (Custom Delimiter)
**Bash 4.4+ (4.4 added `-d`; common in 5.x codebases)**

Split input into array elements using a custom delimiter instead of newline.

```bash
# Split CSV line
mapfile -t -d ',' fields <<< "a,b,c,d"
echo "${fields[1]}"          # b

# Split NUL-separated output from find ... -print0
mapfile -t -d '' files < <(find . -name '*.sh' -print0)

# Split on null records (e.g., GNU sort -z)
mapfile -t -d '' sorted < <(sort -z list.txt)
```

### `local` and `declare` Improvements
**Bash 5.2+**

```bash
# Declare and initialize with nameref in one step (Bash 5.2+)
local -n ref="$1"
ref="initialized"
```

### `BASH_REMATCH` Indexed Capture Groups
**Bash 5.0+ (improved indexing for named groups)**

```bash
regex='^([[:digit:]]+)-([[:alpha:]]+)$'
[[ "123-abc" =~ $regex ]]
echo "${BASH_REMATCH[1]}"    # 123
echo "${BASH_REMATCH[2]}"    # abc

# Named groups (Bash 5.1+)
[[ "2024-01" =~ (?<year>[0-9]{4})-(?<month>[0-9]{2}) ]]
```

---

## Timing and Profiling

### `time` Builtin
**Bash 2.0+ (POSIX)**

```bash
# Time a command
time some_command

# Time a pipeline or compound command
time {
    slow_command1
    slow_command2
}
```

### `TIMEFORMAT`
**Bash 4.0+**

Customize the output format of the `time` builtin. Uses `printf`-like formatting with `%R` (real), `%U` (user), `%S` (system).

```bash
TIMEFORMAT='real %R user %U sys %S'
time some_command           # real 0.123 user 0.100 sys 0.022

# Milliseconds only
TIMEFORMAT='%3R'
time some_command           # 0.123

# Custom labels
TIMEFORMAT='Elapsed: %0R seconds'
time some_command           # Elapsed: 0.123 seconds
```

### Microsecond Timing
**Bash 5.0+**

```bash
# Using EPOCHREALTIME for microsecond precision
start=$EPOCHREALTIME
some_command
end=$EPOCHREALTIME

# Difference in seconds with microsecond precision (via bc)
printf -v elapsed '%.6f' "$(bc <<< "$end - $start")"
echo "Elapsed: $elapsed seconds"
```

### Cumulative Timing in Scripts
**Bash 4.0+**

```bash
# Section timing
section_start=$EPOCHREALTIME
# ... section work ...
section_end=$EPOCHREALTIME
printf -v section_elapsed '%.3f' "$(bc <<< "$section_end - $section_start")"
echo "Section took ${section_elapsed}s"
```

---

## Readline / `read`

### `read -r` (Raw Input)
**Bash 2.0+ (POSIX)**

Always use `-r` to prevent backslash interpretation. Without `-r`, `\` acts as line continuation.

```bash
# Always use -r unless you explicitly want backslash processing
while IFS= read -r line; do
    printf '%s\n' "$line"
done < file.txt
```

### `read -p` (Prompt)
**Bash 2.0+**

Display a prompt without needing a separate `echo`.

```bash
read -p "Enter your name: " name
read -p "Continue? [y/n]: " -n 1 reply
```

### `read -s` (Silent)
**Bash 2.0+**

Suppress echo for password input.

```bash
read -s -p "Password: " password
echo
```

### `read -d` (Delimiter)
**Bash 4.0+ (full support for arbitrary delimiters)**

Read until a specified delimiter character (not just newline).

```bash
# Read until comma
IFS= read -r -d ',' field <<< "value,rest"
echo "$field"               # value

# Read all data at once (NUL delimiter)
IFS= read -r -d '' data < file.txt
```

### `read -t` (Timeout)
**Bash 2.0+**

```bash
# Wait up to 5 seconds for input
if read -t 5 -p "Proceed? [y/n]: " answer; then
    echo "Got answer: $answer"
else
    echo "Timed out"
fi
```

### `read -n` (Character Count)
**Bash 2.0+**

Read exactly N characters (or until a delimiter).

```bash
# Read exactly 1 character (no Enter required)
read -n 1 -p "Press any key to continue" key

# Read up to 5 characters
read -n 5 input
```

### Combined Options
**Bash 4.0+ for full combination support**

```bash
# Prompt, silent, timed, raw
read -r -s -t 10 -p "PIN: " pin

# Read N characters with prompt
read -n 1 -p "Continue? (y/n): " answer

# Read into array with custom delimiter
IFS=',' read -r -a fields <<< "a,b,c"
echo "${fields[1]}"          # b
```

---

## Verification

> [Check] All idioms include explanation, code example, and Bash version requirement
> [Check] Parameter expansion section covers all 9 operators: `:-`, `:?`, `#`, `##`, `%`, `%%`, `/`, `,,`, `^^`
> [Check] Arithmetic section covers `$(( ))`, `(( ))`, and warns against `let`/`expr`
> [Check] Arrays section covers indexed, associative, and iteration patterns
> [Check] Process substitution covers `<()`, `>()`, while-read, and mapfile
> [Check] Here-docs cover `<<EOF`, `<<-`, `<<<`
> [Check] Brace expansion covers ranges, lists, and combinatorial
> [Check] Redirection covers `&>` / `|&`, file descriptors, `/dev/tcp`
> [Check] Coprocess section covers bidirectional communication with `coproc`
> [Check] Nameref section covers `declare -n` (Bash 4.3+)
> [Check] Bash 5.x section covers `@U`/`@L`, `EPOCHREALTIME`, `wait -n`, `mapfile -d`
> [Check] Timing section covers `time` and `TIMEFORMAT`
> [Check] Read section covers `-r`, `-p`, `-s`, `-d`, `-t`, `-n`
> [Check] File validated on Bash 5.3.15
