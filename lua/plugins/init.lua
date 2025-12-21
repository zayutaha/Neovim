local cmp = require "cmp"

return {
  { import = "configs.languages.rust.plugins" },
  { import = "configs.core.plugins" },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "vim",
        "lua",
        "vimdoc",
        "html",
        "css",
        "rust",
        "typescript",
        "go",
      },
    },
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
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    opts = function()
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
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    init = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        callback = function()
          -- Setup some globals for debugging (lazy-loaded)
          _G.dd = function(...)
            Snacks.debug.inspect(...)
          end
          _G.bt = function()
            Snacks.debug.backtrace()
          end
          vim.print = _G.dd -- Override print to use snacks for `:=` command
        end,
      })
    end,
  },
  {
    "kiyoon/python-import.nvim",
    build = "uv tool install . --force --reinstall",
    opts = {
      -- Example 1:
      -- Default behaviour for `tqdm` is `from tqdm.auto import tqdm`.
      -- If you want to change it to `import tqdm`, you can set `import = {"tqdm"}` and `import_from = {tqdm = vim.NIL}` here.
      -- If you want to change it to `from tqdm import tqdm`, you can set `import_from = {tqdm = "tqdm"}` here.

      -- Example 2:
      -- Default behaviour for `logger` is `import logging`, ``, `logger = logging.getLogger(__name__)`.
      -- If you want to change it to `import my_custom_logger`, ``, `logger = my_custom_logger.get_logger()`,
      -- you can set `statement_after_imports = {logger = {"import my_custom_logger", "", "logger = my_custom_logger.get_logger()"}}` here.
      extend_lookup_table = {
        ---@type string[]
        import = {
          -- "tqdm",
        },

        ---@type table<string, string|vim.NIL>
        import_as = {
          -- These are the default values. Here for demonstration.
          np = "numpy",
          pd = "pandas",
        },

        ---@type table<string, string|vim.NIL>
        import_from = {
          -- tqdm = vim.NIL,
          -- tqdm = "tqdm",
        },

        ---@type table<string, string[]|vim.NIL>
        statement_after_imports = {
          -- logger = { "import my_custom_logger", "", "logger = my_custom_logger.get_logger()" },
        },
      },

      ---Return nil to indicate no match is found and continue with the default lookup
      ---Return a table to stop the lookup and use the returned table as the result
      ---Return an empty table to stop the lookup. This is useful when you want to add to wherever you need to.
      ---@type fun(winnr: integer, word: string, ts_node: TSNode?): string[]?
      custom_function = function(winnr, word, ts_node)
        -- if vim.endswith(word, "_DIR") then
        --   return { "from my_module import " .. word }
        -- end
      end,
    },
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
  -- {
  --   "3rd/image.nvim",
  --   lazy = false,
  --   config = function()
  --     require("image").setup {
  --       backend = "kitty",
  --     }
  --   end,
  -- },
  -- {
  --   "3rd/diagram.nvim",
  --   dependencies = {
  --     "3rd/image.nvim",
  --   },
  --   ft = { "markdown" },
  --   config = function()
  --     require("diagram").setup {
  --       integrations = {
  --         require "diagram.integrations.markdown",
  --         require "diagram.integrations.neorg",
  --       },
  --       renderer_options = {
  --         mermaid = {
  --           theme = "forest",
  --         },
  --         plantuml = {
  --           charset = "utf-8",
  --         },
  --         d2 = {
  --           theme_id = 1,
  --         },
  --         gnuplot = {
  --           theme = "dark",
  --           size = "800,600",
  --         },
  --       },
  --     }
  --   end,
  --   opts = { -- you can just pass {}, defaults below
  --     command_paths = {
  --       mermaid = "/opt/homebrew/bin/mmdc", -- Adjust this path based on your installation
  --     },
  --     events = {
  --       render_buffer = { "InsertLeave", "BufWinEnter", "TextChanged" },
  --       clear_buffer = { "BufLeave" },
  --     },
  --     renderer_options = {
  --       mermaid = {
  --         background = "transparent",
  --         theme = "forest",
  --         width = 800,
  --         height = 400,
  --         scale = 1,
  --       },
  --     },
  --   },
  -- },
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    build = ":Copilot auth",
    opts = {
      suggestion = { enabled = false },
      panel = { enabled = false },
    },
  },
  {
    "yetone/avante.nvim",
    build = function()
      if vim.fn.has "win32" == 1 then
        return "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
      else
        return "make"
      end
    end,
    event = "VeryLazy",
    version = false,
    opts = require "configs.tools.ai",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "echasnovski/mini.pick",
      "nvim-telescope/telescope.nvim",
      "hrsh7th/nvim-cmp",
      "ibhagwan/fzf-lua",
      "stevearc/dressing.nvim",
      "folke/snacks.nvim",
      "nvim-tree/nvim-web-devicons",
      "zbirenbaum/copilot.lua",
      {
        "HakonHarnes/img-clip.nvim",
        event = "VeryLazy",
        opts = {
          default = {
            embed_image_as_base64 = false,
            prompt_for_file_name = false,
            drag_and_drop = {
              insert_mode = true,
            },
            use_absolute_path = true,
          },
        },
      },
      {
        "MeanderingProgrammer/render-markdown.nvim",
        opts = {
          file_types = { "markdown", "Avante" },
        },
        ft = { "markdown", "Avante" },
      },
    },
  },
  {
    "nvim-mini/mini.nvim",
    event = "VeryLazy",
    version = "*",
    config = function()
      require "configs.tools.mini"
    end,
  },
  {
    "esmuellert/vscode-diff.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    cmd = "CodeDiff",
  },
  {
    "m4xshen/hardtime.nvim",
    lazy = false,
    dependencies = { "MunifTanjim/nui.nvim", "rcarriga/nvim-notify" },
    opts = {},
  },
}
