hs.hotkey.bind({"cmd", "alt"}, "1", function()
  hs.keycodes.setLayout("English - Ilya Birman Typography")
end)

hs.hotkey.bind({"cmd", "alt"}, "2", function()
  hs.keycodes.setLayout("Russian - Ilya Birman Typography")
end)

hs.hotkey.bind({"ctrl", "shift"}, "n", function()
  hs.execute("~/.dotfiles/bin/newnote", true)
end)

hs.hotkey.bind({"ctrl", "shift"}, "l", function()
  hs.execute("~/.dotfiles/bin/lastnote", true)
end)

hs.hotkey.bind({"ctrl", "shift"}, "j", function()
  -- hs.execute("alacritty --working-directory ~/ -e $SHELL -lc 'nvim +WikiJournal && exit' &", true)

  local log = require("hs.logger").new("test", "debug")
  log.i("starting a task")

  hs.task.new(
    "/opt/homebrew/bin/alacritty",
    function(exitCode, stdOut, stdErr)
      log.df("exitCode: %s", exitCode)
      log.df("stdOut: %s", stdOut)
      log.df("stdErr: %s", stdErr)
      return true
    end,
    {"-e", "/Users/alex/.dotfiles/bin/journal"}
  ):start()

  -- local test =  hs.task.new(
  --   "/bin/zsh",
  --   function(exitCode, stdOut, stdErr)
  --     log.df("exitCode: %s", exitCode)
  --     log.df("stdOut: %s", stdOut)
  --     log.df("stdErr: %s", stdErr)
  --     return true
  --   end,
  --   function(task, stdOut, stdErr)
  --     log.df("task: %s", task)
  --     log.df("stdOut: %s", stdOut)
  --     log.df("stdErr: %s", stdErr)
  --     return true
  --   end,
  --   { "-lc", "alacritty --working-directory ~/ -e $SHELL -lc 'nvim +WikiJournal && exit'" }
  -- ):start()
end)
