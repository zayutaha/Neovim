require "nvchad.mappings"

-- Load Modules
require "configs.languages.rust.mappings"
require "configs.languages.go.mappings"
require "configs.languages.python.mappings"
require "configs.editor.mappings"

local map = vim.keymap.set

-- Global Actions
map("n", "<leader>ca", ":lua vim.lsp.buf.code_action() <CR>", { noremap = true, silent = true, desc = "Code actions" })