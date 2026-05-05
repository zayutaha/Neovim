# NvChad Custom Configuration

This is a personal Neovim configuration based on [NvChad v2.5](https://nvchad.com). It is tailored for web development, Rust, Python, and Go, featuring AI integration and enhanced UI components.

## 📂 Project Structure

```
~/.config/nvim/
├── init.lua              # Main entry point (bootstraps lazy.nvim & NvChad)
├── lua/
│   ├── chadrc.lua        # NvChad UI overrides (Theme: tokyonight)
│   ├── mappings.lua      # Global key mappings
│   ├── options.lua       # Global vim options
│   ├── plugins/          # Plugin loading entry points
│   └── configs/          # Detailed configuration modules
│       ├── editor/       # General editor features (AI, UI, tools)
│       └── languages/    # Language-specific settings (LSP, plugins)
```

## ✨ Key Features

### 🧠 AI Integration
- **[opencode.nvim](https://github.com/nickjvandyke/opencode.nvim):** Neovim integration for [OpenCode](https://opencode.ai), an open source AI coding agent. Keymaps: `<C-a>` ask, `<C-x>` select action, `<C-.>` toggle, `go` operator.

### 🛠️ Development Tools
- **LSP & Formatting:** Managed via [Mason](https://github.com/williamboman/mason.nvim) and [Conform](https://github.com/stevearc/conform.nvim).
    - **Pre-installed:** `pyright`, `mypy`, `typescript-language-server`, `tailwind-language-server`, `eslint-lsp`, `gopls`, `prettier`, `stylua`.
- **Treesitter:** Highlighting support for Lua, Vim, HTML, CSS, Rust, TypeScript, and Go.
- **Hardtime:** [hardtime.nvim](https://github.com/m4xshen/hardtime.nvim) is enabled to help establish better Vim habits by blocking repeated keys.

### 🎨 UI & UX Enhancements
- **Theme:** Tokyonight (configured in `chadrc.lua`).
- **Diagnostics:** [tiny-inline-diagnostic.nvim](https://github.com/rachartier/tiny-inline-diagnostic.nvim) for cleaner inline errors in Rust and TypeScript.
- **Utilities:** [Snacks.nvim](https://github.com/folke/snacks.nvim) for various quality-of-life improvements and debugging helpers (`dd`, `bt`).
- **Completion:** Custom `nvim-cmp` setup including `crates` source for Rust.

## 🚀 Language Specifics

Configurations are modularized under `lua/configs/languages/`:

- **Rust:** Includes specific plugin support (likely `crates.nvim` and others).
- **Python:** Dedicated plugin and LSP settings.
- **Go & TypeScript:** Supported via LSP (gopls, tsserver) and Treesitter, with additional configurations available in their respective folders.

## 📦 Installation

1.  **Backup:** Ensure you back up your current configuration.
2.  **Clone:**
    ```bash
    git clone <repository-url> ~/.config/nvim
    ```
3.  **Start:** Run `nvim`. Lazy.nvim will automatically bootstrap and install all plugins.
4.  **Dependencies:** Ensure you have a Nerd Font installed and `ripgrep` / `fd` for Telescope.

## ⌨️ Customization

- **Keybindings:** Edit `lua/mappings.lua`.
- **UI/Theme:** Edit `lua/chadrc.lua`.
- **Plugins:** Add new plugins in `lua/plugins/init.lua` or `lua/configs/`.

## 📝 TODO

- Check `lua/TODO.md` for pending tasks and improvements.
