require "configs.languages.typescript.lsp"
require "configs.languages.python.lsp"
require "configs.languages.go.lsp"
require "configs.languages.rust.lsp"
require "configs.languages.kotlin.lsp"

vim.diagnostic.config { virtual_text = false }

-- Check if project is a Dioxus project
local function is_dioxus_project()
  local root = vim.fs.root(0, { "dioxus.toml" })
  return root ~= nil
end

-- Configure tailwindcss for Dioxus projects
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

local enable_servers = {
  "html",
  "cssls",
  "ts_ls",
  "eslint",
  "gopls",
  "pyright",
  "rust_analyzer",
  "kotlin_language_server",
}

-- Only enable tailwindcss in Dioxus projects
if is_dioxus_project() then
  table.insert(enable_servers, "tailwindcss")
end

vim.lsp.enable(enable_servers)
