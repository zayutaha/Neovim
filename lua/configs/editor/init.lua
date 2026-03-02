return {
  { import = "configs.editor.ui" },
  { import = "configs.editor.ai" },

  {
    "nvim-telescope/telescope.nvim",
    opts = {
      defaults = {
        mappings = {
          i = {
            ["<CR>"] = function(prompt_bufnr)
              local actions = require "telescope.actions"
              local state = require "telescope.actions.state"
              local picker = state.get_current_picker(prompt_bufnr)
              local selections = picker:get_multi_selection()
              if #selections > 1 then
                actions.close(prompt_bufnr)
                for _, entry in ipairs(selections) do
                  if entry.path or entry.filename then
                    vim.cmd("edit " .. (entry.path or entry.filename))
                  end
                end
              else
                actions.select_default(prompt_bufnr)
              end
            end,
          },
        },
      },
    },
  },

  {
    "stevearc/conform.nvim",
    lazy = false,
    event = "BufWritePre",
    opts = require "configs.conform",
  },

  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "pyright",
        "mypy",
        "typescript-language-server",
        "tailwind-language-server",
        "eslint-lsp",
        "gopls",
        "prettier",
        "prettierd",
        "stylua",
        "rust-analyzer",
      },
    },
  },

  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig" },
    opts = {
      automatic_enable = false,
    },
  },

  -- {
  --   "m4xshen/hardtime.nvim",
  --   lazy = false,
  --   dependencies = { "MunifTanjim/nui.nvim", "rcarriga/nvim-notify" },
  --   opts = {},
  -- },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "vim",
        "lua",
        "vimdoc",
        "html",
        "rust",
        "typescript",
        "go",
      },
    },
  },
}
