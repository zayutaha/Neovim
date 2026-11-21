-- Markdown rendering inside the buffer (headings, tables, checkboxes, callouts, ...)
-- https://github.com/MeanderingProgrammer/render-markdown.nvim
return {
  enabled = true,
  preset = "none",
  file_types = { "markdown" },

  heading = {
    enabled = true,
    sign = true,
    icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
    position = "overlay",
  },

  code = {
    enabled = true,
    sign = true,
    width = "full",
    border = "thin",
    language = true,
    position = "left",
    disable_background = { "diff" },
  },

  dash = { enabled = true, width = "full" },

  bullet = {
    enabled = true,
    icons = { "●", "○", "◆", "◇" },
  },

  checkbox = {
    enabled = true,
    unchecked = { icon = "󰄱 " },
    checked = { icon = "󰱒 " },
    custom = {
      -- Obsidian-style in-progress task: - [-] item
      todo = { raw = "[-]", rendered = "󰥔 " },
    },
  },

  quote = { enabled = true },

  pipe_table = {
    enabled = true,
    preset = "none",
    cell = "padded",
    -- GitHub-flavored borders
    border = {
      "┌",
      "┬",
      "┐",
      "├",
      "┼",
      "┤",
      "└",
      "┴",
      "┘",
      "│",
      "─",
    },
  },

  link = {
    enabled = true,
    image = "󰥶 ",
    email = "󰀓 ",
    hyperlink = "󰌹 ",
  },

  sign = { enabled = true },

  win_options = {
    conceallevel = { default = 0, rendered = 3 },
    concealcursor = { default = "", rendered = "" },
  },
}
