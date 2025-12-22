return {
  { import = "configs.core.tools" },
  { import = "configs.core.ui" },
  { import = "configs.core.ai" },

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
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "vim",
        "lua",
        "vimdoc",
        "html",
        "css",
        "rust",
        "typescript",
        "go",
      },
    },
  },
}

