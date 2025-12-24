return {
  {
    "mrcjkb/rustaceanvim",
    version = "^6",
    ft = { "rust" },
    dependencies = {
      "neovim/nvim-lspconfig",
    },
    init = function()
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
