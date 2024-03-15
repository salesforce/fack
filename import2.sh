#!/bin/bash

# Requires 'jq'
# Run `brew install jq` on mac to install

# Load environment variables from .env file, skipping lines starting with #
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

# Check for necessary environment variables
if [ -z "$ROOT_URL" ]; then
  echo "Missing ROOT_URL in .env"
  exit 1
fi

if [ -z "$IMPORT_API_TOKEN" ]; then
  echo "Missing IMPORT_API_TOKEN in .env"
  exit 1
fi

API_URL="$ROOT_URL/api/v1/documents"
AUTH_TOKEN="$IMPORT_API_TOKEN"

# Function to display usage
usage() {
  echo "Usage: $0 -l LIBRARY_ID -d DIRECTORY"
  echo "  -l  Library id which contains documents (required)"
  echo "  -d  Directory path of docs to import (required)"
  exit 1
}

# Parse command line options
while getopts ":l:d:" opt; do
  case ${opt} in
    l )
      LIBRARY_ID=$OPTARG
      ;;
    d )
      DIRECTORY_PATH=$OPTARG
      ;;
    \? )
      usage
      ;;
  esac
done

# Check if all required options are present
if [ -z "$LIBRARY_ID" ] || [ -z "$DIRECTORY_PATH" ]; then
  usage
fi

# Function to process files in directory
process_directory() {
  local directory_path="$1"
  local library_id="$2"
  local api_url="$3"
  local auth_token="$4"

  for file_path in "$directory_path"/*; do
    if [ -d "$file_path" ]; then
      # Recursively process subdirectories
      process_directory "$file_path" "$library_id" "$api_url" "$auth_token"
    elif [[ $file_path == *.md || $file_path == *.mdx ]]; then
      echo -e "\n# Processing: $file_path"
      local file_content=$(<"$file_path")
      local external_id=$(md5 "$file_path" | cut -d' ' -f1)
      local title=$(basename "$file_path")
      local data_json=$(jq -n \
        --arg doc "$file_content" \
        --arg title "$title" \
        --arg externalId "$external_id" \
        --arg libraryId "$library_id" \
        '{document: {document: $doc, title: $title, external_id: $externalId, library_id: $libraryId}}')

      # Send the POST request to create the new document
      response=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$api_url" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $auth_token" \
        -d "$data_json")

      # Check the response status code
      if [ "$response" -eq 201 ]; then
        echo "Document '$file_path' uploaded successfully."
      else
        echo "Failed to create document '$file_path'. Response status code: $response"
      fi
    fi
  done
}

# Start processing the directory
process_directory "$DIRECTORY_PATH" "$LIBRARY_ID" "$API_URL" "$AUTH_TOKEN"
