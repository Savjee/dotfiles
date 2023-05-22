# dotfiles

**WARNING: THIS REPOSITORY CANNOT BE MADE PUBLIC**
It contains passwords & tokens that should remain private!


## Manual steps

### Alfred
Set the preference folder to `linked_files/alfred/`.

### Configure crontabs

```
2 * * * * /Users/xavier/Workspace/Projects/dotfiles/scripts/obsidian-commit.sh >/dev/null 2>&1
```