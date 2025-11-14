function ssh_copy
    if test (count $argv) -lt 3 -o (count $argv) -gt 4
        echo "Usage: ssh_copy <hostname> <source_file> <destination_path> [ssh_key_name]" >&2
        echo "  ssh_key_name is optional, defaults to 'id_rsa'" >&2
        return 1
    end

    set target_host $argv[1]
    set source_file $argv[2]
    set dest_path $argv[3]

    # Set SSH key - use provided key or default to 'id_rsa'
    if test (count $argv) -eq 4
        set ssh_key_name $argv[4]
    else
        set ssh_key_name "id_rsa"
    end

    set ssh_base_path "/Users/eryoma/.ssh"
    set ssh_key_path "$ssh_base_path/$ssh_key_name"
    set ssh_user "m.eremenko"  # Change this to your desired username

    # Validate that the SSH key exists
    if not test -f $ssh_key_path
        echo "SSH key not found: $ssh_key_path" >&2
        return 1
    end

    # Validate that source file exists
    if not test -f $source_file
        echo "Source file not found: $source_file" >&2
        return 1
    end

    # Get the basename of the source file
    set file_basename (basename $source_file)

    # Copy file to /tmp on remote host using specified SSH key
    echo "Copying $source_file to $target_host:/tmp/..."
    scp -i $ssh_key_path $source_file $ssh_user@$target_host:/tmp/
    if test $status -ne 0
        echo "Failed to copy file via scp" >&2
        return 1
    end

    # Move file to final destination with sudo using specified SSH key
    echo "Moving file to final destination: $dest_path"
    ssh -i $ssh_key_path $ssh_user@$target_host "sudo mv \"/tmp/$file_basename\" \"$dest_path\""
    if test $status -ne 0
        echo "Failed to move file on remote host" >&2
        return 1
    end

    echo "File successfully copied and moved!"
end
