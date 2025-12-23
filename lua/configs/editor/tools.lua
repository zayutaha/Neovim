return {
  {
    "ruifm/gitlinker.nvim",
    event = "BufReadPost",
    cond = function()
      return vim.fn.isdirectory(vim.fn.getcwd() .. "/.git") == 1
    end,
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {},
  },
}
