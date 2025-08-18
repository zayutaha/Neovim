local lspconfig = require "lspconfig"
local nvlsp = require "nvchad.configs.lspconfig"

lspconfig.ts_ls.setup {
  capabilities = nvlsp.capabilities,
  on_attach = nvlsp.on_attach,
}

lspconfig.eslint.setup {
  capabilities = nvlsp.capabilities,
  on_attach = nvlsp.on_attach,
}

lspconfig.tailwindcss.setup {
  capabilities = nvlsp.capabilities,
  on_attach = nvlsp.on_attach,
}
