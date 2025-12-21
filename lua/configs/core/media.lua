return {
  {
    "3rd/image.nvim",
    lazy = false,
    config = function()
      require("image").setup {
        backend = "kitty",
      }
    end,
  },
  {
    "3rd/diagram.nvim",
    dependencies = {
      "3rd/image.nvim",
    },
    ft = { "markdown" },
    config = function()
      require("diagram").setup {
        integrations = {
          require "diagram.integrations.markdown",
          require "diagram.integrations.neorg",
        },
        renderer_options = {
          mermaid = {
            theme = "forest",
          },
          plantuml = {
            charset = "utf-8",
          },
          d2 = {
            theme_id = 1,
          },
          gnuplot = {
            theme = "dark",
            size = "800,600",
          },
        },
      }
    end,
    opts = { -- you can just pass {}, defaults below
      command_paths = {
        mermaid = "/opt/homebrew/bin/mmdc", -- Adjust this path based on your installation
      },
      events = {
        render_buffer = { "InsertLeave", "BufWinEnter", "TextChanged" },
        clear_buffer = { "BufLeave" },
      },
      renderer_options = {
        mermaid = {
          background = "transparent",
          theme = "forest",
          width = 800,
          height = 400,
          scale = 1,
        },
      },
    },
  },
}
