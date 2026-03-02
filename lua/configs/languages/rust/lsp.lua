vim.lsp.config["rust_analyzer"] = {
  -- Use .git root so multi-crate repos (e.g. rust-clippy) get a single instance
  root_dir = function(bufnr, on_dir)
    local fname = vim.api.nvim_buf_get_name(bufnr)
    local git_root = vim.fs.root(fname, { ".git" })
    local cargo_root = vim.fs.root(fname, { "Cargo.toml" })

    if git_root and cargo_root then
      -- Prefer git root when it contains a Cargo.toml (monorepo)
      local git_has_cargo = vim.uv.fs_stat(git_root .. "/Cargo.toml")
      on_dir(git_has_cargo and git_root or cargo_root)
    else
      on_dir(git_root or cargo_root)
    end
  end,

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
