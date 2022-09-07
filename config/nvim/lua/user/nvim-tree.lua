require("nvim-tree").setup({
  renderer = {
    icons = {
      webdev_colors = true,
      git_placement = "before",
      padding = " ",
      symlink_arrow = " ➛ ",
      show = {
        file = false,
        folder = false,
        folder_arrow = false,
        git = true,
      },
      glyphs = {
        default = "",
        symlink = "",
        bookmark = "",
        folder = {
          arrow_closed = "",
          arrow_open = "",
          default = "",
          open = "",
          empty = "",
          empty_open = "",
          symlink = "",
          symlink_open = "",
        },
        git = {
          unstaged = "?",
          staged = "s",
          unmerged = "!",
          renamed = "%",
          untracked = "★",
          deleted = "d",
          ignored = "i",
        },
      },
    }
  }
})
