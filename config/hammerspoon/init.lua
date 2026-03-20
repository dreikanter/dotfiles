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
local notesPath = os.getenv("NOTES_PATH") or (os.getenv("HOME") .. "/Dropbox/Notes")
local subl = "/opt/homebrew/bin/subl"

local function openInSubl(filePath)
  hs.task.new(subl, nil, {"--add", notesPath, filePath}):start()
end

local function notesRun(args, callback)
  hs.task.new("/bin/zsh", function(exitCode, stdout, stderr)
    if exitCode == 0 and callback then
      callback(stdout:gsub("%s+$", ""))
    elseif exitCode ~= 0 then
      print("notes error: " .. (stderr or ""))
    end
  end, {"-lc", "notes " .. args}):start()
end

local noteKeys = {
  n = {cmd = "new"},
  l = {cmd = "latest"},
  t = {cmd = "latest todo"},
  b = {cmd = "latest backlog"},
  w = {cmd = "latest weekly"},
}

for key, cfg in pairs(noteKeys) do
  local hk = hs.hotkey.new({"ctrl", "shift"}, key, function()
    print("ctrl+shift+" .. key .. " pressed")
    notesRun(cfg.cmd, openInSubl)
  end)
  local ok = hk:enable()
  if ok then
    print("Registered ctrl+shift+" .. key)
  else
    print("FAILED to register ctrl+shift+" .. key)
  end
end

