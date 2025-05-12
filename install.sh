#!/bin/bash

# Function to display usage information
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -h, --help           Show this help message"
    echo "  --packages           Install Homebrew packages only"
    echo "  --casks              Install Homebrew casks only"
    echo "  --mas                Install Mac App Store apps only"
    echo "  --dotfiles           Install dotfiles only"
    echo "  --defaults           Install macOS defaults only"
    echo "  --all                Install everything (default if no options provided)"
    exit 1
}

# Read the contents of a file and execute a command for each non-empty and 
# non-comment line. Inputs: file, command, placeholder.
# Example: process_file "brew-packages.txt" "brew install {}" "{}"
#  -> Will read brew-packages.txt and run "brew install <line>" for each line
process_file() {
    local file="$1"
    local command="$2"
    local placeholder="$3"
    echo "Processing $file..."
    while IFS= read -r line || [ -n "$line" ]; do
        if [ ! -z "$line" ] && [[ ! "$line" =~ ^[[:space:]]*# ]]; then
            # Replace the placeholder with the line content
            cmd="${command//$placeholder/\"$line\"}"
            eval "$cmd"
        fi
    done < "$file"
}

# Install Homebrew packages
install_brew_packages() {
    process_file "brew-packages.txt" "brew install {}" "{}"
}

# Install Homebrew casks
install_brew_casks() {
    process_file "brew-casks.txt" "brew install --cask {}" "{}"
}

# Install Mac App Store apps
install_mas_apps() {
    process_file "brew-mas.txt" "mas install {}" "{}"
}

# Link dotfiles
install_dotfiles() {
    # Check if stow is installed
    if ! command -v stow &> /dev/null; then
        echo "Error: GNU Stow is not installed"
        echo "Run the brew install script first?"
        exit 1
    fi

    echo "Stowing dotfiles..."
    for dir in config/*/; do
        if [ -d "$dir" ]; then
            dirname=$(basename "$dir")
            echo "--> Stowing $dirname..."
            stow --dir config --target "$HOME" "$dirname"
        fi
    done
}

# Install macOS defaults
install_defaults() {
    process_file "bin/macos-defaults.sh" "bash -c {}" "{}"
}

# Install Homebrew if not present
install_homebrew() {
    if ! command -v brew &> /dev/null; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
}

# When Ctrl+C is pressed, exit the entire script
trap 'echo -e "\nScript interrupted. Exiting..."; exit 1' INT


# Parse command line arguments
if [ $# -eq 0 ]; then
    # No arguments passed, show the help message
    usage
else
    # Initialize and fetch git submodules
    echo "Initializing git submodules..."
    git submodule init
    git submodule update

    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help)
                usage
                ;;
            --packages)
                install_homebrew
                install_brew_packages
                ;;
            --casks)
                install_homebrew
                install_brew_casks
                ;;
            --mas)
                install_mas_apps
                ;;
            --dotfiles)
                install_dotfiles
                ;;
            --defaults)
                install_defaults
                ;;
            --all)
                install_homebrew
                install_brew_packages
                install_brew_casks
                install_mas_apps
                install_dotfiles
                ;;
            *)
                echo "Unknown option: $1"
                usage
                ;;
        esac
        shift
    done
fi

echo "Done!"
