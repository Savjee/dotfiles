# Shared packages for every host (macOS, Linux, …).
# These are packages that should always be available.
pkgs: with pkgs; [
  # Dev tools
  git # Version control
  lazygit # Git TUI
  curl # HTTP client

  # Fancy terminal
  eza # Modern replacement for ls
  bat # Syntax-highlighting cat

  # Setup tools
  stow # File symlink manager

  # YouTube archival tools
  gnupg
  par2cmdline # Creating and using PAR2

  # Various
  ffmpeg
  yt-dlp # Audio/video downloader
]
