local lspconfig = require "nvchad.configs.lspconfig"

vim.g.rustaceanvim = {
  server = {
    on_attach = lspconfig.on_attach,
    capabilities = lspconfig.capabilities,
    default_settings = {
      ["rust-analyzer"] = {
        cargo = {
          allFeatures = true,
        },
        check = {
          command = "check",
        },
        procMacro = {
          enable = true,
        },
      },
    },
  },
}
