#!/bin/bash
# Script to help identify non-Vietnamese text patterns in JS files

echo "Scanning for English text patterns..."
echo ""

cd "wwwroot/js"

# Common English patterns to check
patterns=(
    "Loading"
    "Please wait"
    "Success"
    "Failed"
    "Error occurred"
    "Are you sure"
    "Delete this"
    "Create new"
    "Edit "
    "Save changes"
    "Cancel"
    " Add "
    " View "
    "No data"
    "No results"
    "Select option"
    "Required field"
    "Invalid"
)

for pattern in "${patterns[@]}"; do
    echo "Checking for: $pattern"
    grep -n "$pattern" *.js 2>/dev/null | head -5
    echo ""
done
