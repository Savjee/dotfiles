-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- The launcher reads optional scaling workarounds from the machine package.
-- Unbind existing SUPER+SHIFT+SLASH (was: Passwords via omarchy 1password).
hl.unbind("SUPER + SHIFT + SLASH")
o.bind("SUPER + SHIFT + SLASH", "Passwords", { launch = os.getenv("HOME") .. "/.local/bin/1password-launch" })

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Belgian AZERTY: Omarchy resize uses US keycodes (code:20/21 = ) and -).
-- Bind the real = key (next to right Shift) so Option + = matches the overlay.
o.bind("SUPER + EQUAL", "Shrink window left", hl.dsp.window.resize({ x = 100, y = 0, relative = true }))
o.bind("SUPER + SHIFT + EQUAL", "Expand window down", hl.dsp.window.resize({ x = 0, y = 100, relative = true }))
o.bind("SUPER + ALT + EQUAL", "Shrink window left a little", hl.dsp.window.resize({ x = 25, y = 0, relative = true }))
o.bind("SUPER + SHIFT + ALT + EQUAL", "Expand window down a little", hl.dsp.window.resize({ x = 0, y = 25, relative = true }))
o.bind("SUPER + CTRL + EQUAL", "Shrink window left a lot", hl.dsp.window.resize({ x = 300, y = 0, relative = true }))
o.bind("SUPER + CTRL + SHIFT + EQUAL", "Expand window down a lot", hl.dsp.window.resize({ x = 0, y = 300, relative = true }))

-- Aerospace-style consume-or-expel on Option+Command+Left/Right:
--   neighbor in that direction → tile underneath it
--   nothing there → promote out of the current split to a full-height column
--   (needed when a new window nested with the bottom pane, not the whole stack)
local function consume_or_expel(dir)
  local active = hl.get_active_window()
  local workspace = hl.get_active_workspace()
  if not active or active.floating or not workspace then
    return
  end

  if workspace.tiled_layout == "scrolling" then
    local side = dir == "l" and "prev" or "next"
    hl.dispatch(hl.dsp.layout("consume_or_expel " .. side))
    return
  end

  local gap_slop, overlap_min = 30, 20

  local function tiled_windows()
    local windows = {}
    for _, window in ipairs(hl.get_workspace_windows(workspace)) do
      if not window.floating then
        table.insert(windows, window)
      end
    end
    return windows
  end

  local function find_neighbor(windows, origin, toward)
    local best, best_gap = nil, math.huge
    for _, window in ipairs(windows) do
      if window.address ~= origin.address then
        local overlap, gap
        if toward == "l" then
          overlap = math.min(origin.at.y + origin.size.y, window.at.y + window.size.y) - math.max(origin.at.y, window.at.y)
          gap = origin.at.x - (window.at.x + window.size.x)
        elseif toward == "r" then
          overlap = math.min(origin.at.y + origin.size.y, window.at.y + window.size.y) - math.max(origin.at.y, window.at.y)
          gap = window.at.x - (origin.at.x + origin.size.x)
        elseif toward == "u" then
          overlap = math.min(origin.at.x + origin.size.x, window.at.x + window.size.x) - math.max(origin.at.x, window.at.x)
          gap = origin.at.y - (window.at.y + window.size.y)
        else
          overlap = math.min(origin.at.x + origin.size.x, window.at.x + window.size.x) - math.max(origin.at.x, window.at.x)
          gap = window.at.y - (origin.at.y + origin.size.y)
        end
        if overlap > overlap_min and gap >= -gap_slop and gap < best_gap then
          best, best_gap = window, gap
        end
      end
    end
    return best
  end

  local function is_full_height(windows, origin)
    return not find_neighbor(windows, origin, "u") and not find_neighbor(windows, origin, "d")
  end

  local function place_on_side(toward)
    local current = hl.get_active_window()
    local other = find_neighbor(tiled_windows(), current, toward == "r" and "l" or "r")
    if current and other then
      local on_wrong_side = (toward == "r" and current.at.x < other.at.x) or (toward == "l" and current.at.x > other.at.x)
      if on_wrong_side then
        hl.dispatch(hl.dsp.layout("swapsplit"))
      end
    end
  end

  local function after_toggle(partner_address)
    return hl.get_active_window(), hl.get_window("address:" .. partner_address)
  end

  local windows = tiled_windows()
  local beside = find_neighbor(windows, active, dir)

  -- Nothing in that direction: pull out to a full-height column (Aerospace move-out).
  -- A new window often nests with the bottom pane only. Flip that row split
  -- first so movetoroot keeps the other windows stacked as one column.
  if not beside then
    if is_full_height(windows, active) then
      return
    end
    local row_partner = find_neighbor(windows, active, "l") or find_neighbor(windows, active, "r")
    if row_partner then
      hl.dispatch(hl.dsp.layout("togglesplit"))
    end
    hl.dispatch(hl.dsp.layout("movetoroot"))
    active = hl.get_active_window()
    windows = tiled_windows()
    if active and not is_full_height(windows, active) then
      hl.dispatch(hl.dsp.layout("togglesplit"))
    end
    place_on_side(dir)
    return
  end

  -- Neighbor exists: join into a vertical stack with this window underneath.
  local neighbor_address = beside.address
  hl.dispatch(hl.dsp.layout("togglesplit"))
  active, beside = after_toggle(neighbor_address)
  if active and beside and active.at.y < beside.at.y then
    hl.dispatch(hl.dsp.layout("swapsplit"))
  end
