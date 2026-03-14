require("hs.ipc")

-- Keyboard layout switching
-- Cmd+Option+1 → English, Cmd+Option+2 → Russian

local function switchLayout(pattern)
  for _, name in ipairs(hs.keycodes.layouts()) do
    if name:lower():find(pattern:lower()) then
      hs.keycodes.setLayout(name)
      return
    end
  end
  hs.alert.show("Layout not found: " .. pattern)
end

hs.hotkey.bind({"cmd", "alt"}, "1", function() switchLayout("english") end)
hs.hotkey.bind({"cmd", "alt"}, "2", function() switchLayout("russian") end)

-- Notes control (Ctrl+Shift)
local dotfiles = os.getenv("HOME") .. "/.dotfiles/bin/"
local function run(script)
  hs.task.new("/bin/zsh", nil, {"-lc", dotfiles .. script}):start()
end

local noteKeys = {
  n = "new-note",
  l = "latest-note",
  t = "latest-todo",
  b = "latest-backlog",
  w = "latest-weekly",
}

for key, script in pairs(noteKeys) do
  local hk = hs.hotkey.new({"ctrl", "shift"}, key, function()
    print("ctrl+shift+" .. key .. " pressed")
    run(script)
  end)
  local ok = hk:enable()
  if ok then
    print("Registered ctrl+shift+" .. key)
  else
    print("FAILED to register ctrl+shift+" .. key)
  end
end

