#!/bin/bash

# This script is called every hour to push my Obsidian vault to GitHub. This is
# used because the git plugin is single-threaded and locks up Obsidian for 20
# seconds (while making it unusable).
# Source: https://medium.com/analytics-vidhya/how-i-put-my-mind-under-version-control-24caea37b8a5
VAULT_PATH="/Users/xavier/Workspace/XD Brain/"
cd "$VAULT_PATH"

#CHANGES_EXIST="$(git status --porcelain | wc -l)"

#if [ "$CHANGES_EXIST" -eq 0 ]; then
#    echo "No changes exist, exiting"
#    exit 0
#fi

git diff-index --quiet HEAD -- || {
    # Add all changes to the staging area
    git add .

    # Commit the changes with a generic message. Customize the message if needed.
    git commit -m "Auto commit on $(date +"%Y-%m-%d %H:%M:%S")"

    # Push the changes to the origin
    git push origin
}

# #git pull origin master
# git add .
# git commit -q -m "Last Sync: $(date +"%Y-%m-%d %H:%M:%S")"
# git push
# git push
