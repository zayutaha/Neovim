local map = vim.keymap.set

map("n", "<leader>rs", "<cmd>RustAnalyzer restart<cr>", { desc = "Restart Rust analyzer" })
map("n", "<leader>rt", "<cmd>RustLsp testables<cr>", { desc = "Rust testables" })

map("n", "<leader>rcu", function()
  require("crates").upgrade_all_crates()
end, { desc = "Update crates" })

map("n", "<leader>k", function()
  require("krust").render()
end, { desc = "Krust Render" })

map("n", "<leader>gx", "<cmd>RustLsp openDocs<cr>", { desc = "Rust: Open docs in browser" })
