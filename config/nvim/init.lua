require "user.options"
require "user.keymaps"
require "user.plugins"
require "user.nvim-tree"
require "user.lualine"
require "user.which-key"

local group = vim.api.nvim_create_augroup("Markdown", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  command = "setlocal wrap linebreak",
  group = group
})

