#!/bin/bash

# Input Markdown file
input_file="$1"

# Temporary file to store content
temp_file="temp.md"

# Process the input file line by line
while IFS= read -r line; do
  # Check for a second-level header (##)
  if [[ "$line" =~ ^##\  ]]; then
    # Extract the header text and create a filename
    header_text=$(echo "$line" | sed -E 's/^##\ (.*)$/\1/')
    filename=$(echo "$header_text" | tr ' ' '_' | tr '[:upper:]' '[:lower:]').md
    
    # Create a new file and write the header to it
    echo "$line" > "$filename"
    
    # Create a temporary file to store content until the next header is found
    echo -n > "$temp_file"
    
    # Flag to indicate that we are inside a section
    inside_section=true
  elif [[ "$inside_section" == true ]]; then
    # Append the current line to the temporary file
    echo "$line" >> "$filename"
  fi
done < "$input_file"

# Append the temporary file content to the appropriate section
if [[ -n "$filename" && -f "$temp_file" ]]; then
  cat "$temp_file" >> "$filename"
  rm "$temp_file"
fi

