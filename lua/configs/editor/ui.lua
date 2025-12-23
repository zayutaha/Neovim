return {
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    opts = function()
      local cmp = require "cmp"
      local M = require "nvchad.configs.cmp"
      M.completion.completeopt = "menu,menuone,noselect"
      M.mapping["<CR>"] = cmp.mapping.confirm {
        behavior = cmp.ConfirmBehavior.Insert,
        select = false,
      }
      table.insert(M.sources, { name = "crates" })
      return M
    end,
  },

  {
    "rachartier/tiny-inline-diagnostic.nvim",
    ft = { "rust", "typescript", "javascript" },
    lazy = false,
    config = function()
      require("tiny-inline-diagnostic").setup()
    end,
  },

  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      -- Add any snacks options here if needed, e.g.,
      -- bigfile = { enabled = true },
      -- dashboard = { enabled = true },
      -- notifier = { enabled = true },
      -- quickfile = { enabled = true },
      -- statuscolumn = { enabled = true },
      -- words = { enabled = true },
    },
    init = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        callback = function()
          _G.dd = function(...)
            Snacks.debug.inspect(...)
          end
          _G.bt = function()
            Snacks.debug.backtrace()
          end
          vim.print = _G.dd
        end,
      })
    end,
  },
}
