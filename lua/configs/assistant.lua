local M = {}

local providers = { Claude = "configs.claude_window", Codex = "configs.codex_window" }
local file_explorers = { "NvimTree", "neo-tree", "oil", "minifiles", "netrw", "snacks_picker_list" }

local function selected()
  return vim.g.nvim_assistant or "Claude"
end

local function provider(name)
  return require(providers[name or selected()])
end

function M.pick()
  vim.ui.select({ "Claude", "Codex" }, { prompt = "Select coding assistant (" .. selected() .. ")" }, function(choice)
    if choice then
      if choice ~= selected() then
        provider().hide()
        vim.g.nvim_assistant = choice
      end
      provider().open()
    end
  end)
end

function M.toggle(layout)
  provider().toggle(layout)
end

-- Ctrl-S: toggle the assistant docked in the sidebar, starting it if needed
-- (or move it there from the popup).
function M.dock()
  require("lazy").load({ plugins = { "claudecode.nvim" } })
  if selected() == "Claude" and provider().in_code_tour() then
    vim.notify("The sidebar isn't available during a walkthrough. Use Ctrl-F to open Claude here.")
    return
  end
  provider().toggle("sidebar")
end

-- <leader>ac: in a walkthrough, end it and keep editing its file; elsewhere
-- toggle the assistant sidebar.
function M.continue_or_toggle()
  if selected() == "Claude" or package.loaded[providers.Claude] then
    local claude = require(providers.Claude)
    if claude.in_code_tour() and claude.continue_editing() then
      return
    end
  end
  M.toggle("sidebar")
end

function M.focus()
  provider().open()
end

function M.resume(last)
  if selected() == "Claude" then
    local claude = provider()
    if claude.in_code_tour() then
      local terminal = require("claudecode.terminal")
      local active = terminal.get_active_terminal_bufnr()
      claude.open("popup", last and "--continue" or "--resume")
      if active and not last then
        terminal.send_to_terminal("/resume", { submit = false })
      end
    else
      vim.cmd(last and "ClaudeCode --continue" or "ClaudeCode --resume")
    end
  else
    provider().open(nil, last and { "resume", "--last" } or { "resume" })
  end
end

function M.model()
  if selected() == "Claude" then
    local claude = provider()
    if claude.in_code_tour() then
      claude.open("popup")
      require("claudecode.terminal").send_to_terminal("/model", { submit = false })
    else
      vim.cmd.ClaudeCodeSelectModel()
    end
  else
    provider().draft("/model", true)
  end
end

local function draft_files(paths)
  provider().draft(table.concat(paths, "\n") .. "\n")
end

function M.add_buffer()
  if selected() == "Claude" then
    vim.cmd("ClaudeCodeAdd %")
    if provider().in_code_tour() then
      provider().open("popup")
    end
  else
    local path = vim.api.nvim_buf_get_name(0)
    if path ~= "" then
      draft_files({ path })
    end
  end
end

function M.send_tree()
  if selected() == "Claude" then
    provider().send("ClaudeCodeTreeAdd")
  else
    local paths, err = require("claudecode.integrations").get_selected_files_from_tree()
    if paths and #paths > 0 then
      draft_files(paths)
    elseif err then
      vim.notify(err, vim.log.levels.WARN)
    end
  end
end

-- In a :CodeDiff tab the diff needs the room, so selections go to the
-- popup (Ctrl-F) instead of the sidebar.
local function in_codediff()
  local lifecycle = package.loaded["codediff.ui.lifecycle"]
  return lifecycle ~= nil and lifecycle.get_session(vim.api.nvim_get_current_tabpage()) ~= nil
end

function M.send_selection()
  local layout = in_codediff() and "popup" or nil
  if selected() == "Claude" then
    provider().send("ClaudeCodeSend", layout)
    return
  end
  local path = vim.api.nvim_buf_get_name(0)
  local start_pos = vim.fn.getpos("v")
  local end_pos = vim.fn.getpos(".")
  local lines = vim.fn.getregion(start_pos, end_pos, {
    type = vim.fn.mode(),
    exclusive = vim.o.selection == "exclusive",
  })
  local text = table.concat(lines, "\n")
  local fence = "```"
  for ticks in text:gmatch("`+") do
    if #ticks >= #fence then
      fence = string.rep("`", #ticks + 1)
    end
  end
  local label = (path == "" and "Selected code" or path)
  local first, last = math.min(start_pos[2], end_pos[2]), math.max(start_pos[2], end_pos[2])
  label = string.format("%s (lines %d–%d)", label, first, last)
  vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "in", false)
  vim.schedule(function()
    provider("Codex").draft(table.concat({ label, fence, text, fence, "" }, "\n"), false, layout)
  end)
