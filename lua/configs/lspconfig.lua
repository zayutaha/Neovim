-- load defaults i.e lua_lsp
require("nvchad.configs.lspconfig").defaults()

local lspconfig = require "lspconfig"

local servers = { "html", "cssls", "ts_ls", "eslint"}
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

-- Enable tiny inline diagnostics on in python or lua files
-- if vim.bo.filetype == 'python' or vim.bo.filetype == 'lua'  then
  vim.diagnostic.config({ virtual_text = false })
-- else
  -- vim.diagnostic.config({ virtual_text = true })
-- end
