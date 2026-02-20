vim.lsp.config["rust-analyzer"] = {
  cmd = { "rust-analyzer" },
  filetypes = { "rust" },
  root_markers = { "Cargo.toml", "rust-project.json", ".git" },

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
