# This Mac: platform, macOS-only packages, and system defaults.
{ pkgs, ... }:
{
  nixpkgs.hostPlatform = "aarch64-darwin";

  environment.systemPackages = with pkgs; [
    aerospace # Tiling window manager
    jankyborders # Add colored border to active windows
  ];

  time.timeZone = "Europe/Brussels";

  system.defaults = {
    dock = {
      autohide = true;
      autohide-delay = 0.0;
      show-recents = false;
      mru-spaces = false;

      # Hot corners: 2 = Mission Control, 4 = Desktop, 5 = Start Screen Saver
      wvous-tl-corner = 2;
      wvous-tr-corner = 4;
      wvous-br-corner = 5;
    };

    NSGlobalDomain = {
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
      "com.apple.swipescrolldirection" = false;
      "com.apple.mouse.tapBehavior" = 1;
      PMPrintingExpandedStateForPrint = true;
      PMPrintingExpandedStateForPrint2 = true;
      AppleMeasurementUnits = "Centimeters";
      AppleMetricUnits = 1;
    };

    trackpad.Clicking = true;

    finder = {
      ShowStatusBar = true;
      FXDefaultSearchScope = "SCcf";
      FXPreferredViewStyle = "Nlsv";
      _FXEnableColumnAutoSizing = true;
      ShowExternalHardDrivesOnDesktop = false;
      ShowHardDrivesOnDesktop = false;
      ShowMountedServersOnDesktop = false;
      ShowRemovableMediaOnDesktop = false;
      FXEnableExtensionChangeWarning = false;
    };

    ActivityMonitor = {
      ShowCategory = 0;
      SortColumn = "CPUUsage";
      SortDirection = 0;
    };

    # Keys without first-class nix-darwin options (and Safari; may be ignored by modern Safari).
    CustomUserPreferences = {
      NSGlobalDomain = {
        AppleLanguages = [
          "en"
          "nl"
        ];
        AppleLocale = "en_US@currency=EUR";
      };

      "com.apple.finder" = {
        FXConnectToLastURL = "smb://xavier@192.168.2.216/";
      };

      "com.apple.desktopservices" = {
        DSDontWriteNetworkStores = true;
        DSDontWriteUSBStores = true;
      };

      "com.apple.dock" = {
        "wvous-tl-modifier" = 0;
        "wvous-tr-modifier" = 0;
        "wvous-br-modifier" = 0;
      };

      "com.apple.Safari" = {
        ShowFavoritesBar = false;
        ShowSidebarInTopSites = false;
        IncludeDevelopMenu = true;
        WebKitDeveloperExtrasEnabledPreferenceKey = true;
        "com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled" = true;
      };
    };
  };
}
