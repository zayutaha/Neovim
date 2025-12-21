return {
  {
    "mrcjkb/rustaceanvim",
    version = "^4",
    ft = { "rust" },
    dependencies = {
      "neovim/nvim-lspconfig",
    },
    config = function()
      require "configs.languages.rust.opts"
    end,
  },

  {
    "saecki/crates.nvim",
    ft = { "toml" },
    dependencies = {
      "hrsh7th/nvim-cmp",
    },
  },
  {
    "alexpasmantier/krust.nvim",
    ft = "rust",
  },
}

