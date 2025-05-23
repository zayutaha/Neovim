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

map("n", "<leader>ca", ":lua vim.lsp.buf.code_action() <CR>", { noremap = true, silent = true, desc = "Code actions" })

