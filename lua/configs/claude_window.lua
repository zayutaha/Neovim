local M = {}
local agent_layout = require("configs.agent_layout")
local ranges = require("configs.walkthrough_ranges")
local restore_popup_after_approval = false
local open_diffs = {}
local review_tabs = {}
local tab_popups = {}
local popup_returns = {}
local shown_code_namespace = vim.api.nvim_create_namespace("ClaudeShowCode")
local shown_code_buffer
local shown_code_tab
local shown_code_window
local shown_code_origin
local code_tour
local notes_highlights = vim.api.nvim_create_namespace("ClaudeWalkthroughNotes")
local notes_window
local rendered_tour
local rendered_index
local watched_terminal
local terminal_revision = 0
local active_claude_session
local generating_session
local pending_resume

local function walkthrough_generating(tour)
  return tour.awaiting_stop or (tour.session_id and generating_session == tour.session_id)
end

M.terminal_env = {
  NVIM_SERVER = vim.v.servername,
  NVIM_CLIENT = vim.v.progpath,
  NVIM_SHOW_CODE = vim.fn.stdpath("config") .. "/scripts/show_code.py",
}

-- Link the skills shipped in this config (claude/skills/*) into Claude's
-- personal skills directory, so /show-code works without a manual install.
-- Existing entries with the same name are left alone.
local function install_claude_skills()
  local source = vim.fn.stdpath("config") .. "/claude/skills"
  local config_dir = vim.env.CLAUDE_CONFIG_DIR or (vim.env.HOME .. "/.claude")
  local target = config_dir .. "/skills"
  for name, kind in vim.fs.dir(source) do
    local link = target .. "/" .. name
    if kind == "directory" and not vim.uv.fs_lstat(link) then
      vim.fn.mkdir(target, "p")
      local ok, err = vim.uv.fs_symlink(source .. "/" .. name, link, { dir = true })
      if not ok then
        vim.notify(("Could not install Claude skill %s: %s"):format(name, err), vim.log.levels.WARN)
      end
    end
  end
end

M.terminal_options = {
  provider = "snacks",
  split_width_percentage = agent_layout.sidebar_width,
  snacks_win_opts = { resize = false, keys = { term_normal = false } },
}

local function managed_claude_window()
  local buffer = require("claudecode.terminal").get_active_terminal_bufnr()
  if not buffer then
    return
  end

  for _, terminal in pairs(Snacks.terminal.list()) do
    if terminal.buf == buffer and terminal:win_valid() then
      return terminal.win
    end
  end
end

local function claude_window()
  local window = tab_popups[vim.api.nvim_get_current_tabpage()]
  return window and vim.api.nvim_win_is_valid(window) and window or managed_claude_window()
end

local function save_popup_return(tab)
  local context = { focused = vim.api.nvim_get_current_win(), views = {} }
  for _, window in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
    if agent_layout.current(window) == "sidebar" then
      context.views[window] = {
        buffer = vim.api.nvim_win_get_buf(window),
        view = vim.api.nvim_win_call(window, vim.fn.winsaveview),
      }
    end
  end
  return context
end

local function restore_popup_return(context, popup)
  if not context then
    return
  end
  if context.focused ~= popup and vim.api.nvim_win_is_valid(context.focused) then
    vim.api.nvim_set_current_win(context.focused)
  end
  for window, saved in pairs(context.views) do
    if window ~= popup and vim.api.nvim_win_is_valid(window) and vim.api.nvim_win_get_buf(window) == saved.buffer then
      vim.api.nvim_win_call(window, function()
        vim.fn.winrestview(saved.view)
      end)
    end
  end
end

local function fit_claude_terminal(window)
  local buffer = vim.api.nvim_win_get_buf(window)
  local channel = vim.bo[buffer].channel
  if vim.bo[buffer].buftype == "terminal" and channel > 0 then
    local text_offset = vim.fn.getwininfo(window)[1].textoff
    local width = math.max(1, vim.api.nvim_win_get_width(window) - text_offset)
    local winbar = vim.wo[window].winbar ~= "" and 1 or 0
    local height = math.max(1, vim.api.nvim_win_get_height(window) - winbar)
    pcall(vim.fn.jobresize, channel, width, height)
  end
end

local function watch_terminal_output(buffer)
  if watched_terminal == buffer then
    return
  end
  watched_terminal = buffer
  vim.api.nvim_buf_attach(buffer, false, {
    on_lines = function(_, changed)
      if changed ~= watched_terminal then
        return true
      end
      terminal_revision = terminal_revision + 1
    end,
  })
end

local function set_walkthrough_highlights()
  for _, name in ipairs({ "Normal", "NormalNC" }) do
    local style = vim.api.nvim_get_hl(0, { name = name, link = false })
    style.fg = "#ffffff"
    style.ctermfg = 15
    vim.api.nvim_set_hl(notes_highlights, name, style)
  end
end

local function show_walkthrough_notes()
  local tour = code_tour
  if not tour then
    return
  end
  if not notes_window or not vim.api.nvim_win_is_valid(notes_window) then
    local buffer = vim.api.nvim_create_buf(false, true)
    vim.bo[buffer].bufhidden = "wipe"
    vim.bo[buffer].filetype = "markdown"
    notes_window = vim.api.nvim_open_win(buffer, false, {
      split = "right",
      win = -1,
      width = math.max(1, math.floor(vim.o.columns * agent_layout.sidebar_width)),
    })
    local opts = vim.wo[notes_window]
    opts.winfixwidth = true
    opts.number = false
    opts.relativenumber = false
    opts.signcolumn = "no"
    opts.wrap = true
    opts.linebreak = true
    opts.winbar = " <leader>an Next · aN Prev · ae Chat"
    vim.api.nvim_win_set_hl_ns(notes_window, notes_highlights)
    rendered_tour = nil
  end

  if rendered_tour ~= tour or rendered_index ~= tour.index then
    local stop = tour.stops[tour.index]
    local title = stop.title or vim.fn.fnamemodify(stop.file, ":t")
    local location = vim.fn.fnamemodify(stop.file, ":~:.")
    if tour.location.first then
      location = ("%s:%d–%d"):format(location, tour.location.first, tour.location.last)
    end
    local lines = {
      ("## %d/%d · %s"):format(tour.index, #tour.stops, title),
      "",
      "`" .. location .. "`",
      "",
    }
    if tour.location.reason then
      vim.list_extend(lines, {
        "> " .. tour.location.reason .. " Select the code and press `<leader>aR` to update the range.",
        "",
      })
    end
    vim.list_extend(lines, vim.split(stop.note or "", "\n", { plain = true }))
    local buffer = vim.api.nvim_win_get_buf(notes_window)
    vim.bo[buffer].modifiable = true
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
    vim.bo[buffer].modifiable = false
    vim.api.nvim_win_set_cursor(notes_window, { 1, 0 })
    rendered_tour, rendered_index = tour, tour.index
  end
  return notes_window
end

function M.in_code_tour()
  return vim.api.nvim_get_current_tabpage() == shown_code_tab
end

local function popup_terminal_options()
  return vim.tbl_extend("force", M.terminal_options.snacks_win_opts, { position = "float", backdrop = false })
end

-- Starting Claude fresh continues the project's last conversation (`-c`),
-- when there is one: `claude --continue` exits if the project has none.
local function start_args(args)
  if args or require("claudecode.terminal").get_active_terminal_bufnr() then
    return args
  end
  local config_dir = vim.env.CLAUDE_CONFIG_DIR or (vim.env.HOME .. "/.claude")
  local project = vim.fn.getcwd():gsub("[^%w]", "-")
  if #vim.fn.glob(config_dir .. "/projects/" .. project .. "/*.jsonl", false, true) > 0 then
    return "--continue"
  end
end

function M.open(layout, args)
  args = start_args(args)
  local in_tour = M.in_code_tour()
  local target_layout = in_tour and "popup" or layout or "sidebar"
  local tab = vim.api.nvim_get_current_tabpage()
  local terminal = require("claudecode.terminal")
  local window = claude_window()
  local context
  if target_layout == "popup" then
    context = save_popup_return(tab)
    local buffer = terminal.get_active_terminal_bufnr()
    local needs_local_window = window and vim.api.nvim_win_get_tabpage(window) ~= tab
    if buffer and (needs_local_window or (in_tour and not window)) then
      window = vim.api.nvim_open_win(buffer, false, agent_layout.popup_config())
      tab_popups[tab] = window
    elseif tab_popups[tab] ~= window or not window then
      terminal.open({ snacks_win_opts = popup_terminal_options() }, args)
      window = claude_window()
    end
  elseif not window or tab_popups[tab] ~= window then
    terminal.open(nil, args)
    window = claude_window()
  end
  if window then
    agent_layout.show(window, target_layout)
    if context and not popup_returns[window] then
      popup_returns[window] = context
    end
    vim.api.nvim_set_current_win(window)
    fit_claude_terminal(window)
    vim.cmd.startinsert()
  end
end

function M.show_sidebar(focus)
  if M.in_code_tour() then
    if focus then
      M.open("popup")
    end
    return
  end
  local previous_window = vim.api.nvim_get_current_win()
  local tab = vim.api.nvim_get_current_tabpage()
  local window = claude_window()
  if review_tabs[tab] and (not window or vim.api.nvim_win_get_tabpage(window) ~= tab) then
    local buffer = require("claudecode.terminal").get_active_terminal_bufnr()
    if buffer then
      window = vim.api.nvim_open_win(buffer, false, {
        split = "right", win = -1, width = math.max(1, math.floor(vim.o.columns * agent_layout.sidebar_width)),
      })
      tab_popups[tab] = window
    else
      return
    end
  end
  if not window then
    require("claudecode.terminal").open(nil, start_args())
    window = claude_window()
  end
  if not window then
    return
  end

  if vim.api.nvim_win_get_config(window).hide then
    vim.api.nvim_win_set_config(window, { hide = false })
  end
  agent_layout.show(window, "sidebar")

  if focus then
    vim.api.nvim_set_current_win(window)
    vim.cmd.startinsert()
  elseif vim.api.nvim_win_is_valid(previous_window) then
    vim.api.nvim_set_current_win(previous_window)
  end
end

local function code_range_buffer(path, first_line, last_line)
  local buffer = vim.fn.bufadd(path)
  vim.fn.bufload(buffer)
  if first_line < 1 or last_line < first_line or last_line > vim.api.nvim_buf_line_count(buffer) then
    error(("Line range %d–%d is outside %s"):format(first_line, last_line, path))
  end
  return buffer
end

local function paint_code_range(buffer, first_line, last_line)
  if shown_code_buffer and vim.api.nvim_buf_is_valid(shown_code_buffer) then
    vim.api.nvim_buf_clear_namespace(shown_code_buffer, shown_code_namespace, 0, -1)
  end
  shown_code_buffer = nil
  if not first_line then
    return
  end
  vim.api.nvim__ns_set(shown_code_namespace, { wins = { shown_code_window } })
  for line = first_line, last_line do
    vim.api.nvim_buf_set_extmark(buffer, shown_code_namespace, line - 1, 0, {
      line_hl_group = "ClaudeCodeShownRange",
      sign_text = "│",
      sign_hl_group = "DiagnosticInfo",
    })
  end
  shown_code_buffer = buffer
end

-- Put the stop on screen: the start of the range near the top, or the whole
-- range centred when it fits. Snacks' smooth scroll is paused for this window
-- while jumping, because its animation starts from the previous view and can
-- be cut off before reaching the range.
local function center_code_range(window, buffer, first_line, last_line)
  local function apply()
    if not vim.api.nvim_win_is_valid(window) or vim.api.nvim_win_get_buf(window) ~= buffer then
      return
    end
    vim.api.nvim_win_call(window, function()
      local height = vim.api.nvim_win_get_height(window)
      local span = last_line - first_line + 1
      local top = span < height and first_line - math.floor((height - span) / 2) or first_line - 2
      vim.api.nvim_win_set_cursor(window, { first_line, 0 })
      vim.cmd("normal! zv")
      vim.fn.winrestview({ topline = math.max(1, top), lnum = first_line, col = 0 })
    end)
  end

  local previous = vim.b[buffer].snacks_scroll
  vim.b[buffer].snacks_scroll = false
  apply()
  vim.defer_fn(function()
    if not vim.api.nvim_buf_is_valid(buffer) then
      return
    end
    local view = vim.api.nvim_win_is_valid(window) and vim.api.nvim_win_call(window, vim.fn.winsaveview)
    if view and view.lnum == first_line and (view.topline > first_line or view.topline + vim.api.nvim_win_get_height(window) <= first_line) then
      apply()
    end
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(buffer) then
        vim.b[buffer].snacks_scroll = previous
      end
    end)
  end, 80)
end

local function show_code_range(buffer, first_line, last_line)
  local terminal = require("claudecode.terminal").get_active_terminal_bufnr()
  if not terminal then
    error("Open the Claude terminal in Neovim first")
  end
  local tab = vim.api.nvim_get_current_tabpage()
  if tab ~= shown_code_tab then
    local origin = vim.api.nvim_get_current_win()
    shown_code_origin = popup_returns[origin] or save_popup_return(tab)
    if origin == claude_window() and agent_layout.current(origin) == "popup" then
      M.hide()
    end
    -- Neovim sizes a shared terminal to its widest window, even a hidden float.
    for _, window in ipairs(vim.fn.win_findbuf(terminal)) do
      if vim.api.nvim_win_get_tabpage(window) ~= shown_code_tab and agent_layout.current(window) == "popup" then
        vim.api.nvim_win_close(window, false)
      end
    end
  end
  if not shown_code_tab or not vim.api.nvim_tabpage_is_valid(shown_code_tab) then
    vim.cmd.tabnew()
    shown_code_tab = vim.api.nvim_get_current_tabpage()
    shown_code_window = vim.api.nvim_get_current_win()
  else
    vim.api.nvim_set_current_tabpage(shown_code_tab)
  end
  if not vim.api.nvim_win_is_valid(shown_code_window) then
    shown_code_window = vim.api.nvim_open_win(buffer, true, { split = "left", win = -1 })
  else
    vim.api.nvim_set_current_win(shown_code_window)
    vim.api.nvim_win_set_buf(shown_code_window, buffer)
  end
  vim.cmd.stopinsert()
  paint_code_range(buffer, first_line, last_line)
  center_code_range(shown_code_window, buffer, first_line or 1, last_line or first_line or 1)
end

local function hide_tour_chat()
  local window = claude_window()
  if M.in_code_tour() and window and vim.api.nvim_win_get_tabpage(window) == shown_code_tab then
    M.hide()
  end
end

local function focus_walkthrough_notes()
  if notes_window and vim.api.nvim_win_is_valid(notes_window) then
    hide_tour_chat()
    vim.api.nvim_set_current_win(notes_window)
    vim.cmd.stopinsert()
  end
end

local function show_tour_stop(tour, index)
  hide_tour_chat()
  local stop = tour.stops[index]
  local buffer, first, last, reason
  if vim.fn.filereadable(stop.file) == 1 then
    buffer = vim.fn.bufadd(stop.file)
    if vim.api.nvim_buf_is_loaded(buffer) and not vim.bo[buffer].modified then
      vim.cmd.checktime({ args = { tostring(buffer) } })
    end
    vim.fn.bufload(buffer)
    first, last = ranges.resolve(vim.api.nvim_buf_get_lines(buffer, 0, -1, false), stop)
    if not first then
      reason, last = last, nil
    end
  else
    buffer = vim.api.nvim_create_buf(false, true)
    vim.bo[buffer].bufhidden = "wipe"
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "Saved source file is no longer available.", stop.file })
    vim.bo[buffer].modifiable = false
    reason = "The saved source file could not be opened."
  end
  show_code_range(buffer, first, last)
  tour.index = index
  tour.location = { first = first, last = last, reason = reason }
  code_tour = tour
  rendered_index = nil
  watch_terminal_output(require("claudecode.terminal").get_active_terminal_bufnr())
  show_walkthrough_notes()
  if tour.reading and not walkthrough_generating(tour) then
    focus_walkthrough_notes()
  end
end

function M.toggle_code_explanation()
  if vim.api.nvim_get_current_tabpage() ~= shown_code_tab or not code_tour then
    vim.notify("Open a /show-code walkthrough first")
    return
  end
  if notes_window and vim.api.nvim_get_current_win() == notes_window then
    code_tour.focus_pending = false
    code_tour.reading = false
    M.open("popup")
    return
  end
  if walkthrough_generating(code_tour) then
    code_tour.focus_pending = true
    return
  end
  code_tour.reading = true
  show_walkthrough_notes()
  focus_walkthrough_notes()
end

function M.show_code_tour(stops, id, session_id)
  if not vim.islist(stops) or #stops == 0 then
    error("The walkthrough needs at least one stop")
  end
  for _, stop in ipairs(stops) do
    local buffer = code_range_buffer(stop.file, stop.first_line, stop.last_line)
    stop.anchor = ranges.capture(vim.api.nvim_buf_get_lines(buffer, 0, -1, false), stop.first_line, stop.last_line)
  end
  local history = require("configs.code_walkthroughs")
  if session_id and session_id ~= vim.NIL and not history.valid_session(session_id) then
    error("A valid Claude conversation ID is required")
  end
  session_id = session_id ~= vim.NIL and session_id or nil
  local tour = {
    stops = stops, id = id, session_id = session_id,
    awaiting_stop = session_id ~= nil, focus_pending = session_id ~= nil,
  }
  show_tour_stop(tour, 1)
  return "ok"
end

function M.show_code(path, first_line, last_line)
  return M.show_code_tour({ { file = path, first_line = first_line, last_line = last_line or first_line } })
end

local function tour_for_session(session_id)
  if not code_tour or not code_tour.session_id or code_tour.session_id ~= session_id then
    error("Open the walkthrough for this Claude conversation first")
  end
  return code_tour
end

function M.code_tour_status(session_id)
  local tour = tour_for_session(session_id)
  local stops = {}
  for index, stop in ipairs(tour.stops) do
    local ok, lines = pcall(vim.fn.readfile, stop.file)
    local first, last
    if ok then
      first, last = ranges.resolve(lines, stop)
    end
    stops[index] = {
      index = index, file = stop.file, title = stop.title, note = stop.note,
      first_line = first or vim.NIL, last_line = first and last or vim.NIL,
      saved_first_line = stop.first_line, saved_last_line = stop.last_line,
    }
  end
  return vim.json.encode({ id = tour.id, index = tour.index, saved = tour.saved_at ~= nil, stops = stops })
end

function M.update_code_tour(session_id, id, updates)
  local tour = tour_for_session(session_id)
  if tour.id ~= id or not tour.saved_at then
    error("The requested walkthrough is no longer active or has not been saved yet")
  end

  local stops = vim.deepcopy(tour.stops)
  local updated = {}
  for _, update in ipairs(updates) do
    local index = update.index
    local stop = stops[index]
    if not stop or updated[index] or vim.fs.normalize(stop.file) ~= vim.fs.normalize(update.file) then
      error("Each update must identify a distinct saved stop in the same file")
    end
    local lines = vim.fn.readfile(stop.file)
    if update.first_line < 1 or update.last_line < update.first_line or update.last_line > #lines then
      error("The updated range is outside the saved source file")
    end
    stop.first_line = update.first_line
    stop.last_line = update.last_line
    stop.title = update.title or stop.title
    stop.note = update.note
    stop.anchor = ranges.capture(lines, stop.first_line, stop.last_line)
    updated[index] = true
  end
  require("configs.code_walkthroughs").save(vim.tbl_extend("force", tour, { stops = stops }))
  tour.stops = stops

  if updated[tour.index] and shown_code_window and vim.api.nvim_win_is_valid(shown_code_window) then
    local stop = stops[tour.index]
    local buffer = vim.api.nvim_win_get_buf(shown_code_window)
    if vim.api.nvim_buf_get_name(buffer) == stop.file then
      if not vim.bo[buffer].modified then
        vim.cmd.checktime({ args = { tostring(buffer) } })
      end
      local first, last = ranges.resolve(vim.api.nvim_buf_get_lines(buffer, 0, -1, false), stop)
      tour.location = { first = first, last = first and last or nil, reason = not first and last or nil }
      paint_code_range(buffer, first, last)
    end
    if notes_window and vim.api.nvim_win_is_valid(notes_window) then
      rendered_index = nil
      show_walkthrough_notes()
    end
  end
  return "ok"
end

function M.step_code_tour(direction)
  if not code_tour or not shown_code_tab or not vim.api.nvim_tabpage_is_valid(shown_code_tab) then
    error("Open a /show-code walkthrough first")
  end
  local index = code_tour.index + direction
  if code_tour.stops[index] then
    code_tour.reading = true
    if walkthrough_generating(code_tour) then
      code_tour.focus_pending = true
    end
    show_tour_stop(code_tour, index)
  else
    vim.notify(direction < 0 and "First walkthrough stop" or "Last walkthrough stop")
  end
  return "ok"
end

local function focus_after_output(tour, attempts)
  local revision = terminal_revision
  vim.defer_fn(function()
    if code_tour ~= tour or not tour.focus_pending or walkthrough_generating(tour) then
      return
    end
    if revision ~= terminal_revision and attempts > 0 then
      focus_after_output(tour, attempts - 1)
      return
    end
    if shown_code_tab ~= vim.api.nvim_get_current_tabpage() then
      return
    end
    if not notes_window or not vim.api.nvim_win_is_valid(notes_window) then
      return
    end
    tour.focus_pending = false
    tour.reading = true
    focus_walkthrough_notes()
  end, 250)
end

local function show_saved_tour(tour)
  tour.awaiting_stop = false
  tour.focus_pending = true
  tour.reading = false
  show_tour_stop(tour, 1)
  focus_after_output(tour, 12)
end

function M.reopen_code_tour(tour)
  local terminal = require("claudecode.terminal")
  local active = terminal.get_active_terminal_bufnr()
  if active and generating_session then
    vim.notify("Claude is still responding. Open the saved walkthrough when it finishes.", vim.log.levels.WARN)
    return
  end
  if active and active_claude_session == tour.session_id then
    show_saved_tour(tour)
    return
  end
  local request = { tour = tour }
  pending_resume = request
  if active then
    terminal.close()
  end
  terminal.open({ cwd = tour.cwd, snacks_win_opts = popup_terminal_options() }, "--resume " .. tour.session_id)
  vim.defer_fn(function()
    if pending_resume == request then
      pending_resume = nil
      vim.notify("Claude didn't confirm it reopened this conversation", vim.log.levels.WARN)
    end
  end, 20000)
end

function M.walkthrough_event(event, session_id, cwd)
  local history = require("configs.code_walkthroughs")
  if not history.valid_session(session_id) then
    return "ignored"
  end
  if event == "SessionStart" then
    active_claude_session = session_id
    generating_session = nil
    if pending_resume and pending_resume.tour.session_id == session_id then
      local tour = pending_resume.tour
      pending_resume = nil
      vim.schedule(function()
        local ok, err = pcall(show_saved_tour, tour)
        if not ok then
          vim.notify(tostring(err), vim.log.levels.WARN)
        end
      end)
    end
  elseif event == "UserPromptSubmit" then
    active_claude_session = session_id
    generating_session = session_id
  elseif event == "SessionEnd" then
    if active_claude_session == session_id then
      active_claude_session = nil
    end
    if generating_session == session_id then
      generating_session = nil
    end
  elseif event == "Stop" or event == "StopFailure" then
    if generating_session == session_id then
      generating_session = nil
    end
    local tour = code_tour
    if tour and tour.session_id == session_id then
      local was_new = tour.awaiting_stop
      tour.awaiting_stop = false
      if event == "Stop" then
        if was_new then
          tour.cwd = cwd
          tour.saved_at = os.time()
          local ok, err = pcall(history.save, tour)
          if not ok then
            vim.notify(tostring(err), vim.log.levels.WARN)
          end
        end
        if tour.focus_pending then
          focus_after_output(tour, 12)
        end
      else
        tour.focus_pending = false
      end
    end
  end
  return "ok"
end

local function diff_selection(path, lines, line_types)
  local anchor, cursor = vim.fn.line("v"), vim.fn.line(".")
  local prefixes = { added = "+", deleted = "-" }
  local selection = {}
  for index = math.min(anchor, cursor), math.max(anchor, cursor) do
    selection[#selection + 1] = (prefixes[line_types[index]] or " ") .. (lines[index] or "")
  end
  local patch = table.concat(selection, "\n")
  local fence = "```"
  for ticks in patch:gmatch("`+") do
    if #ticks >= #fence then
      fence = string.rep("`", #ticks + 1)
    end
  end
  return (table.concat({
    "About this proposed diff for " .. path .. ":",
    fence .. "diff",
    patch,
    fence,
    "",
    "Question: ",
  }, "\n"):gsub("[%z\1-\8\11-\31\127]", ""))
end

local function leave_visual_mode()
  vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
end

function M.reanchor_code_tour()
  if not code_tour or vim.api.nvim_get_current_win() ~= shown_code_window or vim.bo.buftype ~= "" then
    vim.notify("Select the code in the walkthrough's source pane first", vim.log.levels.WARN)
    return
  end
  local anchor, cursor = vim.fn.line("v"), vim.fn.line(".")
  local first, last = math.min(anchor, cursor), math.max(anchor, cursor)
  local buffer = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(buffer)
  if vim.fn.filereadable(path) ~= 1 then
    vim.notify("Open a source file before updating this highlight", vim.log.levels.WARN)
    return
  end
  local stop = code_tour.stops[code_tour.index]
  stop.file, stop.first_line, stop.last_line = path, first, last
  stop.anchor = ranges.capture(vim.api.nvim_buf_get_lines(buffer, 0, -1, false), first, last)
  if code_tour.saved_at then
    local ok, err = pcall(require("configs.code_walkthroughs").save, code_tour)
    if not ok then
      vim.notify(tostring(err), vim.log.levels.WARN)
    end
  end
  leave_visual_mode()
  show_tour_stop(code_tour, code_tour.index)
end

local function send_review_text(text, failure, terminal_buffer, submit)
  vim.schedule(function()
    local terminal = require("claudecode.terminal")
    if terminal_buffer
      and terminal.get_active_terminal_bufnr() == terminal_buffer
      and (not submit or not next(open_diffs))
      and terminal.send_to_terminal(text, { submit = submit })
    then
      if not submit then
        M.show_sidebar(true)
      end
    else
      vim.notify(failure, vim.log.levels.WARN)
    end
  end)
end

local function read_review_source(path)
  local stat, err, code = vim.uv.fs_lstat(path)
  if not stat then
    if code == "ENOENT" then
      return false
    end
    return nil, err
  end
  if stat.type ~= "file" then
    return nil, "the target is not a regular file"
  end
  local file, open_error = io.open(path, "rb")
  if not file then
    return nil, open_error
  end
  local text, read_error = file:read("*a")
  file:close()
  return text, read_error
end

local function apply_review(path, original, proposed)
  local current, err = read_review_source(path)
  if current == nil or current ~= original then
    vim.notify("Cannot apply pinned diff: " .. (err or "the file changed after review began"), vim.log.levels.WARN)
    return false
  end

  local loaded = {}
  local resolved_path = vim.uv.fs_realpath(path)
  for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buffer) and vim.bo[buffer].buftype == "" then
      local name = vim.api.nvim_buf_get_name(buffer)
      if name == path or (resolved_path and vim.uv.fs_realpath(name) == resolved_path) then
        if vim.bo[buffer].modified or vim.bo[buffer].readonly then
          vim.notify("Cannot apply pinned diff: the source buffer is modified or read-only", vim.log.levels.WARN)
          return false
        end
        loaded[#loaded + 1] = buffer
      end
    end
  end

  local ok, result = pcall(vim.fn.writefile, vim.split(proposed, "\n", { plain = true }), path, "bs")
  if not ok or result ~= 0 then
    vim.notify("Could not write pinned diff: " .. tostring(result), vim.log.levels.ERROR)
    return false
  end
  for _, buffer in ipairs(loaded) do
    vim.cmd.checktime({ args = { tostring(buffer) } })
  end
  return true
end

local function review_touches_walkthrough(path, original, proposed)
  local tour = code_tour
  if not tour or not tour.saved_at or tour.session_id ~= active_claude_session or not original then
    return false
  end
  local source = vim.split(original, "\n", { plain = true })
  if source[#source] == "" then
    table.remove(source)
  end
  local changes
  for _, stop in ipairs(tour.stops) do
    if vim.fs.normalize(stop.file) == vim.fs.normalize(path) then
      local first, last = ranges.resolve(source, stop)
      if first then
        changes = changes or vim.diff(original, proposed, { result_type = "indices" }) or {}
        for _, change in ipairs(changes) do
          local start, count = change[1], change[2]
          if (count == 0 and start >= first and start < last)
            or (count > 0 and start <= last and start + count - 1 >= first)
          then
            return true
          end
        end
      end
    end
  end
  return false
end

local function open_diff_review(name, proposal)
  local diff = require("claudecode.diff")
  local state = diff._get_active_diffs()[name]
  if not state or state.status ~= "pending" or state.layout ~= "unified" or state.new_buffer ~= proposal then
    return
  end

  local cursor = vim.api.nvim_win_is_valid(state.new_window) and vim.api.nvim_win_get_cursor(state.new_window)
  local path = state.old_file_path
  local lines, line_types = state.lines, state.line_types
  local proposed = state.new_file_contents
  local terminal_buffer = require("claudecode.terminal").get_active_terminal_bufnr()
  local inline = require("claudecode.diff_inline")
  local original, apply_error = read_review_source(path)
  if original ~= nil then
    local current_lines, current_types = inline.compute_inline_diff(original or "", proposed)
    if (original == false) ~= state.is_new_file
      or not vim.deep_equal(lines, current_lines)
      or not vim.deep_equal(line_types, current_types)
    then
      apply_error = "the file changed while the proposal was open"
    end
  end
  if proposed:find("\0", 1, true) then
    apply_error = "the proposal contains binary data"
  end
  local buffer = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buffer, ("Claude diff %d: %s"):format(buffer, vim.fn.fnamemodify(path, ":t")))
  inline.render_diff_buffer(buffer, lines, line_types)
  vim.bo[buffer].filetype = vim.bo[proposal].filetype
  vim.bo[buffer].bufhidden = "wipe"
  vim.bo[buffer].modifiable = false
  vim.bo[buffer].readonly = true
  vim.keymap.set("x", "<leader>as", function()
    local selection = diff_selection(path, lines, line_types)
    leave_visual_mode()
    send_review_text(selection, "Could not attach the selection to Claude", terminal_buffer, false)
  end, { buffer = buffer, desc = "Attach selected diff lines to Claude" })
  local function close_review()
    if #vim.api.nvim_list_tabpages() > 1 then
      vim.cmd.tabclose()
    else
      vim.api.nvim_buf_delete(buffer, {})
    end
  end
  vim.keymap.set("n", "<leader>ad", close_review, { buffer = buffer, desc = "Close Claude diff review" })

  local applied = false
  vim.keymap.set("n", "<leader>aa", function()
    if applied then
      vim.notify("This pinned diff is already applied")
    elseif apply_error or original == nil then
      vim.notify("Cannot apply pinned diff: " .. (apply_error or "original file is unavailable"), vim.log.levels.WARN)
    elseif apply_review(path, original, proposed) then
      applied = true
      local message = "I applied your proposed changes. Please continue."
      if review_touches_walkthrough(path, original, proposed) then
        message = message .. " Use /show-code to update the affected saved walkthrough stops."
      end
      send_review_text(message,
        "The diff was applied, but Claude could not receive the follow-up", terminal_buffer, true)
      close_review()
    end
  end, { buffer = buffer, desc = "Apply pinned Claude diff" })

  restore_popup_after_approval = false
  if not diff.close_diff_by_tab_name(name) then
    vim.api.nvim_buf_delete(buffer, { force = true })
    return
  end

  local origin = save_popup_return(vim.api.nvim_get_current_tabpage())
  vim.cmd.tabnew()
  review_tabs[vim.api.nvim_get_current_tabpage()] = origin
  local editor = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(editor, buffer)
  vim.wo[editor].winbar = " <leader>aa Apply and send   <leader>ad Close   <leader>as Ask about selected lines"
  vim.api.nvim_set_option_value("signcolumn", "yes", { scope = "local", win = editor })
  if cursor then
    vim.api.nvim_win_set_cursor(editor, cursor)
  end
  M.show_sidebar(false)
end

local function remember_popup()
  local window = claude_window()
  if window and agent_layout.current(window) == "popup" then
    restore_popup_after_approval = true
  end
end

function M.prepare_for_approval()
  if next(open_diffs) then
    return
  end
  remember_popup()
  M.show_sidebar(true)
end

function M.restore_after_approval()
  if not restore_popup_after_approval or next(open_diffs) then
    return
  end
  restore_popup_after_approval = false
  M.open("popup")
end

function M.hide()
  local tab = vim.api.nvim_get_current_tabpage()
  local window = claude_window()
  if not window or vim.api.nvim_win_get_config(window).hide then
    return
  end
  if M.in_code_tour() and vim.api.nvim_win_get_tabpage(window) ~= tab then
    return
  end
  local context = popup_returns[window]
  popup_returns[window] = nil
  if tab_popups[tab] == window then
    vim.api.nvim_win_close(window, false)
    tab_popups[tab] = nil
  else
    require("claudecode.terminal").simple_toggle()
  end
  restore_popup_return(context, window)
end

function M.toggle(layout)
  if M.in_code_tour() then
    layout = "popup"
  end
  local window = claude_window()
  if window and vim.api.nvim_win_get_tabpage(window) == vim.api.nvim_get_current_tabpage() then
    local config = vim.api.nvim_win_get_config(window)
    if not config.hide and agent_layout.current(window) == layout then
      M.hide()
      return
    end
  end

  M.open(layout)
end

function M.send(command)
  vim.cmd(command)
  -- ClaudeCodeSend schedules the send after leaving Visual mode.
  vim.schedule(function()
    M.open()
  end)
end

function M.setup()
  pcall(install_claude_skills)

  local function map_terminal_keys(buffer)
    require("configs.assistant").map_terminal_keys(buffer)
  end

  local group = vim.api.nvim_create_augroup("ClaudeWindow", { clear = true })
  set_walkthrough_highlights()
  vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = set_walkthrough_highlights })
  vim.api.nvim_create_autocmd("TabLeave", {
    group = group,
    callback = function()
      local tab = vim.api.nvim_get_current_tabpage()
      local origin = tab == shown_code_tab and shown_code_origin or review_tabs[tab]
      if not origin then
        return
      end
      vim.schedule(function()
        if not vim.api.nvim_tabpage_is_valid(tab) then
          restore_popup_return(origin)
        end
      end)
    end,
  })
  vim.api.nvim_create_autocmd("TabClosed", {
    group = group,
    callback = function()
      for tab in pairs(review_tabs) do
        if not vim.api.nvim_tabpage_is_valid(tab) then
          review_tabs[tab] = nil
        end
      end
    end,
  })
  vim.api.nvim_create_autocmd("WinClosed", {
    group = group,
    callback = function(event)
      local window = tonumber(event.match)
      popup_returns[window] = nil
      if window == shown_code_window then
        if shown_code_buffer and vim.api.nvim_buf_is_valid(shown_code_buffer) then
          vim.api.nvim_buf_clear_namespace(shown_code_buffer, shown_code_namespace, 0, -1)
        end
        shown_code_buffer = nil
      end
      for tab, popup in pairs(tab_popups) do
        if popup == window then
          tab_popups[tab] = nil
          break
        end
      end
    end,
  })
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "claudecode",
    callback = function(event)
      map_terminal_keys(event.buf)
    end,
  })
  vim.api.nvim_create_autocmd("VimResized", {
    group = group,
    callback = function()
      local window = claude_window()
      if window and agent_layout.current(window) == "popup" then
        agent_layout.show(window, "popup")
      end
    end,
  })
  vim.api.nvim_create_autocmd("WinResized", {
    group = group,
    callback = function()
      if vim.api.nvim_get_current_tabpage() == shown_code_tab then
        local window = claude_window()
        if window and vim.api.nvim_win_get_tabpage(window) == shown_code_tab then
          fit_claude_terminal(window)
        end
      end
    end,
  })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "ClaudeCodeDiffOpened",
    callback = function(event)
      open_diffs[event.data.tab_name] = true
      remember_popup()
      local window = event.data.diff_window
      if window and vim.api.nvim_win_is_valid(window) then
        local buffer = vim.api.nvim_win_get_buf(window)
        if vim.b[buffer].claudecode_inline_diff then
          local name = event.data.tab_name
          vim.schedule(function()
            open_diff_review(name, buffer)
          end)
        end
      end
    end,
  })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "ClaudeCodeDiffClosed",
    callback = function(event)
      open_diffs[event.data.tab_name] = nil
      vim.schedule(M.restore_after_approval)
    end,
  })

  local buffer = require("claudecode.terminal").get_active_terminal_bufnr()
  if buffer then
    map_terminal_keys(buffer)
  end
end

return M
