#!/bin/sh

echo "$(kubectl ctx -c):$(kubectl ns -c)"
