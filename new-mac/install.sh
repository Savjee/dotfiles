#!/usr/bin/env bash

# Configure macOS settings
sh macos-defaults.sh

# Install ZSH
sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

# Install homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

# Install applications
sh brew-install.sh
