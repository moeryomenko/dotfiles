#!/bin/sh

echo "$(kubectl config current-context):$(kubectl config view --minify --output 'jsonpath={..namespace}')"
