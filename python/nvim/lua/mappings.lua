require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

-- Trouble
map(
  "n",
  "<leader>xx",
  ":Trouble diagnostics toggle<CR>",
  { noremap = true, silent = true, desc = "Diagnostics (Trouble)" }
)
map(
  "n",
  "<leader>xX",
  ":Trouble diagnostics toggle filter.buf=0<CR>",
  { noremap = true, silent = true, desc = "Buffer Diagnostics (Trouble)" }
)
map(
  "n",
  "<leader>cs",
  ":Trouble symbols toggle focus=false<CR>",
  { noremap = true, silent = true, desc = "Symbols (Trouble)" }
)
map(
  "n",
  "<leader>cl",
  ":Trouble lsp toggle focus=false win.position=right<CR>",
  { noremap = true, silent = true, desc = "LSP Definitions / references / ... (Trouble)" }
)
map(
  "n",
  "<leader>xL",
  ":Trouble loclist toggle<CR>",
  { noremap = true, silent = true, desc = "Location List (Trouble)" }
)
map(
  "n",
  "<leader>xQ",
  ":Trouble qflist toggle<CR>",
  { noremap = true, silent = true, desc = "Quickfix List (Trouble)" }
)

-- Crates
map("n", "<leader>rcu", function()
  require("crates").upgrade_all_crates()
end, { desc = "Update crates" })

-- go dap
map("n", "<leader>db", ":DapToggleBreakpoint<CR>", { noremap = true, silent = true, desc = "Add breakpoint at line" })
map("n", "<leader>dus", function()
  local widgets = require "dap.ui.widgets"
  local sidebar = widgets.sidebar(widgets.scopes)
  sidebar.open()
end, { noremap = true, silent = true, desc = "Open debugging sidebar" })
map("n", "<leader>dgt", function()
  require("dap-go").debug_test()
end, { noremap = true, silent = true, desc = "Debug go test" })

map("n", "<leader>dgl", function()
  require("dap-go").debug_last()
end, { noremap = true, silent = true, desc = "Debug last go test" })

map("n", "<leader>gsj", ":GoTagAdd json<CR>", { noremap = true, silent = true, desc = "Add json struct tags" })

map("n", "<leader>gsy", ":GoTagAdd yaml<CR>", { noremap = true, silent = true, desc = "Add yaml struct tags" })

-- go
-- all the go remaps start with gs
map("n", "<leader>gse", ":GoIfErr <CR> ", { noremap = true, silent = true, desc = "If err return nil" })
map("n", "<leader>gst", ":GoMod tidy<CR> ", { noremap = true, silent = true, desc = "Go Mod Tidy" })

-- rust
map("n", "<leader>rs", ":RustAnalyzer restart<CR> ", { noremap = true, silent = true, desc = "Restart Rust analyzer" })
map("n", "<leader>rt", ":RustLsp testables<CR> ", { noremap = true, silent = true, desc = "Rust testables" })

-- Refactoring
map("x", "<leader>re", ":Refactor extract ", { noremap = true, silent = true, desc = "Refactor extract" })
map(
  "x",
  "<leader>rf",
  ":Refactor extract_to_file ",
  { noremap = true, silent = true, desc = "Refactor extract to file" }
)

map("x", "<leader>rv", ":Refactor extract_var ", { noremap = true, silent = true, desc = "Refactor extract var" })

map({ "n", "x" }, "<leader>ri", ":Refactor inline_var", { noremap = true, silent = true, desc = "Refactor inline var" })

map("n", "<leader>rI", ":Refactor inline_func", { noremap = true, silent = true, desc = "Refactor inline func" })

map("n", "<leader>rb", ":Refactor extract_block", { noremap = true, silent = true, desc = "Refactor extract block" })
map(
  "n",
  "<leader>rbf",
  ":Refactor extract_block_to_file",
  { noremap = true, silent = true, desc = "Refactor extract block to file" }
)

map("n", "<leader>ca", ":lua vim.lsp.buf.code_action() <CR>", { noremap = true, silent = true, desc = "Code actions" })

map({ "n", "x" }, "<C-j>", "<Cmd>MultipleCursorsAddDown<CR>", { desc = "Add cursor and move down" })
map({ "n", "x" }, "<C-k>", "<Cmd>MultipleCursorsAddUp<CR>", { desc = "Add cursor and move up" })

map({ "n", "i", "x" }, "<C-Up>", "<Cmd>MultipleCursorsAddUp<CR>", { desc = "Add cursor and move up" })
map({ "n", "i", "x" }, "<C-Down>", "<Cmd>MultipleCursorsAddDown<CR>", { desc = "Add cursor and move down" })

map({ "n", "i" }, "<C-LeftMouse>", "<Cmd>MultipleCursorsMouseAddDelete<CR>", { desc = "Add or remove cursor" })

map("x", "<Leader>m", "<Cmd>MultipleCursorsAddVisualArea<CR>", { desc = "Add cursors to the lines of the visual area" })

map({ "n", "x" }, "<Leader>a", "<Cmd>MultipleCursorsAddMatches<CR>", { desc = "Add cursors to cword" })
map(
  { "n", "x" },
  "<Leader>A",
  "<Cmd>MultipleCursorsAddMatchesV<CR>",
  { desc = "Add cursors to cword in previous area" }
)

map(
  { "n", "x" },
  "<Leader>d",
  "<Cmd>MultipleCursorsAddJumpNextMatch<CR>",
  { desc = "Add cursor and jump to next cword" }
)
map({ "n", "x" }, "<Leader>D", "<Cmd>MultipleCursorsJumpNextMatch<CR>", { desc = "Jump to next cword" })

map({ "n", "x" }, "<Leader>l", "<Cmd>MultipleCursorsLock<CR>", { desc = "Lock virtual cursors" })
