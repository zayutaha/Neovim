local map = vim.keymap.set

map("n", "<leader>rs", "<cmd>LspRestart rust-analyzer<cr>", { desc = "Restart Rust analyzer" })

map("n", "<leader>gx", function()
  local client = vim.lsp.get_clients({ bufnr = 0, name = "rust-analyzer" })[1]
  if not client then
    vim.notify("rust-analyzer not attached", vim.log.levels.WARN)
    return
  end
  client:request(
    "experimental/externalDocs",
    vim.lsp.util.make_position_params(0, client.offset_encoding),
    function(_, url)
      if not url then
        vim.notify("No documentation found", vim.log.levels.WARN)
        return
      end
      vim.ui.open(type(url) == "table" and (url.web or url.local_) or url)
    end
  )
end, { desc = "Open docs in browser" })

map("n", "<leader>rcu", function()
  require("crates").upgrade_all_crates()
end, { desc = "Update crates" })

map("n", "<leader>k", function()
  require("krust").render()
end, { desc = "Krust Render" })
