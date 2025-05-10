#!/bin/bash

# When Ctrl+C is pressed, exit the entire script instead of stopping the current
# command in a loop
trap 'echo -e "\nScript interrupted. Exiting..."; exit 1' INT

# Initialize and fetch git submodules
echo "Initializing git submodules..."
git submodule init
git submodule update

# Install Homebrew
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install brew packages
echo "Installing brew packages..."
while IFS= read -r package || [ -n "$package" ]; do
    # Skip empty lines and comments
    if [ ! -z "$package" ] && [[ ! "$package" =~ ^[[:space:]]*# ]]; then
        brew install "${package}"
    fi
done < brew-packages.txt

# Install brew casks from file
echo "Installing brew casks..."
while IFS= read -r cask || [ -n "$cask" ]; do
    # Skip empty lines and comments
    if [ ! -z "$cask" ] && [[ ! "$cask" =~ ^[[:space:]]*# ]]; then
        brew install --cask "${cask}"
    fi
done < brew-casks.txt

# Install apps from App Store
echo "Installing app store apps via brew..."
while IFS= read -r masId || [ -n "$cask" ]; do
    # Skip empty lines and comments
    if [ ! -z "$masId" ] && [[ ! "$masId" =~ ^[[:space:]]*# ]]; then
        mas install "${masId}"
    fi
done < brew-mas.txt

# Check if stow is installed
if ! command -v stow &> /dev/null; then
    echo "Error: GNU Stow is not installed"
    echo "Run the brew install script first?"
    exit 1
fi

# Run stow on each directory in config/
echo "Stowing dotfiles..."
for dir in config/*/; do
    if [ -d "$dir" ]; then
        dirname=$(basename "$dir")
        echo "--> Stowing $dirname..."
        stow --dir config --target "$HOME" "$dirname"
    fi
done

echo "Done!"
