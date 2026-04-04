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
        -- Use separate target dir to avoid lock contention with manual cargo commands
        targetDir = true,
      },

      rustc = {
        source = "discover",
      },

      -- Faster: only check current package, not entire workspace
      check = {
        command = "check",
        workspace = false,
      },

      procMacro = {
        enable = true,
      },

      diagnostics = {
        enable = true,
      },

      -- Reduce inlay hints for better performance
      inlayHints = {
        bindingModeHints = { enable = false },
        closingBraceHints = { enable = true, minLines = 25 },
        closureReturnTypeHints = { enable = "never" },
        lifetimeElisionHints = { enable = "skip_trivial" },
        typeHints = { enable = true },
        chainingHints = { enable = false },
        parameterHints = { enable = false },
      },

      -- Limit completion work
      completion = {
        limit = 100,
        autoimport = { enable = true },
        termSearch = { enable = false },
      },

      -- Reduce highlighting work
      highlightRelated = {
        references = { enable = false },
      },
    },
  },
}
