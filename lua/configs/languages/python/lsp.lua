local lspconfig = require "lspconfig"
local nvlsp = require "nvchad.configs.lspconfig"

local function get_python_path()
  local venv = vim.env.VIRTUAL_ENV
  if venv then
    return venv .. "/bin/python"
  end

  local pyproject = vim.fn.findfile("pyproject.toml", ".;")
  if pyproject ~= "" then
    local pyproject_dir = vim.fn.fnamemodify(pyproject, ":h")
    return pyproject_dir .. "/.venv/bin/python"
  end

  return "python3"
end

vim.lsp.config["pyright"] = {
  cmd = { "pyright-langserver", "--stdio" },
  root_dir = vim.fs.root(0, { "pyproject.toml", "setup.py", ".git" }) or vim.loop.cwd(),
  on_attach = nvlsp.on_attach,
  on_init = nvlsp.on_init,
  capabilities = nvlsp.capabilities,
  settings = {
    python = {
      pythonPath = get_python_path(),
      analysis = {
        autoImportCompletions = true,
        typeCheckingMode = "basic",
        diagnosticMode = "workspace",
        useLibraryCodeForTypes = true,
      },
    },
  },
}
