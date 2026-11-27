local M = { sidebar_width = 0.30 }

function M.current(window)
  return vim.api.nvim_win_get_config(window).relative == "" and "sidebar" or "popup"
end

function M.popup_config()
  local available_height = vim.o.lines - vim.o.cmdheight
  local width = math.max(1, math.floor(vim.o.columns * 0.90))
  local height = math.max(1, math.floor(available_height * 0.86))
  return {
    relative = "editor",
    row = math.floor((available_height - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    width = width,
    height = height,
    border = "rounded",
    style = "minimal",
    title = " Coding Assistant ",
    title_pos = "center",
  }
end

function M.sidebar_columns()
  return math.max(1, math.floor(vim.o.columns * M.sidebar_width))
end

-- Re-fit an assistant window to the current editor size: popups get a new
-- float config, side panes their proportional width.
function M.refit(window)
  if not (window and vim.api.nvim_win_is_valid(window)) then
    return
  end
  if M.current(window) == "popup" then
    if not vim.api.nvim_win_get_config(window).hide then
      vim.api.nvim_win_set_config(window, M.popup_config())
    end
  else
    vim.api.nvim_win_set_width(window, M.sidebar_columns())
  end
end

function M.show(window, layout)
  if layout == "popup" then
    local tab = vim.api.nvim_win_get_tabpage(window)
    local buffer = vim.api.nvim_win_get_buf(window)
    local duplicate_splits = {}
    local has_editor_split = false
    for _, split in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
      if M.current(split) == "sidebar" then
        if vim.api.nvim_win_get_buf(split) ~= buffer then
          has_editor_split = true
        elseif split ~= window then
          table.insert(duplicate_splits, split)
        end
      end
    end
    if not has_editor_split then
      vim.api.nvim_win_call(window, function()
        vim.cmd("noautocmd aboveleft vnew")
      end)
    end

    vim.api.nvim_win_set_config(window, M.popup_config())
    vim.wo[window].winblend = 0
    for _, split in ipairs(duplicate_splits) do
      vim.api.nvim_win_close(split, false)
    end
  elseif M.current(window) == "popup" then
    vim.api.nvim_win_set_config(window, {
      split = "right",
      win = -1,
      width = M.sidebar_columns(),
    })
  end
end

return M
