-- Not much is going on

vim.g.mapleader = " " -- leader must be set before mappings
vim.g.editorconfig = true
vim.o.number = true
vim.o.relativenumber = true
vim.o.clipboard = "unnamedplus"

-- plugins

vim.pack.add {
  { src = "https://github.com/folke/tokyonight.nvim" },
  { src = "https://github.com/echasnovski/mini.nvim" },
  { src = "https://github.com/ibhagwan/fzf-lua" },
  { src = "https://github.com/lewis6991/gitsigns.nvim" }
}

-- plugins setup (safe if not yet installed)

pcall(function()
  vim.cmd.colorscheme("tokyonight-night")

  require("mini.statusline").setup()
  require("mini.diff").setup()
  require("mini.comment").setup()
  require("mini.pick").setup()

  require("fzf-lua").setup({
    winopts = {
      height = 0.85,
      width = 0.90,
      -- row = 0.35,
      -- col = 0.50,
      border = "rounded",
      preview = {
        layout = "vertical",
        vertical = "down:60%",
      },
    },
    keymap = {
      builtin = {
        ["<C-d>"] = "preview-page-down",
        ["<C-u>"] = "preview-page-up",
      },
    },
    fzf_opts = {
      ["--layout"] = "default",
      ["--info"] = "inline",
    },
    files = {
      git_icons = false,
      file_icons = false,
      color_icons = false,
      fd_opts = "--color=never --type f --hidden --follow --exclude .git",
      find_opts = [[-type f -not -path '*/\.git/*' -printf '%P\n']],
    },
    grep = {
      rg_opts = "--hidden --column --line-number --no-heading --color=always --smart-case --max-columns=512",
    },
  })

  require('gitsigns').setup {
    signcolumn = false,
    current_line_blame = true
  }
end)

-- keymaps

map = vim.keymap.set

map("n", "<leader>tw", function()
  vim.wo.wrap = not vim.wo.wrap
  vim.wo.linebreak = vim.wo.wrap
  vim.notify(vim.wo.wrap and "Word wrap" or "No wrap")
end, { desc = "Toggle word wrap" })

map("n", "<leader>f", require("fzf-lua").files, { desc = "Find files" })
map("n", "<leader>w", "<cmd>w<CR>", { silent = true, desc = "Save file" })
map("n", "<leader>r", "<cmd>luafile ~/.config/nvim/init.lua<CR><cmd>echo 'Config reloaded'<CR>", { desc = "Reload config" })
map("n", "<Esc>", "<cmd>nohlsearch<CR><Esc>", { silent = true, desc = "Clear search highlights" })

map({"n", "x"}, "<leader>h", "^")
map({"n", "x"}, "<leader>l", "$")

map("n", "<leader>gg", "<cmd>Gitsigns toggle_signs<CR>", { desc = "Gitsigns: signs" })
map("n", "<leader>gn", "<cmd>Gitsigns toggle_numhl<CR>", { desc = "Gitsigns: numhl" })
map("n", "<leader>gl", "<cmd>Gitsigns toggle_linehl<CR>", { desc = "Gitsigns: linehl" })
map("n", "<leader>gw", "<cmd>Gitsigns toggle_word_diff<CR>", { desc = "Gitsigns: word_diff" })
map("n", "<leader>gd", "<cmd>Gitsigns toggle_deleted<CR>", { desc = "Gitsigns: deleted" })

-- https://github.com/nvim-lua/kickstart.nvim/blob/master/init.lua
