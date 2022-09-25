require("fzf-lua").setup({
  actions = {
    cwd_only = function()
      return vim.api.nvim_command("pwd") ~= vim.env.HOME
    end
  },
  winopts = {
    height = 0.8,
    width = 0.8,
    row = 0.5,
    col = 0.5,
  }
})
