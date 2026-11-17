-- MacBook built-in keyboard (Apple ISO, Belgian): use the Apple Belgian
-- layout with Mac-style modifiers (see ~/.config/xkb/symbols/be_apple).
-- Scoped to this device so external PC keyboards keep the normal layout.
hl.device({
  name = "apple-mtp-keyboard",
  kb_layout = "be_apple",
  kb_options = "omarchy:shift_caps_compose",
})
