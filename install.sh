#!/bin/bash

# Install Homebrew
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install brew packages
packages=(
    # Core utilities
    'stow'
    'rclone'
    'curl'
    'wget'
    'htop'

    # Media tools
    'ffmpeg'
    'yt-dlp'

    # YouTube archiver tools
    'gpg'
    'par2'

    # Development tools
    'fzf'
    'zellij'
    'composer'
    'lazydocker'
    'lazygit'
    'php'
    'node'
)

for package in "${packages[@]}"; do
    brew install "${package}"
done

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
