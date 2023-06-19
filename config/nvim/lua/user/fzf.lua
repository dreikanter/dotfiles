require("fzf-lua").setup({
  actions = {
    cwd_only = function()
      return vim.api.nvim_command("pwd") ~= vim.env.HOME
    end
  },
  files = {
    path_shorten = 1,
  },
  winopts = {
    height = 0.9,
    width = 0.9,
    row = 0.5,
    col = 0.5,
    preview = {
      vertical = "down:70%",
      layout = "vertical",
    }
  }
})
