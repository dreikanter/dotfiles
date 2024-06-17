hs.hotkey.bind({"cmd", "alt"}, "1", function()
  hs.keycodes.setLayout("English - Ilya Birman Typography")
end)

hs.hotkey.bind({"cmd", "alt"}, "2", function()
  hs.keycodes.setLayout("Russian - Ilya Birman Typography")
end)

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
