local map = vim.keymap.set

-- Python Import
map({ "i", "n" }, "<M-CR>", function()
  require("python_import.api").add_import_current_word_and_notify()
end, { silent = true, desc = "Add python import" })

map("x", "<M-CR>", function()
  require("python_import.api").add_import_current_selection_and_notify()
end, { silent = true, desc = "Add python import" })

map("n", "<leader>i", function()
  require("python_import.api").add_import_current_word_and_move_cursor()
end, { silent = true, desc = "Add python import and move cursor" })

map("x", "<leader>i", function()
  require("python_import.api").add_import_current_selection_and_move_cursor()
end, { silent = true, desc = "Add python import and move cursor" })

map("n", "<leader>tr", function()
  require("python_import.api").add_rich_traceback()
end, { silent = true, desc = "Add rich traceback" })
