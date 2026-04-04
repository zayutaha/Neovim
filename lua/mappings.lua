require "nvchad.mappings"

-- Load Modules
require "configs.languages.rust.mappings"
require "configs.languages.go.mappings"
require "configs.languages.python.mappings"
require "configs.editor.mappings"

local map = vim.keymap.set

-- Paste from yank register (previous yank, ignores deletes)
map({ "n", "x" }, "<leader>p", '"0p', { desc = "Paste previous yank" })
map({ "n", "x" }, "<leader>P", '"0P', { desc = "Paste previous yank (before)" })

-- Global Actions
map("n", "<leader>ca", ":lua vim.lsp.buf.code_action() <CR>", { noremap = true, silent = true, desc = "Code actions" })