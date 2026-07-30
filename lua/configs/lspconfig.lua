-- load defaults i.e lua_lsp
require("nvchad.configs.lspconfig").defaults()

vim.diagnostic.config({ virtual_text = false })

local lspconfig = require "lspconfig"

local servers = { "html", "cssls", "ts_ls", "eslint"}
local nvlsp = require "nvchad.configs.lspconfig"
local util = require "lspconfig/util"

-- lsps with default config
for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = nvlsp.on_attach,
    on_init = nvlsp.on_init,
    capabilities = nvlsp.capabilities,
  }
end

-- Custom go setup
lspconfig.gopls.setup {
  on_attach = nvlsp.on_attach,
  capabilities = nvlsp.capabilities,
  cmd = { "gopls" },
  filetypes = { "go", "gomod", "gowork", "gotmpl" },
  root_dir = util.root_pattern("go.work", "go.mod", ".git"),
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
}

-- Python setup (basedpyright + uv venv auto-detection)
lspconfig.basedpyright.setup {
  on_attach = nvlsp.on_attach,
  on_init = nvlsp.on_init,
  capabilities = nvlsp.capabilities,
  on_new_config = function(new_config, new_root_dir)
    local venv_python = new_root_dir .. "/.venv/bin/python"
    if vim.fn.executable(venv_python) == 1 then
      new_config.settings = vim.tbl_deep_extend("force", new_config.settings or {}, {
        python = {
          pythonPath = venv_python,
        },
      })
    end
  end,
  settings = {
    basedpyright = {
      analysis = {
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        autoImportCompletions = true,
        diagnosticMode = "openFilesOnly",
        typeCheckingMode = "standard",
      },
    },
  },
}

-- Ruff setup
lspconfig.ruff.setup {
  on_attach = nvlsp.on_attach,
  on_init = nvlsp.on_init,
  capabilities = nvlsp.capabilities,
}

