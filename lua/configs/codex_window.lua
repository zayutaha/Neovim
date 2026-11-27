local M = {}
local agent_layout = require("configs.agent_layout")
local terminal
local patch_review_tab
local tab_before_patch_review
local restore_popup_after_approval = false
local cleanup_group = vim.api.nvim_create_augroup("CodexTerminalCleanup", { clear = true })

vim.api.nvim_create_autocmd("VimLeavePre", {
  group = cleanup_group,
  callback = function()
    if terminal and terminal:buf_valid() then
      local job = vim.b[terminal.buf].terminal_job_id
      if job and vim.fn.jobwait({ job }, 0)[1] == -1 then
        pcall(vim.api.nvim_chan_send, job, "\x03")
        if vim.fn.jobwait({ job }, 1000)[1] == -1 then
          vim.fn.jobstop(job)
          vim.fn.jobwait({ job }, 1000)
        end
      end
    end
  end,
})

local function start(args)
  local edit_instructions = table.concat({
    "Use the apply_patch tool for file edits in this Neovim session.",
    "Neovim displays the proposed patch before the user approves it in Codex.",
    "Do not use shell commands, scripts, or redirection to make those edits.",
    "If apply_patch is unavailable or cannot express the edit, explain that and wait.",
  }, " ")
  local hook_script = vim.fn.stdpath("config") .. "/scripts/show_agent_sidebar.py"
  local hook_command = vim.json.encode(
    "python3 " .. vim.fn.shellescape(hook_script) .. " codex"
  )
  local permission_hook = 'hooks.PermissionRequest=[{hooks=[{type="command",command='
    .. hook_command
    .. ',timeout=5,statusMessage="Showing Codex in the sidebar"}]}]'
  local restore_hook = '=[{hooks=[{type="command",command='
    .. vim.json.encode(
      "python3 " .. vim.fn.shellescape(hook_script) .. " codex restore"
    )
    .. ',timeout=5}]}]'
  local argv = {
    "codex",
    "--no-daemon",
    "--sandbox",
    "read-only",
    "--ask-for-approval",
    "on-request",
    "-c",
    "developer_instructions=" .. vim.json.encode(edit_instructions),
    "-c",
    permission_hook,
    "-c",
    "hooks.PostToolUse" .. restore_hook,
    "-c",
    "hooks.Stop" .. restore_hook,
    "-c",
    "hooks.Interrupt" .. restore_hook,
  }
  vim.list_extend(argv, args or {})

  return Snacks.terminal.open(argv, {
    cwd = vim.fn.getcwd(),
    env = {
      NVIM_SERVER = vim.v.servername,
      NVIM_CLIENT = vim.v.progpath,
    },
    win = {
      position = "right",
      width = agent_layout.sidebar_width,
      resize = false,
      keys = { term_normal = false },
      wo = { winbar = "" },
      bo = { filetype = "codex_terminal" },
      on_buf = function(term)
        require("configs.assistant").map_terminal_keys(term.buf)
      end,
    },
  })
end

function M.show_sidebar(focus)
  if not terminal or not terminal:buf_valid() then
    return
  end
  if not terminal:win_valid() then
    terminal:show()
  end
  if not terminal:win_valid() then
    return
  end

  local window = terminal.win
  if vim.api.nvim_win_get_config(window).hide then
    vim.api.nvim_win_set_config(window, { hide = false })
  end
  agent_layout.show(window, "sidebar")

  if focus then
    vim.api.nvim_set_current_win(window)
    vim.cmd.startinsert()
  end
end

local function close_patch_review()
  local tab = patch_review_tab
  local previous_tab = tab_before_patch_review
  patch_review_tab, tab_before_patch_review = nil, nil
  if tab and vim.api.nvim_tabpage_is_valid(tab) then
    local return_to_previous = vim.api.nvim_get_current_tabpage() == tab
    vim.cmd("tabclose " .. vim.api.nvim_tabpage_get_number(tab))
    if return_to_previous and vim.api.nvim_tabpage_is_valid(previous_tab) then
      vim.api.nvim_set_current_tabpage(previous_tab)
    end
  end
end

local function show_patch_review(path)
  local lines = vim.fn.readfile(path)
  close_patch_review()
  tab_before_patch_review = vim.api.nvim_get_current_tabpage()
  vim.cmd("noautocmd tabnew")
  patch_review_tab = vim.api.nvim_get_current_tabpage()

  local review_window = vim.api.nvim_get_current_win()
  local buffer = vim.api.nvim_get_current_buf()
  vim.bo[buffer].buftype = "nofile"
  vim.bo[buffer].bufhidden = "wipe"
  vim.bo[buffer].buflisted = false
  vim.api.nvim_buf_set_name(buffer, "Codex patch review")
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
  vim.bo[buffer].filetype = "diff"
  vim.bo[buffer].modifiable = false
  vim.wo[review_window].winbar = " Codex patch • approve in the terminal"

  vim.api.nvim_open_win(terminal.buf, true, {
    split = "right",
    win = review_window,
    width = math.max(1, math.floor(vim.o.columns * agent_layout.sidebar_width)),
  })
  vim.cmd.startinsert()
end

function M.prepare_for_approval(patch_path)
  if patch_path and terminal and terminal:buf_valid() then
    show_patch_review(patch_path)
    return
  end
  local window = terminal and terminal:win_valid() and terminal.win
  restore_popup_after_approval = window ~= nil
    and agent_layout.current(window) == "popup"
  M.show_sidebar(true)
end

function M.restore_after_approval()
  close_patch_review()
  if not restore_popup_after_approval then
    return
  end
  restore_popup_after_approval = false
  M.open("popup")
end

function M.open(layout, args)
  local target_layout = layout or "sidebar"
  if not terminal or not terminal:buf_valid() then
    terminal = start(args)
  elseif terminal:win_valid() then
    if vim.api.nvim_win_get_config(terminal.win).hide then
      vim.api.nvim_win_set_config(terminal.win, { hide = false })
    end
  else
    terminal:show()
  end

  if terminal and terminal:win_valid() then
    vim.api.nvim_set_current_win(terminal.win)
    agent_layout.show(terminal.win, target_layout)
    vim.cmd.startinsert()
  end
end

function M.hide()
  if not (terminal and terminal:win_valid()) then
    return
  end
  if agent_layout.current(terminal.win) == "popup" then
    local window = terminal.win
    vim.api.nvim_win_set_config(window, { hide = true })
    if vim.api.nvim_get_current_win() == window then
      vim.cmd("wincmd p")
    end
  else
    terminal:hide()
  end
end

function M.toggle(layout)
  if terminal and terminal:win_valid() then
    local window = terminal.win
    if not vim.api.nvim_win_get_config(window).hide and agent_layout.current(window) == layout then
      M.hide()
      return
    end
  end
  M.open(layout)
end

function M.resize()
  if terminal and terminal:win_valid() and agent_layout.current(terminal.win) == "popup" then
    agent_layout.show(terminal.win, "popup")
  end
end

function M.draft(text, submit)
  M.open()
  if not (terminal and terminal:buf_valid()) then
    return
  end

  local channel = vim.b[terminal.buf].terminal_job_id
  if channel then
    local safe_text = text:gsub("[%z\1-\8\11-\31\127]", "")
    if submit then
      vim.api.nvim_chan_send(channel, safe_text .. "\r")
    else
      vim.api.nvim_chan_send(channel, "\27[200~" .. safe_text .. "\27[201~")
    end
  end
end

return M
