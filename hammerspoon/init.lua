hs.hotkey.bind({"cmd", "alt"}, "1", function()
  hs.keycodes.setLayout("English - Ilya Birman Typography")
end)

hs.hotkey.bind({"cmd", "alt"}, "2", function()
  hs.keycodes.setLayout("Russian - Ilya Birman Typography")
end)

hs.hotkey.bind({"cmd", "alt"}, "\\", function()
  hs.eventtap.keyStroke({}, "`")
end)

-- function os.capture(cmd)
--   local handle = assert(io.popen(cmd, 'r'))
--   local output = assert(handle:read('*a'))
--   handle:close()
--   return string.gsub(string.gsub(string.gsub(output, '^%s+', ''), '%s+$', ''), '[\n\r]+', ' ')
-- end

hs.hotkey.bind({"ctrl", "alt", "shift"}, "n", function()
  os.execute("nohup ~/.dotfiles/bin/create_note &")
end)

hs.hotkey.bind({"ctrl", "alt", "shift"}, "l", function()
  os.execute("nohup ~/.dotfiles/bin/open_last_note &", true)
end)

hs.hotkey.bind({"ctrl", "shift"}, "n", function()
  hs.execute("~/.dotfiles/bin/create_note.rb", true)
end)

hs.hotkey.bind({"ctrl", "shift"}, "l", function()
  hs.execute("~/.dotfiles/bin/open_last_note.rb", true)
end)

-- hyper = {"ctrl", "alt", "cmd"}
