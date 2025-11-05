vim.diagnostic.config { virtual_text = false }

local servers = {
  "html",
  "cssls",
  "ts_ls",
  "eslint",
  "tailwindcss",
  "gopls",
  "pyright",
}

vim.lsp.enable(servers)

vim.schedule(function()
  require("nvchad.configs.lspconfig").defaults()
  require "configs.languages.typescript.lsp"
  require "configs.languages.python.lsp"
  require "configs.languages.go.lsp"
end)
