local M = {}

local selected_hunk_namespace = vim.api.nvim_create_namespace("GitDiffSelectedHunk")
local diff_items = {}
local selected_diff_index
local highlighted_buffer

local function set_selected_hunk_sign_highlight()
  vim.api.nvim_set_hl(0, "GitDiffSelectedHunkSign", {
    fg = "#9ece6a",
    ctermfg = 114,
  })
end

set_selected_hunk_sign_highlight()
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = set_selected_hunk_sign_highlight,
})

for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
  vim.api.nvim_buf_clear_namespace(buffer, selected_hunk_namespace, 0, -1)
end

local function absolute_path(path)
  return vim.fs.normalize(vim.fn.fnamemodify(path, ":p"))
end

local function find_hunk_index(items, file, line)
  local nearest_index
  local nearest_distance = math.huge

  for index, item in ipairs(items) do
    local item_file = Snacks.picker.util.path(item)
    if item_file and item.pos and absolute_path(item_file) == file then
      local distance = math.abs(item.pos[1] - line)
      if distance < nearest_distance then
        nearest_index = index
        nearest_distance = distance
      end
    end
  end

  return nearest_index
end

local function find_item_index(items, target)
  for index, item in ipairs(items) do
    if item.file == target.file and item.pos[1] == target.pos[1] and item.staged == target.staged then
      return index
    end
  end
end

local function save_picker_items(picker, current_file, current_line)
  diff_items = picker:items()
  if #diff_items == 0 then
    return
  end

  selected_diff_index = find_hunk_index(diff_items, current_file, current_line) or 1
  picker.list:move(selected_diff_index, true)
end

local function add_hunk_sign(buffer, line)
  local line_count = vim.api.nvim_buf_line_count(buffer)
  if line_count == 0 then
    return
  end

  local row = math.max(0, math.min(line - 1, line_count - 1))
  vim.api.nvim_buf_set_extmark(buffer, selected_hunk_namespace, row, 0, {
    sign_text = "▎",
    sign_hl_group = "GitDiffSelectedHunkSign",
    priority = 100,
  })
end

local function mark_selected_hunk(buffer, diff)
  if highlighted_buffer and vim.api.nvim_buf_is_valid(highlighted_buffer) then
    vim.api.nvim_buf_clear_namespace(highlighted_buffer, selected_hunk_namespace, 0, -1)
  end
  highlighted_buffer = buffer
  vim.api.nvim_buf_clear_namespace(buffer, selected_hunk_namespace, 0, -1)
  vim.api.nvim_set_option_value("signcolumn", "yes", { win = 0 })

  local current_line = 0
  for diff_line in (diff .. "\n"):gmatch("(.-)\n") do
    if diff_line:match("^@@") then
      local new_start = tonumber(diff_line:match("%+(%d+)")) or 1
      local new_count = tonumber(diff_line:match("%+%d+,(%d+)"))
      current_line = new_start - 1
      if new_count == 0 then
        add_hunk_sign(buffer, new_start)
      end
    elseif diff_line:sub(1, 1) == "+" and diff_line:sub(1, 3) ~= "+++" then
      current_line = current_line + 1
      add_hunk_sign(buffer, current_line)
    elseif diff_line:sub(1, 1) == " " then
      current_line = current_line + 1
    end
  end
end

local function open_diff_item(index)
  local item = diff_items[index]
  if not item then
    vim.notify("Open <leader>gd first to load the diff list", vim.log.levels.INFO)
    return
  end

  local path = Snacks.picker.util.path(item)
  if not path or vim.fn.filereadable(path) ~= 1 then
    vim.notify("This diff has no current file to open", vim.log.levels.INFO)
    return
  end

  local buffer = vim.fn.bufadd(path)
  vim.fn.bufload(buffer)
  vim.api.nvim_set_current_buf(buffer)

  local line = math.max(1, math.min(item.pos[1], vim.api.nvim_buf_line_count(buffer)))
  vim.api.nvim_win_set_cursor(0, { line, 0 })
  selected_diff_index = index
  if item.diff then
    mark_selected_hunk(buffer, item.diff)
  end
end

function M.open()
  local buffer = vim.api.nvim_get_current_buf()
  local current_file = vim.fs.normalize(vim.api.nvim_buf_get_name(buffer))
  local current_line = vim.api.nvim_win_get_cursor(0)[1]

  Snacks.picker.git_diff {
    base = vim.g.git_diff_base_commit,
    search = "",
    win = {
      input = {
        keys = {
          ["[b"] = { { "list_up", "confirm" }, mode = { "i", "n" } },
          ["]b"] = { { "list_down", "confirm" }, mode = { "i", "n" } },
        },
      },
      list = {
        keys = {
          ["[b"] = { "list_up", "confirm" },
          ["]b"] = { "list_down", "confirm" },
        },
      },
    },
    on_show = function(picker)
      local attempts = 0
      local function select_current_hunk()
        if picker.closed then
          return
        end
        local item_count = picker.finder:count()
        if picker:is_active() or #picker:items() < item_count then
          if attempts < 200 then
            attempts = attempts + 1
            vim.defer_fn(select_current_hunk, 10)
          else
            save_picker_items(picker, current_file, current_line)
          end
          return
        end
        save_picker_items(picker, current_file, current_line)
      end
      vim.schedule(select_current_hunk)
    end,
    on_change = function(picker, item)
      if #diff_items == 0 then
        diff_items = picker:items()
      end
      if item then
        local index = find_item_index(diff_items, item)
        if index then
          selected_diff_index = index
        end
      end
    end,
    confirm = function(picker, item, action)
      if item then
        local index = find_item_index(diff_items, item)
        if index then
          selected_diff_index = index
        end
      end
      Snacks.picker.actions.jump(picker, item, action)
      if item and item.diff then
        vim.schedule(function()
          mark_selected_hunk(vim.api.nvim_get_current_buf(), item.diff)
        end)
      end
    end,
  }
end

function M.navigate(direction)
  if #diff_items == 0 then
    vim.notify("Open <leader>gd once to load the diff list", vim.log.levels.INFO)
    return
  end

  local current_file = absolute_path(vim.api.nvim_buf_get_name(0))
  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  local current_index = find_hunk_index(diff_items, current_file, current_line)
    or selected_diff_index
    or (direction > 0 and 0 or 1)
  local next_index = ((current_index - 1 + direction) % #diff_items) + 1
  open_diff_item(next_index)
end

-- The diff base picked with <leader>gB (or <leader>gD's picker), shared by
-- the hunk view and <leader>gD. Ignored when it isn't a commit in this repo.
function M.set_base(commit)
  vim.g.git_diff_base_commit = commit
  M.reset()
  Snacks.notify.info("Git diff base set to " .. commit:sub(1, 7))
end

function M.base()
  local commit = vim.g.git_diff_base_commit
  if type(commit) ~= "string" or commit == "" then
    return nil
  end
  local check = vim.system({ "git", "cat-file", "-e", commit .. "^{commit}" }):wait()
  return check.code == 0 and commit or nil
end

function M.reset()
  diff_items = {}
  selected_diff_index = nil
end

return M