end

-- Snacks closes its terminal windows on ExitPre. When the assistant terminal
-- is the current window, that close switches windows mid-quit and Neovim
-- aborts the :qa! (only Claude/Codex closes). Drop that hook for assistant
-- terminals; their jobs are still stopped on exit (VimLeavePre handlers).
local function keep_quit_all_working(buffer)
  vim.schedule(function()
    for _, term in ipairs(Snacks.terminal.list()) do
      if term.buf == buffer then
        term.events = vim.tbl_filter(function(event)
          return event.event ~= "ExitPre"
        end, term.events or {})
        if term.augroup then
          for _, autocmd in ipairs(vim.api.nvim_get_autocmds({ group = term.augroup, event = "ExitPre" })) do
            vim.api.nvim_del_autocmd(autocmd.id)
          end
        end
      end
    end
  end)
end

function M.map_terminal_keys(buffer)
  keep_quit_all_working(buffer)
  local opts = { buffer = buffer, silent = true }
  for _, keys in ipairs({ "<Esc>:", "<M-:>" }) do
    vim.keymap.set("t", keys, "<C-\\><C-n>:", {
      buffer = buffer,
      desc = "Open Neovim command line from assistant terminal",
    })
  end
  vim.keymap.set("t", "<C-f>", "<C-\\><C-n><Cmd>lua require('configs.assistant').toggle('popup')<CR>", opts)
  vim.keymap.set("t", "<C-s>", "<C-\\><C-n><Cmd>lua require('configs.assistant').dock()<CR>", {
    buffer = buffer, silent = true, desc = "Dock assistant in sidebar",
  })
  vim.keymap.set("n", "<C-s>", M.dock, {
    buffer = buffer, silent = true, desc = "Dock assistant in sidebar",
  })
  vim.keymap.set("t", "<leader>ap", "<C-\\><C-n><Cmd>lua require('configs.assistant').pick()<CR>", opts)

  local directions = { h = "Left", j = "Down", k = "Up", l = "Right" }
  for key, direction in pairs(directions) do
    vim.keymap.set("t", "<C-" .. key .. ">", "<C-\\><C-n><Cmd>TmuxNavigate" .. direction .. "<CR>", opts)
  end
end

function M.setup()
  local group = vim.api.nvim_create_augroup("CodingAssistant", { clear = true })
  vim.api.nvim_create_autocmd("VimResized", {
    group = group,
    callback = function()
      if package.loaded[providers.Codex] then
        provider("Codex").resize()
      end
    end,
  })
end

function M.keys()
  return {
    { "<C-f>", function() M.toggle("popup") end, desc = "Toggle assistant popup" },
    { "<leader>a", nil, desc = "Coding assistant" },
    { "<leader>ap", M.pick, desc = "Pick Claude or Codex" },
    { "<leader>ac", function() M.continue_or_toggle() end, desc = "Walkthrough: keep editing file · else toggle sidebar" },
    { "<leader>af", M.focus, desc = "Focus assistant" },
    { "<leader>an", function() provider("Claude").step_code_tour(1) end, desc = "Next code walkthrough stop" },
    { "<leader>aN", function() provider("Claude").step_code_tour(-1) end, desc = "Previous code walkthrough stop" },
    { "<leader>ae", function() provider("Claude").toggle_code_explanation() end, desc = "Toggle walkthrough explanation and live prompt" },
    { "<leader>ah", function() provider("Claude").toggle_code_tour() end, desc = "Hide or show the code walkthrough" },
    { "<leader>aR", function() provider("Claude").reanchor_code_tour() end, mode = "x", desc = "Update saved walkthrough range" },
    { "<leader>ar", function() M.resume(false) end, desc = "Resume assistant session" },
    { "<leader>aC", function() M.resume(true) end, desc = "Continue assistant session" },
    { "<leader>am", M.model, desc = "Select assistant model" },
    { "<leader>ab", M.add_buffer, desc = "Add current buffer to assistant" },
    { "<leader>as", M.send_selection, mode = "v", desc = "Send selection to assistant" },
    { "<leader>as", M.send_tree, ft = file_explorers, desc = "Add file to assistant" },
    { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept edit" },
    { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Reject edit" },
  }
end

return M
