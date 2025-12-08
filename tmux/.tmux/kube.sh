#!/usr/bin/env fish

echo "$(kubectl ctx -c):$(kubectl ns -c)"
