#!/bin/bash

# Check if an argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <package>"
    exit 1
fi

# Run equery g -UMAl on the provided argument
equery_output=$(equery g -UMAl "$1")

# Extract categories from the argument
categories=$(echo "$1" | grep -oE '\b[a-z]+-[a-z]+\b' | sort -u)

# Print the categories
echo $categories

# Print the equery output, excluding lines with the given category/package name, and ensure unique results
echo "$equery_output" | grep -v "$1" | awk '{$1=""; sub(/^[ \t]+/, ""); sub(/^[0-9]+\] /, ""); print}' | sort | uniq
