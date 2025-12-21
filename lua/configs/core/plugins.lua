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
}
