-- Not much is going on:
-- - Install Telescope for fuzzy file search
-- - Install mini.statusline
-- - Install nice theme matching WezTerm
-- - Set Space for the leader key
-- - Define some key binding

-- leader must be set before mappings
vim.g.mapleader = " "
vim.g.editorconfig = true
vim.o.number = true
vim.o.relativenumber = true

-- plugins
vim.pack.add {
  { src = "https://github.com/nvim-lua/plenary.nvim" }, -- Telescope dep
  { src = "https://github.com/nvim-telescope/telescope.nvim" },
  { src = "https://github.com/folke/tokyonight.nvim" },
  { src = "https://github.com/echasnovski/mini.nvim" },
}

-- plugins setup (safe if not yet installed)
pcall(function()
  require("telescope").setup({})
  vim.cmd.colorscheme("tokyonight-night")
  require('mini.statusline').setup()
  require('mini.diff').setup()
  require('mini.comment').setup()
end)

-- keymaps
local telescope_builtin = function(name)
  return function()
    require("telescope.builtin")[name]()
  end
end

-- telescope
vim.keymap.set("n", "<leader>f", telescope_builtin("find_files"), { silent = true, desc = "Find files" })
vim.keymap.set("n", "<leader>g", telescope_builtin("live_grep"),  { silent = true, desc = "Grep project" })
vim.keymap.set("n", "<leader>b", telescope_builtin("buffers"),    { silent = true, desc = "Buffers" })

-- general purpose
vim.keymap.set("n", "<leader>w", "<cmd>w<CR>", { silent = true, desc = "Save file" })
vim.keymap.set("n", "<leader>r", "<cmd>luafile ~/.config/nvim/init.lua<CR><cmd>echo 'Reloaded!'<CR>", { desc = "Reload config" })
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR><Esc>", { silent = true, desc = "Clear search highlights" })

-- system clipboard
vim.keymap.set("n", "<leader>y", '"+y', { silent = true, desc = "Yank to system clipboard" })
vim.keymap.set("v", "<leader>y", '"+y', { silent = true, desc = "Yank to system clipboard" })
vim.keymap.set("n", "<leader>p", '"+p', { silent = true, desc = "Paste from system clipboard" })