end

-- SUPER+CTRL+LEFT/RIGHT was: move grouped window focus.
hl.unbind("SUPER + CTRL + LEFT")
hl.unbind("SUPER + CTRL + RIGHT")
o.bind("SUPER + CTRL + LEFT", "Join left or pull out of stack", function()
  consume_or_expel("l")
end)
o.bind("SUPER + CTRL + RIGHT", "Join right or pull out of stack", function()
  consume_or_expel("r")
end)

-- Magic Keyboard top row (fnmode=2 sends F-keys, not XF86*). Same actions as
-- the stock media binds. F9 was voxtype push-to-talk; use Option+Cmd+X instead.
hl.unbind("F9")
o.bind("F1", "Brightness down", "omarchy-brightness-display 5%-", { locked = true, repeating = true })
o.bind("F2", "Brightness up", "omarchy-brightness-display +5%", { locked = true, repeating = true })
o.bind("F4", "Omarchy menu", "omarchy-menu toggle", { locked = true })
o.bind("F5", "Mute microphone", "omarchy-audio-input-mute", { locked = true })
o.bind("F7", "Previous track", "omarchy-shell media previous", { locked = true })
o.bind("F8", "Play", "omarchy-shell media playPause", { locked = true })
o.bind("F9", "Next track", "omarchy-shell media next", { locked = true })
o.bind("F10", "Mute", "omarchy-audio-output-volume mute-toggle", { locked = true })
o.bind("F11", "Volume down", "omarchy-audio-output-volume lower", { locked = true, repeating = true })
o.bind("F12", "Volume up", "omarchy-audio-output-volume raise", { locked = true, repeating = true })

-- Universal copy: Omarchy sends Ctrl+Insert to terminals. On this keyboard that
-- chord can land as Ctrl+C while Super+C is still held, so Ghostty gets SIGINT.
-- Use Ctrl+Shift+C instead (Ghostty/Kitty/Alacritty/Foot all bind that to copy).
local function send_shortcut_once(mods, key)
  return function()
    hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down" }))
    hl.timer(function()
      hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" }))
    end, { timeout = 50, type = "oneshot" })
  end
end

local function window_is_terminal(window)
  if not window then
    return false
  end

  local class = window.class or window.initial_class or ""
  if class:find("ghostty", 1, true)
      or class:find("Alacritty", 1, true)
      or class:find("kitty", 1, true)
      or class:find("foot", 1, true)
      or class:find("wezterm", 1, true)
      or class:find("org.omarchy.", 1, true)
      or class:find("TUI.", 1, true) then
    return true
  end

  local tags = window.tags
  if type(tags) == "string" then
    return tags:find("terminal", 1, true) ~= nil
  end
  if type(tags) == "table" then
    for _, tag in ipairs(tags) do
      if tostring(tag):gsub("%*$", "") == "terminal" then
        return true
      end
    end
  end

  return false
end

-- Unbind existing SUPER+C (was: Omarchy universal copy via Ctrl+Insert in terminals).
hl.unbind("SUPER + C")
o.bind("SUPER + C", "Universal copy", function()
  if window_is_terminal(hl.get_active_window()) then
    send_shortcut_once("CTRL SHIFT", "C")()
  else
    send_shortcut_once("CTRL", "C")()
  end
end)
