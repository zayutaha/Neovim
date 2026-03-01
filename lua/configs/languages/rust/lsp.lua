vim.lsp.config["rust_analyzer"] = {
  capabilities = {
    experimental = {
      openDocs = true,
    },
  },

  settings = {
    ["rust-analyzer"] = {
      cargo = {
        allFeatures = true,
        buildScripts = {
          enable = true,
        },
      },

      rustc = {
        source = "discover",
      },

      check = {
        command = "check",
      },

      procMacro = {
        enable = true,
      },

      diagnostics = {
        enable = true,
      },

      inlayHints = {
        bindingModeHints = { enable = true },
        closingBraceHints = { enable = true },
        closureReturnTypeHints = { enable = "always" },
        lifetimeElisionHints = { enable = "always", useParameterNames = true },
        typeHints = { enable = true },
      },
    },
  },
}
