hs.hotkey.bind({"cmd", "alt"}, "1", function()
  hs.keycodes.setLayout("English - Ilya Birman Typography")
end)

hs.hotkey.bind({"cmd", "alt"}, "2", function()
  hs.keycodes.setLayout("Russian - Ilya Birman Typography")
end)

hs.hotkey.bind({"ctrl", "shift"}, "n", function()
  hs.execute("~/.dotfiles/bin/create_note", true)
end)

hs.hotkey.bind({"ctrl", "shift"}, "l", function()
  hs.execute("~/.dotfiles/bin/open_last_note", true)
end)

hyper = {"ctrl", "alt", "cmd"}
