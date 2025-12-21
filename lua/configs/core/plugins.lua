return {
    "stevearc/conform.nvim",
    lazy = false,
    event = "BufWritePre",
    opts = require "configs.conform",
}

