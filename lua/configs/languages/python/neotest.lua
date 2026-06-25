local function get_python_path()
  local uv_venv = vim.fn.findfile(".venv", ".;")
  if uv_venv ~= "" then
    return vim.fn.fnamemodify(uv_venv, ":h") .. "/.venv/bin/python"
  end

  local venv = vim.env.VIRTUAL_ENV
  if venv then
    return venv .. "/bin/python"
  end

  local pyproject = vim.fn.findfile("pyproject.toml", ".;")
  if pyproject ~= "" then
    local pyproject_dir = vim.fn.fnamemodify(pyproject, ":h")
    return pyproject_dir .. "/.venv/bin/python"
  end

  return "python3"
end

require("neotest").setup {
  adapters = {
    require("neotest-python") {
      python = get_python_path,
      runner = "pytest",
    },
  },
  strategies = {
    integrated = {
      auto_close = false,
      kind = "float",
    },
  },
}

local map = vim.keymap.set

map("n", "<leader>ta", function()
  require("neotest").run.run(vim.fn.getcwd())
end, { desc = "Run All Tests" })

map("n", "<leader>tf", function()
  require("neotest").run.run(vim.fn.expand "%")
end, { desc = "Run File Tests" })

map("n", "<leader>tn", function()
  require("neotest").run.run()
end, { desc = "Run Nearest Test" })

map("n", "<leader>tl", function()
  require("neotest").run.run_last()
end, { desc = "Run Last Test" })

map("n", "<leader>ts", function()
  require("neotest").summary.toggle()
end, { desc = "Toggle Summary" })

map("n", "<leader>to", function()
  require("neotest").output.open()
end, { desc = "Open Output" })
