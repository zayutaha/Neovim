vim.lsp.config["eslint"] = {
  capabilities = {},
  settings = {
    eslint = {
      -- Path to eslint config file, if you'd like to specify it explicitly
      -- configFile = ".eslintrc.json",

      -- Use flat config (eslint.config.js) if on ESLint v9+
      useFlatConfig = true,

      -- Run ESLint on save rather than on type, if preferred
      run = "onSave",

      -- Auto-fix on save (optional)
      autoFixOnSave = true,

      -- Lint the whole workspace or just open files
      lintTask = {
        enable = false,
      },

      -- Nodepath, if using a global install
      -- nodePath = "",

      -- Package manager hint
      packageManager = "npm",

      -- Working directory behavior
      workingDirectory = {
        mode = "auto",
      },

      -- Quiet mode: report errors only, not warnings (optional)
      quiet = false,

      diagnostics = {
        enable = true,
      },
    },
  },
}
