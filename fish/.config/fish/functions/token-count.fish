function token-count --description "Count tokens in a file using llama-tokenize"
    if test (count $argv) -ne 1
        echo "Usage: token-count <file>" >&2
        return 1
    end

    set -l file $argv[1]

    if not test -f "$file"
        echo "Error: file not found: $file" >&2
        return 1
    end

    /home/eryoma/models/llama.cpp/_build/bin/llama-tokenize \
        -m ~/models/Qwopus3.6-27B-Coder-Compat-MTP-GGUF/Qwopus3.6-27B-Coder-Compat-MTP-Q4_K_M.gguf \
        --file "$file" \
        --show-count 2>/dev/null | rg 'Total number of tokens'
end
