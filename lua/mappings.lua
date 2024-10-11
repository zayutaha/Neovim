require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

-- Trouble
map("n", "<leader>xx", ":Trouble diagnostics toggle<CR>", { noremap = true, silent = true, desc = "Diagnostics (Trouble)" })
map("n", "<leader>xX", ":Trouble diagnostics toggle filter.buf=0<CR>", { noremap = true, silent = true, desc = "Buffer Diagnostics (Trouble)" })
map("n", "<leader>cs", ":Trouble symbols toggle focus=false<CR>", { noremap = true, silent = true, desc = "Symbols (Trouble)" })
map("n", "<leader>cl", ":Trouble lsp toggle focus=false win.position=right<CR>", { noremap = true, silent = true, desc = "LSP Definitions / references / ... (Trouble)" })
map("n", "<leader>xL", ":Trouble loclist toggle<CR>", { noremap = true, silent = true, desc = "Location List (Trouble)" })
map("n", "<leader>xQ", ":Trouble qflist toggle<CR>", { noremap = true, silent = true, desc = "Quickfix List (Trouble)" })

-- Crates 
map("n", "<leader>rcu", function()
  require("crates").upgrade_all_crates()
end, { desc = "Update crates" })

