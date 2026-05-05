require "configs.languages.typescript.lsp"
require "configs.languages.python.lsp"
require "configs.languages.go.lsp"
require "configs.languages.rust.lsp"
require "configs.languages.kotlin.lsp"

vim.diagnostic.config { virtual_text = false }

vim.lsp.config("tailwindcss", {
  init_options = {
    userLanguages = { rust = "html" },
  },
  settings = {
    tailwindCSS = {
      experimental = {
        classRegex = { [[class\s*:\s*"([^"]*)"]] },
      },
      includeLanguages = { rust = "html" },
    },
  },
  filetypes = { "css", "html", "rust" },
})

vim.lsp.enable {
  "html",
  "cssls",
  "ts_ls",
  "eslint",
  "tailwindcss",
  "gopls",
  "pyright",
  "rust_analyzer",
  "kotlin_language_server",
}
