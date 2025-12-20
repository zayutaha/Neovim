local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    python = { "ruff" },

    -- Web / Next.js stack
    javascript = { "prettierd", "prettier" },
    javascriptreact = { "prettierd", "prettier" },
    typescript = { "prettierd", "prettier" },
    typescriptreact = { "prettierd", "prettier" },
    json = { "prettierd", "prettier" },
    css = { "prettierd", "prettier" },
    html = { "prettierd", "prettier" },
    markdown = { "prettierd", "prettier" },
    yaml = { "prettierd", "prettier" },
  },

  format_on_save = {
    timeout_ms = 1000,
    lsp_fallback = true,
  },
}

return options
