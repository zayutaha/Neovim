require("nvchad.configs.lspconfig").defaults()
require "configs.languages.typescript.lsp"
require "configs.languages.python.lsp"
require "configs.languages.go.lsp"

vim.diagnostic.config { virtual_text = false }

local lspconfig = require "lspconfig"

local servers = { "html", "cssls" }
local nvlsp = require "nvchad.configs.lspconfig"

for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = nvlsp.on_attach,
    on_init = nvlsp.on_init,
    capabilities = nvlsp.capabilities,
  }
end
