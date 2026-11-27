-- load defaults i.e lua_lsp (also applies NvChad's capabilities, on_init and
-- LspAttach keymaps to every server through vim.lsp.config("*"))
require("nvchad.configs.lspconfig").defaults()

vim.diagnostic.config({ virtual_text = false })

-- Custom go setup
vim.lsp.config("gopls", {
  cmd = { "gopls" },
  filetypes = { "go", "gomod", "gowork", "gotmpl" },
  root_markers = { "go.work", "go.mod", ".git" },
  settings = {
    gopls = {
      completeUnimported = true,
      usePlaceholders = true,
      staticcheck = true,
      codelenses = {
        generate = true,
        gc_details = true,
        test = true,
        tidy = true,
      },
      analyses = {
        unusedparams = true,
        nilness = true,
        shadow = true,
        unusedwrite = true,
      },
      gofumpt = true,
    },
  },
})

-- Python setup (basedpyright + uv venv auto-detection)
vim.lsp.config("basedpyright", {
  before_init = function(_, config)
    local root = config.root_dir
    local venv_python = root and root .. "/.venv/bin/python"
    if venv_python and vim.fn.executable(venv_python) == 1 then
      -- Mutate in place: the client already holds a reference to this table.
      local settings = config.settings
      settings.python = vim.tbl_extend("force", settings.python or {}, { pythonPath = venv_python })
      settings.venvPath = root
      settings.venv = ".venv"
    end
  end,
  settings = {
    basedpyright = {
      analysis = {
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        autoImportCompletions = true,
        diagnosticMode = "workspace",
        typeCheckingMode = "standard",
        packageIndexDepths = {
          {
            name = "",
            depth = 2,
            includeAllSymbols = true,
          },
          {
            name = "transformers",
            depth = 4,
            includeAllSymbols = true,
          },
        },
      },
    },
  },
})

vim.lsp.enable({ "html", "cssls", "ts_ls", "eslint", "gopls", "basedpyright", "ruff" })
