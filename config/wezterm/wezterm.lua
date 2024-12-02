local wezterm = require("wezterm")
local action = wezterm.action

-- Color schemes
-- https://wezfurlong.org/wezterm/colorschemes/a/index.html

return {
  color_scheme = "Afterglow",
  font = wezterm.font("JetBrains Mono"),
  font_size = 16.0,
  window_close_confirmation = "NeverPrompt",
  keys = {
    { key = "l", mods = "CMD|SHIFT", action = action.ShowDebugOverlay },
    {
      key = "k",
      mods = "CMD",
      action = action.ClearScrollback("ScrollbackAndViewport"),
    },
    { key = "f", mods = "CMD", action = action.Search("CurrentSelectionOrEmptyString") },
    { key = "q", mods = "CMD", action = action.QuitApplication },
    { key = "w", mods = "CMD", action = action.CloseCurrentTab({ confirm = false }) },
    { key = "a", mods = "CMD|SHIFT", action = action.QuickSelect },
  },
}
