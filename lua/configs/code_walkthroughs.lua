local M = {}
local directory = vim.fn.stdpath("state") .. "/code-walkthroughs"

function M.valid_session(value)
  return type(value) == "string"
    and #value == 36
    and value:match("^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x+$") ~= nil
end

local function valid_tour(tour)
  if type(tour) ~= "table"
    or not M.valid_session(tour.session_id)
    or type(tour.id) ~= "string"
    or not tour.id:match("^%x+$")
    or type(tour.cwd) ~= "string"
    or type(tour.saved_at) ~= "number"
    or not vim.islist(tour.stops)
    or #tour.stops == 0
  then
    return false
  end
  for _, stop in ipairs(tour.stops) do
    if type(stop) ~= "table"
      or type(stop.file) ~= "string"
      or type(stop.first_line) ~= "number"
      or type(stop.last_line) ~= "number"
      or type(stop.note) ~= "string"
      or vim.trim(stop.note) == ""
      or (stop.title ~= nil and type(stop.title) ~= "string")
    then
      return false
    end
  end
  return true
end

function M.save(tour)
  if not valid_tour(tour) then
    error("The walkthrough is missing its conversation, source, or notes")
  end
  vim.fn.mkdir(directory, "p", 448)
  local record = {
    id = tour.id, session_id = tour.session_id, cwd = tour.cwd,
    saved_at = tour.saved_at, stops = tour.stops,
  }
  local path = ("%s/%s-%s.json"):format(directory, tour.session_id, tour.id)
  if vim.fn.writefile({ vim.json.encode(record) }, path, "s") ~= 0 then
    error("Could not save the code walkthrough")
  end
end

local function entries()
  local items = {}
  for _, path in ipairs(vim.fn.globpath(directory, "*.json", false, true)) do
    local ok, tour = pcall(function()
      return vim.json.decode(table.concat(vim.fn.readfile(path), "\n"))
    end)
    if ok and valid_tour(tour) then
      local title = tour.stops[1].title or vim.fn.fnamemodify(tour.stops[1].file, ":t")
      local project = vim.fn.fnamemodify(tour.cwd, ":t")
      local search = { project, tour.session_id }
      for _, stop in ipairs(tour.stops) do
        vim.list_extend(search, { stop.title or "", stop.file, stop.note })
      end
      items[#items + 1] = {
        text = table.concat(search, " "),
        label = ("%s  ·  %d stops  ·  %s"):format(title, #tour.stops, project),
        tour = tour,
      }
    end
  end
  table.sort(items, function(a, b)
    return a.tour.saved_at > b.tour.saved_at
  end)
  return items
end

function M.pick()
  local items = entries()
  if #items == 0 then
    vim.notify("No saved walkthroughs. Ask Claude for a /show-code walkthrough first.")
    return
  end
  Snacks.picker.pick({
    title = "Saved Claude Walkthroughs",
    items = items,
    format = function(item)
      return { { item.label, "Normal" } }
    end,
    preview = function(ctx)
      local tour = ctx.item.tour
      local lines = { tour.cwd, os.date("%Y-%m-%d %H:%M", tour.saved_at), "" }
      for index, stop in ipairs(tour.stops) do
        lines[#lines + 1] = ("%d. %s"):format(index, stop.title or vim.fn.fnamemodify(stop.file, ":t"))
        lines[#lines + 1] = ("%s:%d–%d"):format(stop.file, stop.first_line, stop.last_line)
        vim.list_extend(lines, vim.split(stop.note, "\n", { plain = true }))
        lines[#lines + 1] = ""
      end
      ctx.preview:set_lines(lines)
      ctx.preview:highlight({ ft = "markdown" })
      vim.wo[ctx.preview.win.win].wrap = true
    end,
    confirm = function(picker, item)
      if item then
        picker:close()
        vim.schedule(function()
          local ok, err = pcall(function()
            require("lazy").load({ plugins = { "claudecode.nvim" } })
            if not require("claudecode").state.server then
              vim.cmd.ClaudeCodeStart()
            end
            require("configs.claude_window").reopen_code_tour(item.tour)
          end)
          if not ok then
            vim.notify(tostring(err), vim.log.levels.WARN)
          end
        end)
      end
    end,
  })
end

return M
