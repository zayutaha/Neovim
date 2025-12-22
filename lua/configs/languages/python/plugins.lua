return {
  {
    "kiyoon/python-import.nvim",
    build = "uv tool install . --force --reinstall",
    ft = "python",
    opts = require "configs.languages.python.import_opts",
  },
  {
    "nvimtools/none-ls.nvim",
    ft = { "python" },
    dependencies = {
      "nvimtools/none-ls-extras.nvim",
    },
    config = function()
      require "configs.languages.python.none_ls_opts"
    end,
  },
}
