local null_ls = require "null-ls"

null_ls.setup {
  sources = {
    null_ls.builtins.diagnostics.pylint.with {
      extra_args = { "--disable=C0114,C0115,C0116" },
    },
    null_ls.builtins.code_actions.refactoring,
    null_ls.builtins.diagnostics.mypy.with {
      extra_args = function()
        local virtual = os.getenv "VIRTUAL_ENV" or os.getenv "CONDA_PREFIX" or "/usr"
        return { "--python-executable", virtual .. "/bin/python3" }
      end,
    },
  },
}
