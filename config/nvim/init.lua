-- Not much is going on:
-- - Install Telescope for fuzzy file search
-- - Install nice theme matching WezTerm
-- - Set Space for the leader key
-- - Define basic key binding for Telescope

-- leader must be set before mappings
vim.g.mapleader = " "

-- plugins
vim.pack.add {
  { src = "https://github.com/nvim-lua/plenary.nvim" }, -- Telescope dep
  { src = "https://github.com/nvim-telescope/telescope.nvim" },
  { src = "https://github.com/folke/tokyonight.nvim" },
}

-- plugins setup (safe if not yet installed)
pcall(function()
  require("telescope").setup({
    defaults = {
      layout_config = {
        preview_width = 0.6,
      },
    },
    pickers = {
      find_files = {
        previewer = true,
      },
      live_grep = {
        previewer = true,
      },
      buffers = {
        previewer = true,
      },
    },
  })
  vim.cmd.colorscheme("tokyonight-night")
end)

-- keymaps
local telescope_builtin = function(name)
  return function()
    require("telescope.builtin")[name]()
  end
end

vim.keymap.set("n", "<leader>f", telescope_builtin("find_files"), { silent = true, desc = "Find files" })
vim.keymap.set("n", "<leader>g", telescope_builtin("live_grep"),  { silent = true, desc = "Grep project" })
vim.keymap.set("n", "<leader>b", telescope_builtin("buffers"),    { silent = true, desc = "Buffers" })
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR><Esc>", { silent = true })
