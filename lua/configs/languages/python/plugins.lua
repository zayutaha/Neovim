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
  { "onsails/lspkind.nvim", lazy = true },
  {
    "UN-9BOT/nvim-lspimport",
    branch = "nvim11",
    dependencies = { "onsails/lspkind.nvim" },
    lazy = false,
    config = function()
      vim.keymap.set("n", "<leader>a", function()
        local lspkind = require "lspkind"
        local orig_ui_select = vim.ui.select
        vim.ui.select = function(items, opts, on_choice)
          if opts and opts.format_item then
            local orig_format = opts.format_item
            opts.format_item = function(item)
              local description = item.user_data.nvim.lsp.completion_item.labelDetails.description
              local icon = require("lspkind").symbol_map["Method"] or item.kind
              return item.abbr .. " " .. icon .. " " .. description
            end
          end
          orig_ui_select(items, opts, on_choice)
          vim.ui.select = orig_ui_select
        end
        require("lspimport").import()
      end, { noremap = true })
    end,
  },
}
