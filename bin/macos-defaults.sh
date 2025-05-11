#!/usr/bin/env bash

# ------------------------------------------------------------------------
#                               DOCK
# ------------------------------------------------------------------------

# Remove the hiding Dock Delay in OS X
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0

# Dock: don't show recent apps (only running apps)
defaults write com.apple.dock show-recents -bool false

# ------------------------------------------------------------------------
#                               MISSION CONTROL
# ------------------------------------------------------------------------

# Disable automatically rearrange Spaces based on recent use
defaults write com.apple.dock mru-spaces -bool false

# Top left screen corner → Mission Control
defaults write com.apple.dock wvous-tl-corner -int 2
defaults write com.apple.dock wvous-tl-modifier -int 0

# Top right screen corner → Desktop
defaults write com.apple.dock wvous-tr-corner -int 4
defaults write com.apple.dock wvous-tr-modifier -int 0

# Bottom right screen corner -> Screensaver
defaults write com.apple.dock wvous-br-corner -int 5
defaults write com.apple.dock wvous-br-modifier -int 0

# Don't show recent apps in dock
defaults write com.apple.dock show-recents -bool false

# ------------------------------------------------------------------------
#                               OTHERS
# ------------------------------------------------------------------------

# Disable automatic capitalization as it’s annoying when typing code
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# Disable automatic period substitution as it’s annoying when typing code
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

# Disable auto-correct
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# Disable “natural” (Lion-style) scrolling
# Requires a restart!
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false

# Trackpad: enable tap to click for this user and for the login screen
# Requires a restart!
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# ------------------------------------------------------------------------
#                               FINDER
# ------------------------------------------------------------------------
# Finder: show status bar
defaults write com.apple.finder ShowStatusBar -bool true

# When performing a search, search the current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Prefill NAS connection when pressing Cmd+K
defaults write com.apple.finder FXConnectToLastURL -string "smb://xavier@192.168.2.216/"

# Automatically resize columns based on filenames
defaults write com.apple.finder _FXEnableColumnAutoSizing -bool true

# ------------------------------------------------------------------------
#                               SAFARI
# ------------------------------------------------------------------------
# Hide Safari’s bookmarks bar by default
defaults write com.apple.Safari ShowFavoritesBar -bool false

# Hide Safari’s sidebar in Top Sites
defaults write com.apple.Safari ShowSidebarInTopSites -bool false

# Enable the Develop menu and the Web Inspector in Safari
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true

# ------------------------------------------------------------------------
#                           ACTIVITY MONTOR
# ------------------------------------------------------------------------
# Show all processes in Activity Monitor
defaults write com.apple.ActivityMonitor ShowCategory -int 0

# Sort Activity Monitor results by CPU usage
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0

# ------------------------------------------------------------------------
#                            RESTART APPS
# ------------------------------------------------------------------------
killall Dock
killall Finder