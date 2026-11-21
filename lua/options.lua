require "nvchad.options"

-- add yours here!

local o = vim.o
o.relativenumber = true

-- Markdown: comfortable editing defaults (wrap + spell)
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.spell = true
  end,
})


