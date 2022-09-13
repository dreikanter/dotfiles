-- Autocommand that reloads neovim whenever you save the plugins.lua file
vim.cmd([[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost plugins.lua source <afile> | PackerSync
  augroup end
]])

-- Use a protected call so we don't error out on first use
local status_ok, packer = pcall(require, "packer")
if not status_ok then
  return
end

-- Have packer use a popup window
packer.init({
  display = {
    open_fn = function()
      return require("packer.util").float({ border = "rounded" })
    end,
  },
})

-- Install your plugins here
return packer.startup(function(use)
  use("wbthomason/packer.nvim") -- Have packer manage itself

  use("airblade/vim-gitgutter")

  -- use({
  --     "akinsho/bufferline.nvim",
  --     config = function()
  --       require "user.bufferline"
  --     end
  --   })

  use("ctrlpvim/ctrlp.vim")
  use("editorconfig/editorconfig-vim")
  use("folke/which-key.nvim")
  use("jeffkreeftmeijer/vim-numbertoggle")
  use("kyazdani42/nvim-tree.lua")
  use("kyazdani42/nvim-web-devicons")
  use("sheerun/vim-polyglot")
  use("tpope/vim-surround")
  use("ibhagwan/fzf-lua")
  use("ntpeters/vim-better-whitespace")
  use("tpope/vim-commentary")

  -- Themes
  use({
    "folke/tokyonight.nvim",
    config = function()
      vim.cmd("colorscheme tokyonight-night")
    end
  })

  -- use("lunarvim/darkplus.nvim")

  use {
    "vimwiki/vimwiki",
    config = function()
      vim.g.vimwiki_list = {{
        path = "~/wiki/",
        syntax = "markdown",
        ext = ".md"
      }}
    end
  }

  use({
    'nvim-lualine/lualine.nvim',
    requires = { 'kyazdani42/nvim-web-devicons', opt = true }
  })
end)

