require "configs.languages.typescript.lsp"
require "configs.languages.python.lsp"
require "configs.languages.go.lsp"

vim.diagnostic.config { virtual_text = false }

vim.lsp.enable {
  "html",
  "cssls",
  "tsserver",
  "eslint",
  "tailwindcss",
  "gopls",
  "pyright",
}
