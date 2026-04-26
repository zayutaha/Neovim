vim.lsp.config["kotlin_language_server"] = {
  cmd = { "kotlin-language-server" },
  root_markers = { "settings.gradle", "settings.gradle.kts", "build.gradle", "build.gradle.kts", ".git" },
  filetypes = { "kotlin" },
  settings = {
    kotlin = {
      compiler = {
        jvm = {
          target = "17",
        },
      },
    },
  },
}
