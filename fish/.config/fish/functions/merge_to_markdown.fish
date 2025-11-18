function merge_to_markdown -d "Merge files from a directory into a single Markdown file with syntax highlighting"
    # Validate arguments
    if test (count $argv) -lt 2
        echo "Usage: merge_to_markdown <source_dir> <output_file> [file_pattern] [--ignore-dirs dir1,dir2,...]"
        echo "Example: merge_to_markdown ./src output.md \"*.cpp\""
        echo "Example: merge_to_markdown ./src output.md \"*\" --ignore-dirs node_modules,dist"
        return 1
    end

    set -l source_dir $argv[1]
    set -l output_file $argv[2]
    set -l file_pattern "*"
    set -l ignore_dirs

    # Parse arguments
    set -l i 3
    while test $i -le (count $argv)
        if test "$argv[$i]" = "--ignore-dirs"
            set i (math $i + 1)
            if test $i -le (count $argv)
                set ignore_dirs (string split "," $argv[$i])
            end
        else
            set file_pattern $argv[$i]
        end
        set i (math $i + 1)
    end

    # Validate source directory
    if not test -d "$source_dir"
        echo "Error: Directory '$source_dir' does not exist"
        return 1
    end

    # Clear or create output file
    echo -n "# Merged Content from $source_dir" > "$output_file"
    printf "\n\n" >> "$output_file" # Add two newlines after the header

    # Build find command with exclusions
    set -l find_args "$source_dir" -type f -name "$file_pattern"

    # Always exclude .git directory
    set -a find_args -not -path "*/.git/*"

    # Read and parse .gitignore if it exists
    if test -f "$source_dir/.gitignore"
        for pattern in (cat "$source_dir/.gitignore" | grep -v '^#' | grep -v '^$')
            # Remove leading/trailing whitespace
            set pattern (string trim $pattern)
            if test -n "$pattern"
                # Convert gitignore pattern to find pattern
                set pattern (string replace -a '**' '*' $pattern)
                set -a find_args -not -path "*/$pattern" -not -path "*/$pattern/*"
            end
        end
    end

    # Add custom ignore directories
    for dir in $ignore_dirs
        set -a find_args -not -path "*/$dir/*"
    end

    # Process matching files
    for file in (find $find_args | sort)
        set filename (basename "$file")

        # Extract extension correctly in Fish
        set extension (string replace -r '.*\.' '' "$filename")
        set extension (string lower $extension)

        # Map common extensions to language identifiers
        set language
        switch $extension
            case "js" "ts" "jsx" "tsx" "json" "graphql"
                set language "javascript"
            case "py"
                set language "python"
            case "rb"
                set language "ruby"
            case "go"
                set language "go"
            case "rs"
                set language "rust"
            case "java"
                set language "java"
            case "cpp" "cc" "cxx" "c++"
                set language "cpp"
            case "c"
                set language "c"
            case "h" "hpp" "hxx"
                set language "cpp"
            case "cs"
                set language "csharp"
            case "php"
                set language "php"
            case "html" "htm"
                set language "html"
            case "css"
                set language "css"
            case "md" "markdown"
                set language "markdown"
            case "yaml" "yml"
                set language "yaml"
            case "xml"
                set language "xml"
            case "sql"
                set language "sql"
            case "sh" "bash" "zsh"
                set language "bash"
            case "dockerfile" "dockerignore"
                set language "dockerfile"
            case "toml"
                set language "toml"
            case "ini" "cfg" "conf"
                set language "ini"
            case "*"
                set language ""
        end

        # Add language to code block if detected
        if test -n "$language"
            printf "## %s\n```%s\n" "$filename" "$language" >> "$output_file"
        else
            printf "## %s\n```\n" "$filename" >> "$output_file"
        end

        # Output file content with proper newlines
        cat "$file" >> "$output_file"

        # Close code block
        printf "\n```\n\n" >> "$output_file" # Add two newlines after each file block
    end

    echo "Content merged successfully into $output_file"
end
