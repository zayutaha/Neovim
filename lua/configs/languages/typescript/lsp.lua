local lspconfig = vim.lsp.config
local nvlsp = require "nvchad.configs.lspconfig"

lspconfig["ts_ls"] = {
  capabilities = nvlsp.capabilities,
  on_attach = nvlsp.on_attach,
}

lspconfig["eslint"] = {
  capabilities = nvlsp.capabilities,
  on_attach = nvlsp.on_attach,
}

lspconfig["tailwindcss"] = {
  capabilities = nvlsp.capabilities,
  on_attach = nvlsp.on_attach,
}
