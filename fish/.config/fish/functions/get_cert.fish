function get_cert -d "Extract TLS certificate chain from a remote host"
    if test (count $argv) -lt 1; or test (count $argv) -gt 2
        echo "Usage: get_cert <host> [port]" >&2
        echo "  port is optional, defaults to 443" >&2
        return 1
    end

    set host $argv[1]
    set port 443
    if test (count $argv) -eq 2
        set port $argv[2]
    end

    echo "Fetching certificates from $host:$port ..."

    # Fetch cert chain and split into individual PEM files
    openssl s_client -showcerts -connect "$host:$port" </dev/null 2>/dev/null \
        | awk '
/BEGIN CERTIFICATE/ {c++; f="cert" c ".pem"}
/BEGIN CERTIFICATE/,/END CERTIFICATE/ {print > f}
END {if (c==0) print "NO_CERTS"}'
    set -l awk_status $status

    if test $awk_status -ne 0; or not test -f cert1.pem
        echo "No certificates found for $host:$port" >&2
        rm -f cert*.pem 2>/dev/null
        return 1
    end

    # Display subject and issuer for each cert in the chain
    for f in cert*.pem
        echo "=== $f ==="
        openssl x509 -in "$f" -noout -subject -issuer
        echo
    end

    echo "Certificates saved to current directory."
end
