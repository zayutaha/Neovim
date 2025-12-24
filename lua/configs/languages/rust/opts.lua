local on_attach = require("nvchad.configs.lspconfig").on_attach
local capabilities = require("nvchad.configs.lspconfig").capabilities

capabilities.offsetEncoding = { "utf-16" }

local options = {
  server = {
    on_attach = on_attach,
    capabilities = capabilities,
    cmd_env = {
      RUSTC_BOOTSTRAP = "1",
    },
    settings = {
      ["rust-analyzer"] = {
        check = {
          enable = true,
          command = "check",
        },
        checkOnSave = true,
        rustcSource = "discover",
        cargo = {
          extraEnv = { RUSTC_BOOTSTRAP = "1" },
          allFeatures = true,
          buildScripts = { enable = true },
        },
        procMacro = {
          enable = true,
          attributes = { enable = true },
        },
        completion = {
          autoimport = { enable = true },
        },
      },
    },
  },
}

vim.g.rustaceanvim = options
