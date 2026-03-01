require "configs.languages.typescript.lsp"
require "configs.languages.python.lsp"
require "configs.languages.go.lsp"
require "configs.languages.rust.lsp"

vim.diagnostic.config { virtual_text = false }

vim.lsp.enable {
  "html",
  "cssls",
  "ts_ls",
  "eslint",
  "tailwindcss",
  "gopls",
  "pyright",
  "rust_analyzer",
}
