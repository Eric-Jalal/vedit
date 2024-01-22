# vedit

`vedit` is a command-line utility designed to search for files based on a provided keyword. Once found, it allows the user to either edit the file, delete it, or copy its path to the clipboard.

## Installation
### Manual

```shell
curl -LO https://github.com/Eric-Jalal/vedit/releases/download/v1.0.0/vedit.tar.gz && \
tar -xzf vedit.tar.gz && \
sudo mv vedit.sh /usr/local/bin/vedit.sh && \
sudo chmod +x /usr/local/bin/vedit.sh && \
sudo ln -sf /usr/local/bin/vedit.sh /usr/local/bin/vedit
```

### Homebrew
```shell
brew tap Eric-Jalal/tap
brew install vedit
```

Optionally, ensure xclip is installed if you want to use the copy-to-clipboard feature:
sudo apt install xclip


## Usage

Simply run:
```shell
vedit [OPTION] <searching keyword>
```

Options:
-e: Edit the file.
-d: Delete the file.
-c: Copy the file path to clipboard.
-h: Display help.
-v, --version: Display the version of the script.

If no option is provided, the script will prompt the user for an action after the search is complete.

## Example:

To search for files containing the word "sample" and choose to edit:
```shell
vedit -e sample
```

## How It Works

Searching: The script uses the find command to recursively search the current directory and its subdirectories for files containing the provided keyword.
File Handling: Once a file or multiple files are found, the script offers various actions based on provided flags or prompts the user if no flags are provided.
Configuration: Users can configure their preferred editor by running vedit config. This choice is saved in a .vedit_config file in the user's home directory.
Loading Animation: While searching, a spinning animation (-|/) is displayed to indicate progress.

## Dependencies

fd: Required for searching through files
mapfile: For transforming the texts into arrays from files
xclip: Required for the copy-to-clipboard feature. Ensure it's installed on your system.
