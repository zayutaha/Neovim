local map = vim.keymap.set

map("n", "<leader>rs", "<cmd>LspRestart rust-analyzer<cr>", { desc = "Restart Rust analyzer" })

map("n", "<leader>rcu", function()
  require("crates").upgrade_all_crates()
end, { desc = "Update crates" })

map("n", "<leader>k", function()
  require("krust").render()
end, { desc = "Krust Render" })
