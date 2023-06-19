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

return packer.startup(function(use)
  use("wbthomason/packer.nvim") -- Have packer manage itself

  use({
    "airblade/vim-gitgutter",
    config = function()
      vim.g.gitgutter_map_keys = 0
    end
  })

  -- use({
  --   "romgrk/barbar.nvim",
  --   config = function()
  --     require("bufferline").setup()
  --   end
  -- })

  -- use({
  --   "akinsho/bufferline.nvim",
  --   config = function()
  --     require "user.bufferline"
  --   end
  -- })

  use("editorconfig/editorconfig-vim")
  use("folke/which-key.nvim")

  use({
    "ibhagwan/fzf-lua",
    config = function()
      require "user.fzf"
    end
  })

  use("jeffkreeftmeijer/vim-numbertoggle")
  use("kyazdani42/nvim-tree.lua")
  use("kyazdani42/nvim-web-devicons")
  use("ntpeters/vim-better-whitespace")
  use("sheerun/vim-polyglot")
  use("tpope/vim-commentary")
  use("tpope/vim-surround")

  use({
    'goolord/alpha-nvim',
    config = function()
      require('alpha').setup(require('alpha.themes.startify').config)
    end
  })

  use({
    "folke/tokyonight.nvim",
    config = function()
      vim.cmd("colorscheme tokyonight-night")
    end
  })

  use({
    'nvim-lualine/lualine.nvim',
    requires = { "kyazdani42/nvim-web-devicons", opt = true }
  })

  use({
    "preservim/vim-markdown",
    requires = { "godlygeek/tabular", opt = true },
    config = function()
      vim.g.vim_markdown_conceal = 2
    end
  })

  -- use("neovim/nvim-lspconfig")
  -- use("hrsh7th/cmp-nvim-lsp")
  -- use("hrsh7th/cmp-buffer")
  -- use("hrsh7th/cmp-path")
  -- use("hrsh7th/cmp-cmdline")
  -- use("hrsh7th/nvim-cmp")

  use("L3MON4D3/LuaSnip")

  -- use("saadparwaiz1/cmp_luasnip")

  use({
    "psliwka/vim-smoothie",
    config = function()
      require "user.smoothie"
    end
  })

  use({
    "lervag/wiki.vim",
    config = function()
      vim.g.wiki_root = "~/wiki"
      vim.g.wiki_filetypes = { 'md' }
      vim.g.wiki_link_extension = '.md'
    end
  })

  -- use({
  --   "vimwiki/vimwiki",
  --   config = function()
  --     vim.g.vimwiki_list = {
  --       {
  --         path = "~/wiki",
  --         syntax = "markdown",
  --         ext = ".md",
  --       }
  --     }
  --   end
  -- })

  use({
    "nvim-treesitter/nvim-treesitter",
    config = function()
      require("user.treesitter")
    end
  })

  use({
    "lukas-reineke/indent-blankline.nvim",
    config = function()
      require("indent_blankline").setup({
        -- show_current_context = true,
        show_current_context_start = true,
      })
    end
  })

  use({
    "phaazon/hop.nvim",
    branch = "v2",
    config = function()
      require("hop").setup()
    end
  })

  use("opdavies/toggle-checkbox.nvim")

  use({
    "ellisonleao/glow.nvim",
    config = function()
      -- require("glow").setup({
      --   width = 80,
      --   style = "light",
      -- })
    end
  })

  use({"junegunn/goyo.vim"})

  -- use({
  --   "lyokha/vim-xkbswitch",
  --   config = function()
  --     vim.g.XkbSwitchEnabled = 1
  --   end
  -- })
end)

