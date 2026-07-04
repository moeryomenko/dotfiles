# Configure and build CMake projects with sane defaults
#
# Extracted from neovim-tasks configuration at:
#   nvim/.config/nvim/lua/plugins/tasks.lua
#
# Defaults: Ninja generator, ccache, mold linker (Linux),
#           compile_commands.json, _build directory, Debug type.
#
# Usage:
#   cmake_project configure [src_dir]   - configure (default src_dir = .)
#   cmake_project build    [target]     - build (default target = all)
#   cmake_project clean                 - remove _build directory
#   cmake_project rebuild  [target]     - clean + configure + build
#   cmake_project release  [src_dir]    - configure with Release type
function cmake_project -d "Configure and build CMake projects with sane defaults"
    set -l build_dir "_build"
    set -l build_type "Debug"
    set -l generator "Ninja"
    set -l src_dir ""

    # Find ccache
    set -l ccache_path ""
    if command -v ccache >/dev/null 2>&1
        set ccache_path (command -v ccache)
    else if test -x /usr/bin/ccache
        set ccache_path /usr/bin/ccache
    end

    # Detect mold linker availability on Linux
    set -l use_mold 0
    if test (uname -s) = "Linux"
        if command -v mold >/dev/null 2>&1; or test -x /usr/bin/mold
            set use_mold 1
        end
    end

    # Parse subcommand
    if set -q argv[1]
        switch $argv[1]
            case configure
                if set -q argv[2]
                    set src_dir $argv[2]
                else
                    set src_dir "."
                end

                if not test -f "$src_dir/CMakeLists.txt"
                    echo "Error: No CMakeLists.txt found in $src_dir" >&2
                    return 1
                end

                set -l config_args -G "$generator" -B "$build_dir" -S "$src_dir"
                set config_args $config_args "-DCMAKE_EXPORT_COMPILE_COMMANDS=1"
                set config_args $config_args "-DCMAKE_BUILD_TYPE=$build_type"
                if test -n "$ccache_path"
                    set config_args $config_args "-DCMAKE_C_COMPILER_LAUNCHER=$ccache_path"
                    set config_args $config_args "-DCMAKE_CXX_COMPILER_LAUNCHER=$ccache_path"
                end
                if test $use_mold -eq 1
                    set config_args $config_args "-DCMAKE_EXE_LINKER_FLAGS_INIT=-fuse-ld=mold"
                    set config_args $config_args "-DCMAKE_SHARED_LINKER_FLAGS_INIT=-fuse-ld=mold"
                end

                echo "Configuring CMake project..."
                echo "  Generator: $generator"
                echo "  Build dir: $build_dir"
                echo "  Build type: $build_type"
                if test -n "$ccache_path"
                    echo "  CCache: $ccache_path"
                end
                if test $use_mold -eq 1
                    echo "  Linker: mold"
                end
                echo ""

                cmake $config_args

            case build
                set -l target "all"
                if set -q argv[2]
                    set target $argv[2]
                end

                if not test -d "$build_dir"
                    echo "Error: Build directory '$build_dir' does not exist." >&2
                    echo "Run 'cmake_project configure' first." >&2
                    return 1
                end

                echo "Building CMake project (target: $target)..."
                cmake --build "$build_dir" --target "$target"

            case clean
                if test -d "$build_dir"
                    echo "Removing $build_dir..."
                    rm -rf "$build_dir"
                    echo "Done."
                else
                    echo "Nothing to clean ($build_dir does not exist)."
                end

            case rebuild
                set -l target "all"
                if set -q argv[2]
                    set target $argv[2]
                end

                # Clean
                if test -d "$build_dir"
                    echo "=== Clean ==="
                    rm -rf "$build_dir"
                end

                # Configure
                echo ""
                echo "=== Configure ==="
                cmake_project configure

                # Build
                echo ""
                echo "=== Build ==="
                cmake_project build $target

            case release
                if set -q argv[2]
                    set src_dir $argv[2]
                else
                    set src_dir "."
                end

                # Temporarily override build type and reconfigure
                set build_type "Release"
                if not test -d "$build_dir"
                    # First-time configure in release mode
                    cmake_project configure $src_dir
                else
                    # Reconfigure with Release
                    set -l config_args -G "$generator" -B "$build_dir" -S "$src_dir"
                    set config_args $config_args "-DCMAKE_EXPORT_COMPILE_COMMANDS=1"
                    set config_args $config_args "-DCMAKE_BUILD_TYPE=$build_type"
                    if test -n "$ccache_path"
                        set config_args $config_args "-DCMAKE_C_COMPILER_LAUNCHER=$ccache_path"
                        set config_args $config_args "-DCMAKE_CXX_COMPILER_LAUNCHER=$ccache_path"
                    end
                    if test $use_mold -eq 1
                        set config_args $config_args "-DCMAKE_EXE_LINKER_FLAGS_INIT=-fuse-ld=mold"
                        set config_args $config_args "-DCMAKE_SHARED_LINKER_FLAGS_INIT=-fuse-ld=mold"
                    end

                    echo "Reconfiguring with Release type..."
                    cmake $config_args
                end

                echo ""
                echo "=== Build (Release) ==="
                cmake --build "$build_dir"

            case -h --help
                echo "Usage: cmake_project <command> [arguments]"
                echo ""
                echo "Commands:"
                echo "  configure [src_dir]   Configure project (default src_dir = .)"
                echo "  build [target]        Build project (default target = all)"
                echo "  clean                 Remove build directory"
                echo "  rebuild [target]      Clean + configure + build"
                echo "  release [src_dir]     Configure with Release type and build"
                echo ""
                echo "Defaults:"
                echo "  Generator:  $generator"
                echo "  Build dir:  $build_dir"
                echo "  Build type: $build_type"
                if test -n "$ccache_path"
                    echo "  CCache:     enabled"
                end
                if test $use_mold -eq 1
                    echo "  Linker:     mold"
                end
                echo ""
                echo "Based on neovim-tasks CMake configuration."

            case '*'
                echo "Error: Unknown command '$argv[1]'" >&2
                echo "Usage: cmake_project <configure|build|clean|rebuild|release>" >&2
                return 1
        end
    else
        # No arguments: run configure + build
        cmake_project configure
        and cmake_project build
    end
end
