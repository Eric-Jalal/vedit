#!/usr/bin/env bash

# Set unofficial bash script mode
set -euo pipefail

CONFIG_FILE="$HOME/.vedit_config"
TRASH_DIR="$HOME/.vedit_trash"
VERSION="1.0.0"

# Ensure dependencies are installed
command -v fd >/dev/null 2>&1 || { echo >&2 "fd is not installed. Exiting."; exit 1; }
command -v xclip >/dev/null 2>&1 || { echo >&2 "xclip is not installed. Exiting."; exit 1; }

# Create trash directory if it doesn't exist
mkdir -p "$TRASH_DIR"

# Backup mechanism before deletion
move_to_trash() {
    local file="$1"
    local filename=$(basename "$file")
    local trash_target="$TRASH_DIR/$filename"
    # Ensure unique filenames in trash
    local counter=1
    while [[ -e "$trash_target" ]]; do
        trash_target="$TRASH_DIR/$filename.$counter"
        counter=$((counter + 1))
    done
    mv "$file" "$trash_target"
    echo "File moved to trash: $trash_target"
}

# Loading animation
spin() {
    local -a spinner
    spinner=('-' '\' '|' '/')
    while :
    do
        for i in "${spinner[@]}"
        do
            echo -ne "\r$i"
            sleep 0.2
        done
    done
}

# Function to display files and let the user select one
select_file() {
  local files=("$@")
  echo "Files found with the provided keyword:"
  local i=1
  for f in "${files[@]}"; do
    echo "$i) $f"
    let i++
  done
  echo -n "Select a file by number or 'n' to exit: "
  read -r choice
  if [[ "$choice" == "n" ]]; then
    exit 0
  fi
  echo "${files[$choice]}"
}

display_help() {
  echo "vedit - A utility to search and manage files"
  echo "Usage: vedit [OPTION] <searching keyword>"
  echo "Options:"
  echo "  -e          Edit the file"
  echo "  -d          Delete the file"
  echo "  -c          Copy the file path to clipboard"
  echo "  -h          Display this help message"
  echo "  -v, --version  Display the version of the script"
}

handle_file() {
  local file="$1"
  case "$ACTION" in
    edit)
      $EDITOR "$file"
      ;;
    delete)
      move_to_trash "$file"
      ;;
    copy)
      echo -n "$file" | xclip -selection clipboard
      echo "Path copied to clipboard."
      ;;
    *)
      echo "Found: $file"
      echo "What would you like to do?"
      echo "e) Edit"
      echo "r) Remove"
      echo "c) Copy path to clipboard"
      echo -n "Choose an option (1/2/3) or 'n' to exit: "
      read -r action
      case "$action" in
        e)
          $EDITOR "$file"
          ;;
        d)
          rm "$file"
          echo "File removed."
          ;;
        c)
          echo -n "$file" | xclip -selection clipboard
          echo "Path copied to clipboard."
          ;;
        n)
          exit 0
          ;;
        *)
          echo "Invalid option."
          ;;
      esac
      ;;
  esac
}

# Check if the user wants to configure the editor
if [[ "$1" == "config" ]]; then
    echo -n "Which editor would you like to use? (nvim, vim, etc.): "
    read editor_choice
    echo "$editor_choice" > "$CONFIG_FILE"
    exit 0
fi

# Get the editor from the configuration file or default to nvim
EDITOR="$(cat "$CONFIG_FILE" 2>/dev/null || echo "nvim")"

# Start the spinner in the background
spin &
# Save spinner's process ID
SPIN_PID=$!
# Use a trap to stop the spinner when the script exits
trap "kill -9 $SPIN_PID" $(echo {1..15})

# Stop the spinner
kill -9 $SPIN_PID

# Handle flags
while getopts ":edchv-:" opt; do
  case $opt in
    e)
      ACTION="edit"
      ;;
    d)
      ACTION="delete"
      ;;
    c)
      ACTION="copy"
      ;;
    h)
      display_help
      exit 0
      ;;
    v)
      echo "vedit version $VERSION"
      exit 0
      ;;
    -)
      if [[ "$OPTARG" == "version" ]]; then
        echo "vedit version $VERSION"
        exit 0
      else
        echo "Invalid option: --$OPTARG" >&2
        exit 1
      fi
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

# Shift to get the next argument which should be the searching keyword
shift $((OPTIND - 1))

if [[ -z "$1" ]]; then
  echo "Please provide a searching keyword."
  exit 1
fi

# Use fd to search for files with the provided keyword
while IFS= read -r line; do
    files+=("$line")
done < <(fd --type f ".*$1.*" .)

# If no file is found
if [[ ${#files[@]} -eq 0 ]]; then
  echo "No files found containing the keyword."
  exit 1
# If only one file is found
elif [[ ${#files[@]} -eq 1 ]]; then
  handle_file "${files[0]}"
# If multiple files are found
else
  file_to_handle=$(select_file "${files[@]}")
  handle_file "$file_to_handle"
fi

