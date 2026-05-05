vim.lsp.config("tailwindcss", {
  init_options = {
    userLanguages = { rust = "html" },
  },
  settings = {
    tailwindCSS = {
      experimental = {
        classRegex = { [[class\s*:\s*"([^"]*)"]] },
      },
      includeLanguages = { rust = "html" },
    },
  },
  filetypes = { "css", "html", "rust" },
})
vim.lsp.enable "tailwindcss"
