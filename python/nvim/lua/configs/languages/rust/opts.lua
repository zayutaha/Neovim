local on_attach = require("nvchad.configs.lspconfig").on_attach
local capabilities = require("nvchad.configs.lspconfig").capabilities

local options = {
  server = {
    on_attach = on_attach,
    capabilities = capabilities,
    settings = {
      ["rust-analyzer"] = {
        checkOnSave = true,
        check = {
          enable = true,
          command = "check",
        },
        expandMacro = {
          command = "cargo",
          args = {
            "+nightly",
            "rustc",
            "--",
            "-Z",
            "unstable-options",
            "--pretty=expanded",
          },
        },
      },
    },
  },
}

return options
