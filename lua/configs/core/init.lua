require "configs.core.media"
require "configs.core.tools"
require "configs.core.ui"

return {
  {
    "nvimtools/none-ls.nvim",
    ft = { "python" },
    dependencies = {
      "nvimtools/none-ls-extras.nvim",
    },
    config = function()
      require "configs.tools.none-ls"
    end,
  },
  {
    "stevearc/conform.nvim",
    lazy = false,
    event = "BufWritePre",
    opts = require "configs.conform",
  },

  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "pyright",
        "mypy",
        "typescript-language-server",
        "tailwind-language-server",
        "eslint-lsp",
        "gopls",
        "prettier",
        "prettierd",
        "stylua",
      },
    },
  },

  {
    "m4xshen/hardtime.nvim",
    lazy = false,
    dependencies = { "MunifTanjim/nui.nvim", "rcarriga/nvim-notify" },
    opts = {},
  },
}
