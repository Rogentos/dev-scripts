#!/bin/bash

# Check if an argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <package> [--auto]"
    exit 1
fi

# Check for the --auto argument, which dodges the asking prompt
auto_mode=false
for arg in "$@"; do
    if [ "$arg" == "--auto" ]; then
        auto_mode=true
        break
    fi
done

# Run equery g -UMAl on the provided argument
equery_output=$(equery g -UMAl "$1")

# Check the exit status
if [ $? -eq 0 ]; then
    echo ""
else
    echo "Command failed with exit code $?"
    exit 1
fi

# Extract categories from the argument
categories=$(echo "$1" | grep -oE '\b[a-z]+-[a-z]+\b' | sort -u)

# Print the categories
echo $categories

# Get the list of installed packages
installed_packages=$(qlist -Iv)

# Print the equery output, excluding lines with the given category/package-version-revision name, and ensure unique results
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
echo "Output of command written to $temp_file"

# Emerge the exact packages in the temporary locked file
if [ "$auto_mode" = true ]; then
    emerge -v1 $(cat "$temp_file")
else
    emerge -va1 $(cat "$temp_file")
fi

# Remove the temporary locked file