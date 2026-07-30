local options = {
  format_on_save = {
    timeout_ms = 500,
    lsp_format = "fallback",
  },
  formatters_by_ft = {
    lua = { "stylua" },
    javascript = { "prettierd", "prettier", stop_after_first = true },
    python = { "ruff_organize_imports", "ruff" },
  },
}

return options
