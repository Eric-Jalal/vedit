#!/usr/bin/env python3

import os
import subprocess
import sys
from time import sleep

CONFIG_FILE = os.path.expanduser("~/.vedit_config")
TRASH_DIR = os.path.expanduser("~/.vedit_trash")
VERSION = "1.0.0"

# Ensure dependencies are installed
def check_dependency(command):
    try:
        subprocess.run([command], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    except FileNotFoundError:
        print(f"{command} is not installed. Exiting.")
        sys.exit(1)

check_dependency("fd")
check_dependency("xclip")

# Create trash directory if it doesn't exist
os.makedirs(TRASH_DIR, exist_ok=True)

def move_to_trash(file):
    filename = os.path.basename(file)
    trash_target = os.path.join(TRASH_DIR, filename)
    counter = 1
    while os.path.exists(trash_target):
        trash_target = os.path.join(TRASH_DIR, f"{filename}.{counter}")
        counter += 1
    os.rename(file, trash_target)
    print(f"File moved to trash: {trash_target}")

def select_file(files):
    print("Files found with the provided keyword:")
    for i, f in enumerate(files, 1):
        print(f"{i}) {f}")
    choice = input("Select a file by number or 'n' to exit: ")
    if choice == "n":
        sys.exit(0)
    return files[int(choice)-1]

def display_help():
    help_text = """
    vedit - A utility to search and manage files
    Usage: vedit [OPTION] <searching keyword>
    Options:
      -e          Edit the file
      -d          Delete the file
      -c          Copy the file path to clipboard
      -h          Display this help message
      -v, --version  Display the version of the script
    """
    print(help_text)

def handle_file(file, action):
    if action == "edit":
        subprocess.run([EDITOR, file])
    elif action == "delete":
        move_to_trash(file)
    elif action == "copy":
        subprocess.run(["echo", "-n", file, "|", "xclip", "-selection", "clipboard"])
        print("Path copied to clipboard.")
    else:
        print(f"Found: {file}\nWhat would you like to do?")
        print("e) Edit\nr) Remove\nc) Copy path to clipboard")
        choice = input("Choose an option (e/r/c) or 'n' to exit: ")
        if choice == "e":
            subprocess.run([EDITOR, file])
        elif choice == "r":
            move_to_trash(file)
        elif choice == "c":
            subprocess.run(["echo", "-n", file, "|", "xclip", "-selection", "clipboard"])
            print("Path copied to clipboard.")
        elif choice == "n":
            sys.exit(0)
        else:
            print("Invalid option.")

# Get the editor from the configuration file or default to nvim
if os.path.exists(CONFIG_FILE):
    with open(CONFIG_FILE, 'r') as f:
        EDITOR = f.read().strip()
else:
    EDITOR = "nvim"

action = None
search_keyword = None

for arg in sys.argv[1:]:
    if arg in ["-e", "--edit"]:
        action = "edit"
    elif arg in ["-d", "--delete"]:
        action = "delete"
    elif arg in ["-c", "--copy"]:
        action = "copy"
    elif arg in ["-h", "--help"]:
        display_help()
        sys.exit(0)
    elif arg in ["-v", "--version"]:
        print(f"vedit version {VERSION}")
        sys.exit(0)
    else:
        search_keyword = arg

if not search_keyword:
    print("Please provide a searching keyword.")
    sys.exit(1)

# Use fd to search for files with the provided keyword
result = subprocess.run(["fd", "--type", "f", f".*{search_keyword}.*", "."], stdout=subprocess.PIPE)
files = result.stdout.decode().splitlines()

if len(files) == 0:
    print("No files found containing the keyword.")
    sys.exit(1)
elif len(files) == 1:
    handle_file(files[0], action)
else:
    file_to_handle = select_file(files)
    handle_file(file_to_handle, action)

