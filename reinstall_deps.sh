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

# Get the list of installed packages
installed_packages=$(qlist -Iv)

# Print the equery output, excluding lines with the given category/package name, and ensure unique results
dependencies=$(echo "$equery_output" | grep -v "$1" | awk '{$1=""; sub(/^[ \t]+/, ""); sub(/^[0-9]+\] /, ""); print}' | sort | uniq)

# Create a temporary locked file
temp_file=$(mktemp)

# Lock the file
{
    flock -x 200

    # Check if each dependency is installed and write to the temporary file
    for deps in $dependencies; do
        if echo "$installed_packages" | grep -q "^$deps$"; then
            echo "=$deps" >> "$temp_file"
        fi
    done

} 200>"$temp_file"

# Output the path to the temporary locked file
echo "Output of command written to $temp_file"s

# Emerge the exact packages in the temporary locked file
emerge -va1 $(cat "$temp_file")

# Remove the temporary locked file
rm -f "$temp_file"
