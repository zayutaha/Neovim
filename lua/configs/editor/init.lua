return {
  { import = "configs.editor.ui" },
  { import = "configs.editor.ai" },

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
        "rust-analyzer",
      },
    },
  },

  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig" },
    opts = {
      automatic_enable = false,
    },
  },

  -- {
  --   "m4xshen/hardtime.nvim",
  --   lazy = false,
  --   dependencies = { "MunifTanjim/nui.nvim", "rcarriga/nvim-notify" },
  --   opts = {},
  -- },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "vim",
        "lua",
        "vimdoc",
        "html",
        "rust",
        "typescript",
        "go",
      },
    },
  },
}
