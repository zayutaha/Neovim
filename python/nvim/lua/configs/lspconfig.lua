-- load defaults i.e lua_lsp
require("nvchad.configs.lspconfig").defaults()

vim.diagnostic.config { virtual_text = false }

local lspconfig = require "lspconfig"

local servers = { "html", "cssls", "ts_ls", "eslint", "tailwindcss" }
local nvlsp = require "nvchad.configs.lspconfig"
local util = require "lspconfig/util"

for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = nvlsp.on_attach,
    on_init = nvlsp.on_init,
    capabilities = nvlsp.capabilities,
  }
end
