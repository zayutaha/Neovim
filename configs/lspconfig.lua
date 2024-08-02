-- load defaults i.e lua_lsp
require("nvchad.configs.lspconfig").defaults()

local lspconfig = require "lspconfig"

-- EXAMPLE
local servers = { "html", "cssls", "ruff_lsp", "tsserver" }
local nvlsp = require "nvchad.configs.lspconfig"

-- lsps with default config
for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = nvlsp.on_attach,
    on_init = nvlsp.on_init,
    capabilities = nvlsp.capabilities,
  }
end

-- Needs to be configured explicity due to root_dir
lspconfig.pyright.setup {
  root_dir = vim.loop.cwd,
  on_attach = nvlsp.on_attach,
  on_init = nvlsp.on_init,
  capabilities = nvlsp.capabilities,

}

-- Enable tiny inline diagnostics on in python files
-- if vim.bo.filetype == 'python' then
vim.diagnostic.config({ virtual_text = false })
-- end

