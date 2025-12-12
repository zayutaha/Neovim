local on_attach = require("nvchad.configs.lspconfig").on_attach
local capabilities = require("nvchad.configs.lspconfig").capabilities

local rustc_sysroot = vim.fn.system("rustc --print sysroot"):gsub("\n", "")

local options = {
  server = {
    on_attach = on_attach,
    capabilities = capabilities,
    settings = {
      ["rust-analyzer"] = {
        checkOnSave = true,
        check = { enable = true, command = "check" },
        rustcSource = rustc_sysroot .. "/lib/rustlib/src/rust",
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
