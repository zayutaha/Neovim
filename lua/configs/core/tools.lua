return {
  {
    "kiyoon/python-import.nvim",
    build = "uv tool install . --force --reinstall",
    ft = "python",
    opts = require "configs.languages.python.opts",
  },
  {
    "ruifm/gitlinker.nvim",
    event = "BufReadPost",
    cond = function()
      return vim.fn.isdirectory(vim.fn.getcwd() .. "/.git") == 1
    end,
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {},
  },
  {
    "esmuellert/vscode-diff.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    cmd = "CodeDiff",
  },
}
