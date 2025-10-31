# Function to display directory structure as a tree (files excluded)
function tree_dirs -d "Display directory structure as a tree (excludes files)"
    set -l target_dir .
    set -l max_depth ""
    set -l exclude_patterns ""
    set -l show_help 0

    # Parse arguments
    while set -q argv[1]; and test -n "$argv[1]"
        switch "$argv[1]"
            case -h --help
                set show_help 1
                # Fall through to show help
            case -d --depth
                set max_depth $argv[2]
                set -e argv[1]  # Remove both the flag and its argument
            case -e --exclude
                if test -n "$argv[2]"
                    if test -z "$exclude_patterns"
                        set exclude_patterns $argv[2]
                    else
                        set exclude_patterns $exclude_patterns $argv[2]
                    end
                    set -e argv[1]  # Remove both the flag and its argument
                else
                    echo "Error: --exclude requires an argument" >&2
                    return 1
                end
            case -* --*
                echo "Unknown option: $argv[1]" >&2
                return 1
            case '*'
                # If it's the first non-option argument, treat as target directory
                if test "$target_dir" = "."
                    set target_dir "$argv[1]"
                else
                    echo "Error: Unknown argument: $argv[1]" >&2
                    return 1
                end
        end
        set -e argv[1]
    end

    # Show help if requested
    if test $show_help -eq 1
        set -l help_text "Usage: tree_dirs [OPTIONS] [DIRECTORY]

Display directory structure as a tree (excludes files)

Options:
  -h, --help          Show this help message
  -d, --depth DEPTH   Maximum depth to traverse
  -e, --exclude PATTERN  Exclude directories matching PATTERN (can be used multiple times)

Examples:
  tree_dirs                           # Current directory, no exclusions
  tree_dirs /path/to/project          # Specific directory
  tree_dirs -d 2                      # Limit depth to 2 levels
  tree_dirs -e node_modules           # Exclude node_modules
  tree_dirs -e node_modules -e .git   # Exclude multiple patterns
  tree_dirs -d 3 -e __pycache__ /src  # Combined options"
        echo $help_text
        return 0
    end

    # Validate directory exists
    if not test -d "$target_dir"
        echo "Error: Directory does not exist: $target_dir" >&2
        return 1
    end

    # Use find to list directories only, with optional depth limit and exclusions
    set -l find_cmd find "$target_dir" -type d

    # Add depth limit if specified
    if test -n "$max_depth"
        set find_cmd $find_cmd -maxdepth "$max_depth"
    end

    # Add exclusions if specified
    if test -n "$exclude_patterns"
        for pattern in $exclude_patterns
            set find_cmd $find_cmd -not -path "*/$pattern/*"
        end
    end

    # Execute find and format the tree using the system tree command if available,
    # otherwise use find with basic formatting
    if command -v tree >/dev/null 2>&1
        set -l tree_cmd tree -d
        if test -n "$max_depth"
            set tree_cmd $tree_cmd -L "$max_depth"
        end
        if test -n "$exclude_patterns"
            for pattern in $exclude_patterns
                set tree_cmd $tree_cmd -I "$pattern"
            end
        end
        $tree_cmd "$target_dir"
    else
        # Fallback using find with basic formatting
        $find_cmd | sed 's|[^/]*/|  |g' | sed 's|^ *|&├── |' | sed '1s|├── ||'
    end
end
