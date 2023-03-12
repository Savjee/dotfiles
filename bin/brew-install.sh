#!/usr/bin/env bash

# Install homebrew itself
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

# Programming languages
brew install node
brew install python

# Other dependencies
brew install ffmpeg

# Apps
apps=(
    'alfred'
    'appcleaner'
    'arc'
    'arq'
    'audacity'
    'autodesk-fusion360'
    'blender'
    'blockblock'
    'calibre'
    'cloudflare-warp'
    'cyberduck'
    'doxie'
    'drawio'
    'fork'
    'gnucash'
    'google-drive'
    'imageoptim'
    'istat-menus'
    'microsoft-teams'
    'mimestream'
    'mkvtoolnix'
    'netnewswire'
    'nucleo'
    'obs'
    'obsidian'
    'omnidisksweeper'
    'plex'
    'postman'
    'prusaslicer'
    'rectangle'
    'sabnzbd'
    'sketch'
    'slack'
    'spotify'
    'the-unarchiver'
    'thingsmacsandboxhelper'
    'transmission'
    'visual-studio-code'
    'vlc'
    'whatsapp'
    'zeplin'
)

for i in "${apps[@]}" ; do
   brew install --cask "${i}"
done



# Fonts
brew tap homebrew/cask-fonts
brew install --cask font-fira-code
brew install --cask font-jetbrains-mono