#!/usr/bin/env bash

# Install mas itself
brew install mas

# Install apps
apps=(
    '904280696' # Things 3
    '1091189122' # Bear
    '1357379892' # Menu Bar Controller for Sonos
    '1289583905' # Pixelmator Pro
    '409183694' # Keynote
    '639968404' # Parcel
)

for i in "${apps[@]}" ; do
   mas install "${i}"
done
