return {
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
  {
    "luckasRanarison/tailwind-tools.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "neovim/nvim-lspconfig" },
    opts = {
      server = {
        settings = {
          includeLanguages = { rust = "html" },
        },
      },
      extension = {
        patterns = {
          rust = { 'class: ["](.*)["]' },
        },
      },
    },
  },
}
