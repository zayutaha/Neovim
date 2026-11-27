local M = {}
local context_lines = 4

local function fingerprints(lines)
  local cache = {}
  return vim.tbl_map(function(line)
    line = vim.trim(line)
    if not cache[line] then
      cache[line] = vim.fn.sha256(line)
    end
    return cache[line]
  end, lines)
end

local function slice(lines, first, last)
  local result = {}
  for index = math.max(1, first), math.min(#lines, last) do
    result[#result + 1] = lines[index]
  end
  return result
end

function M.capture(lines, first, last)
  local hashes = fingerprints(lines)
  return {
    file = vim.fn.sha256(table.concat(hashes)),
    before = slice(hashes, first - context_lines, first - 1),
    range = slice(hashes, first, last),
    after = slice(hashes, last + 1, last + context_lines),
  }
end

local function matching_context(hashes, context, first, direction)
  local matches = 0
  local from = direction == 1 and 1 or #context
  local to = direction == 1 and #context or 1
  for index = from, to, direction do
    if hashes[first] ~= context[index] then
      break
    end
    matches = matches + 1
    first = first + direction
  end
  return matches
end

local function choose(hashes, boundary, score)
  local best, best_score
  for index, hash in ipairs(hashes) do
    if hash == boundary then
      local current = score(index)
      if current and (best_score == nil or current > best_score) then
        best, best_score = index, current
      elseif current ~= nil and current == best_score then
        best = nil
      end
    end
  end
  return best, best_score
end

function M.resolve(lines, stop)
  local anchor = stop.anchor
  if type(anchor) ~= "table" or not vim.islist(anchor.range) or #anchor.range == 0
    or not vim.islist(anchor.before) or not vim.islist(anchor.after)
  then
    return nil, "This walkthrough was saved before source anchors were available."
  end
  local hashes = fingerprints(lines)
  if vim.fn.sha256(table.concat(hashes)) == anchor.file then
    return stop.first_line, stop.last_line
  end

  local range = anchor.range
  local width = #range
  local exact, exact_score = choose(hashes, range[1], function(first)
    if matching_context(hashes, range, first, 1) == width then
      return matching_context(hashes, anchor.before, first - 1, -1)
        + matching_context(hashes, anchor.after, first + width, 1)
    end
  end)
  if exact then
    return exact, exact + width - 1
  end
  if exact_score ~= nil or width == 1 then
    return nil, "The saved highlight is missing or matches more than one place."
  end

  local start_context = slice(range, 2, context_lines)
  local end_context = slice(range, width - context_lines + 1, width - 1)
  local first = choose(hashes, range[1], function(index)
    local score = matching_context(hashes, anchor.before, index - 1, -1)
      + matching_context(hashes, start_context, index + 1, 1)
    return score > 0 and score or nil
  end)
  local last = choose(hashes, range[width], function(index)
    local score = matching_context(hashes, anchor.after, index + 1, 1)
      + matching_context(hashes, end_context, index - 1, -1)
    return score > 0 and score or nil
  end)
  if first and last and first < last then
    return first, last
  end
  return nil, "The start and end of the saved highlight could not be matched uniquely."
end

return M
