function extract --description "Extract archive files by detecting format from extension"
    if test (count $argv) -eq 0
        echo "Usage: extract <archive> [files...]"
        return 1
    end

    set -l file $argv[1]
    if not test -f "$file"
        echo "extract: file not found — $file"
        return 1
    end

    switch $file
        case *.tar.xz
            tar xf $file
        case *.txz
            tar xf $file
        case *.tar.gz *.tgz
            tar xf $file
        case *.tar.bz2 *.tbz2
            tar xf $file
        case *.tar.zst
            tar xf $file
        case *.tar
            tar xf $file
        case *.gz
            gunzip -k $file
        case *.bz2
            bunzip2 -k $file
        case *.xz
            unxz -k $file
        case *.zst
            unzstd -k $file
        case *.zip
            unzip $argv
        case *.rar
            unrar x $file
        case *.7z
            7z x $file
        case *.Z
            uncompress -k $file
        case '*'
            echo "extract: unknown archive format — $file"
            return 1
    end
end
