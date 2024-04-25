local wezterm = require 'wezterm'
local action = wezterm.action
local config = wezterm.config_builder()

-- wezterm.on('paste-selection', function(window, pane)
--     local sel = window:get_selection_text_for_pane(pane)
--     pane:send_text(sel)
-- end)

-- config.mouse_bindings = {
--     -- Disable automatic copy to buffer on selection
--     { event = { Up = { streak = 1, button = 'Left' } },   mods = 'NONE', action = action.Nop, },
--     { event = { Up = { streak = 2, button = 'Left' } },   mods = 'NONE', action = action.Nop, },
--     -- 3 stages of text selection
--     { event = { Down = { streak = 2, button = 'Left' } }, mods = 'NONE', action = action.SelectTextAtMouseCursor 'Word', },
--     { event = { Down = { streak = 3, button = 'Left' } }, mods = 'NONE', action = action.SelectTextAtMouseCursor 'Line', },
--     { event = { Down = { streak = 4, button = 'Left' } }, mods = 'NONE', action = action.SelectTextAtMouseCursor 'SemanticZone', },
-- }

config.keys = {
    -- Clear scrollback and viewport
    -- { key = 'k', mods = 'CMD',       action = action.ClearScrollback 'ScrollbackAndViewport' },
    -- Command palette
    -- { key = 'p', mods = 'CMD', action = action.ActivateCommandPalette },
    -- Insert current selection into the terminal
    -- { key = 'v', mods = 'SUPER|SHIFT', action = wezterm.action.EmitEvent 'paste-selection' },
    -- { key = 'v', mods = 'SUPER',       action = action.PasteFrom 'Clipboard' },
}

return config
