return {
  {
    "ruifm/gitlinker.nvim",
    event = "BufReadPost",
    cond = function()
      return vim.fn.isdirectory(vim.fn.getcwd() .. "/.git") == 1
    end,
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {},
  },
  {
    "christoomey/vim-tmux-navigator",
    lazy = false,
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
      "TmuxNavigatorProcessList",
    },
    init = function()
      vim.g.tmux_navigator_no_mappings = 1
      vim.keymap.set({ "n", "v" }, "<C-h>", ":<C-u>TmuxNavigateLeft<CR>")
      vim.keymap.set({ "n", "v" }, "<C-j>", ":<C-u>TmuxNavigateDown<CR>")
      vim.keymap.set({ "n", "v" }, "<C-k>", ":<C-u>TmuxNavigateUp<CR>")
      vim.keymap.set({ "n", "v" }, "<C-l>", ":<C-u>TmuxNavigateRight<CR>")
      vim.keymap.set({ "n", "v" }, "<C-\\>", ":<C-u>TmuxNavigatePrevious<CR>")
    end,
    config = function()
      -- Clear tmux-navigator terminal mode keymaps so they don't steal keys from opencode
      vim.api.nvim_create_autocmd("TermOpen", {
        callback = function()
          vim.keymap.set("t", "<C-h>", "<C-h>", { buffer = true, noremap = true })
          vim.keymap.set("t", "<C-j>", "<C-j>", { buffer = true, noremap = true })
          vim.keymap.set("t", "<C-k>", "<C-k>", { buffer = true, noremap = true })
          vim.keymap.set("t", "<C-l>", "<C-l>", { buffer = true, noremap = true })
        end,
      })
    end,
  },
}
