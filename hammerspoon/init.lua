for idx, layout in pairs(hs.keycodes.layouts()) do
  hs.hotkey.bind({ "cmd", "alt" }, tostring(idx), function()
    hs.keycodes.setLayout(layout)
  end)
end

hs.hotkey.bind({"ctrl", "shift"}, "n", function()
  hs.execute("~/.dotfiles/bin/new-note", true)
end)

hs.hotkey.bind({"ctrl", "shift"}, "l", function()
  hs.execute("~/.dotfiles/bin/latest-note", true)
end)

hs.hotkey.bind({"ctrl", "shift"}, "t", function()
  hs.execute("~/.dotfiles/bin/latest-todo", true)
end)

hs.hotkey.bind({"ctrl", "shift"}, "b", function()
  hs.execute("~/.dotfiles/bin/latest-backlog", true)
end)
