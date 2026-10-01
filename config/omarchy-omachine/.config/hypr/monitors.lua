-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all
-- Super+/ / Super+Alt+/ cycle Omarchy's scale presets and persist into
-- `omarchy_monitor_scale` / `omarchy_gdk_scale` below.

-- Integer HiDPI for the 32" 6K (~223 ppi). Omarchy already sets
-- Electron/Ozone Wayland hints, xwayland.force_zero_scaling, and cursor 24.
-- GDK_SCALE=2 is for GTK. Electron/Chromium must NOT inherit it on top of
-- the compositor's 2× or chrome goes to ~4× (Helium/1Password/T3 Code).
local omarchy_gdk_scale = 2
local omarchy_monitor_scale = 2

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))

-- Match by description, not connector name. USB-C Alt Mode is DP-3 today;
-- full-size DP was DP-1. Native 6144×3456@60 is the stable mode.
-- Do not plug DP and USB-C video at once: same EDID becomes two 6K outputs.
hl.monitor({ output = "desc:Kuycon G32P", mode = "6144x3456@60", position = "0x0", scale = omarchy_monitor_scale })

-- Previous UltraFine 6K over USB4 (DP-7 / DP-1 depending on cable).
-- hl.monitor({ output = "desc:LG ULTRAFINE", mode = "6144x3456@60", position = "0x0", scale = omarchy_monitor_scale })

-- Previous 40WP95X 5K2K (~140 ppi). Re-enable if that panel comes back.
-- hl.monitor({ output = "desc:40WP95X", mode = "5120x2160@72", position = "0x0", scale = 4 / 3 })

hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })
