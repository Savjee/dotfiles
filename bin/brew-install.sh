#!/usr/bin/env bash

# Install homebrew itself
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

# Programming languages
brew install node
brew install python

# Apps
apps=(
    'alfred'
    'arc'
    'vlc'
    'sketch'
    'appcleaner'
    'arq'
    'blockblock'
    'cyberduck'
    'doxie'
    'gnucash'
    'imageoptim'
    'postman'
    'transmission'
    'zeplin'
    'calibre'
    'the-unarchiver'
    'visual-studio-code'
    'spotify'
    'fork'
    'google-drive'
    'rectangle'
    'istat-menus'
    'whatsapp'
    'audacity'
    'obsidian'
    'cloudflare-warp'
    'drawio'
    'nucleo'
    'obs'
    'omnidisksweeper'
    'prusaslicer'
    'slack'
    'netnewswire'
    'mimestream'
    'mkvtoolnix'
    'plex'
    'thingsmacsandboxhelper'
    'blender'
)

for i in "${apps[@]}" ; do
   brew install --cask "${i}"
done



# Fonts
brew tap homebrew/cask-fonts
brew install --cask font-fira-code
brew install --cask font-jetbrains-mono