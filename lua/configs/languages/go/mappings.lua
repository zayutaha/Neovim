local map = vim.keymap.set

-- DAP
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

-- Tags
map("n", "<leader>gsj", ":GoTagAdd json<CR>", { noremap = true, silent = true, desc = "Add json struct tags" })
map("n", "<leader>gsy", ":GoTagAdd yaml<CR>", { noremap = true, silent = true, desc = "Add yaml struct tags" })

-- Tools
map("n", "<leader>gse", ":GoIfErr <CR> ", { noremap = true, silent = true, desc = "If err return nil" })
map("n", "<leader>gst", ":GoMod tidy<CR> ", { noremap = true, silent = true, desc = "Go Mod Tidy" })
