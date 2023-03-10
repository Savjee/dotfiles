#!/usr/bin/env bash

# Make sure the path exists
mkdir -p ~/Library/Application\ Support/Code/User/

rm -f ~/Library/Application\ Support/Code/User/keybindings.json
rm -f ~/Library/Application\ Support/Code/User/settings.json

# Create Symlinks
ln -s ~/Workspace/Projects/dotfiles/linked_files/vscode/keybindings.json ~/Library/Application\ Support/Code/User/keybindings.json
ln -s ~/Workspace/Projects/dotfiles/linked_files/vscode/settings.json ~/Library/Application\ Support/Code/User/settings.json

# Install extensions
extensions=(
    'Angular.ng-template'
    'espressif.esp-idf-extension'
    'ms-azuretools.vscode-docker'
    'ms-python.flake8'
    'ms-python.isort'
    'ms-python.pylint'
    'ms-python.python'
    'ms-python.vscode-pylance'
    'ms-vscode-remote.remote-containers'
    'vscodevim.vim'
)

for i in "${extensions[@]}" ; do
   code --install-extension "${i}"
done
