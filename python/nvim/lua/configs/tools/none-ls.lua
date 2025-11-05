local null_ls = require "null-ls"

local function get_python_path()
  -- Check for uv venv
  local uv_venv = vim.fn.findfile(".venv", ".;")
  if uv_venv ~= "" then
    return vim.fn.fnamemodify(uv_venv, ":h") .. "/.venv/bin/python"
  end

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

null_ls.setup {
  sources = {
    null_ls.builtins.code_actions.refactoring,
    null_ls.builtins.diagnostics.mypy.with {
      extra_args = { "--python-executable", get_python_path() },
    },
  },
  on_attach = function(client, bufnr)
    if client.name == "null-ls" then
      vim.api.nvim_create_autocmd("BufWritePre", {
        buffer = bufnr,
        callback = function()
          vim.lsp.buf.format { bufnr = bufnr }
        end,
      })
    end
  end,
}
