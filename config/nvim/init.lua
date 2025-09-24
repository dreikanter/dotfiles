-- Not much is going on

vim.g.mapleader = " " -- leader must be set before mappings
vim.g.editorconfig = true
vim.o.number = true
vim.o.relativenumber = true
vim.o.clipboard = "unnamedplus"
vim.o.compatible = false
vim.o.title = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.smartindent = true
vim.o.showmode = false -- do not show mode, since statusline shows it anyway

-- plugins

vim.pack.add {
  { src = "https://github.com/nvim-lua/plenary.nvim" },
  { src = "https://github.com/folke/tokyonight.nvim" },
  { src = "https://github.com/echasnovski/mini.nvim" },
  { src = "https://github.com/lewis6991/gitsigns.nvim" },
  { src = "https://github.com/stevearc/oil.nvim" },
  { src = "https://github.com/nvim-telescope/telescope.nvim" }
}

-- plugins setup (safe if not yet installed)

pcall(function()
  vim.cmd.colorscheme("tokyonight-night")

  require("mini.statusline").setup()
  require("mini.diff").setup()
  require("mini.comment").setup()
  require("oil").setup({ default_file_explorer = true })
  require("telescope").setup({})

  require('gitsigns').setup({
    signcolumn = false,
    current_line_blame = true
  })
end)

-- keymaps

map = vim.keymap.set

map("n", "<leader>tw", function()
  vim.wo.wrap = not vim.wo.wrap
  vim.wo.linebreak = vim.wo.wrap
  vim.notify(vim.wo.wrap and "Word wrap" or "No wrap")
end, { desc = "Toggle word wrap" })

-- map("n", "<leader>f", require("fzf-lua").files, { desc = "Find files" })
map("n", "<leader>w", "<cmd>w<CR>", { silent = true, desc = "Save file" })
map("n", "<leader>r", "<cmd>luafile ~/.config/nvim/init.lua<CR><cmd>echo 'Config reloaded'<CR>", { desc = "Reload config" })
map("n", "<Esc>", "<cmd>nohlsearch<CR><Esc>", { silent = true, desc = "Clear search highlights" })
map("n", "<leader>-", "<cmd>Oil<CR>", { desc = "Open parent directory" })

map({"n", "x"}, "<leader>h", "^")
map({"n", "x"}, "<leader>l", "$")
map("n", "<C-d>", "<C-d>zz") -- center cursor on screen after page-down, Ctrl-D
map("n", "<C-u>", "<C-u>zz") -- center cursor on screen after page-up, Ctrl-U

local builtin = require("telescope.builtin")
map('n', '<leader>ff', builtin.find_files, {})
map('n', '<leader>fg', require("telescope.builtin").live_grep, {})
map('n', '<leader>fb', require("telescope.builtin").buffers, {})
map('n', '<leader>fh', require("telescope.builtin").help_tags, {})

map("n", "<leader>gg", "<cmd>Gitsigns toggle_signs<CR>", { desc = "Gitsigns: signs" })
map("n", "<leader>gn", "<cmd>Gitsigns toggle_numhl<CR>", { desc = "Gitsigns: numhl" })
map("n", "<leader>gl", "<cmd>Gitsigns toggle_linehl<CR>", { desc = "Gitsigns: linehl" })
map("n", "<leader>gw", "<cmd>Gitsigns toggle_word_diff<CR>", { desc = "Gitsigns: word_diff" })
map("n", "<leader>gd", "<cmd>Gitsigns toggle_deleted<CR>", { desc = "Gitsigns: deleted" })
map("v", "<leader>s", "\"hy:%s/<C-r>h//g<left><left>")

-- https://github.com/nvim-lua/kickstart.nvim/blob/master/init.lua
