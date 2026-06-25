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
  root_markers = { "pyproject.toml", "setup.py", ".git" },
  settings = {
    python = {
      pythonPath = get_python_path(),
      analysis = {
        autoImportCompletions = true,
        typeCheckingMode = "strict",
        diagnosticMode = "workspace",
        useLibraryCodeForTypes = true,
      },
    },
  },
}
