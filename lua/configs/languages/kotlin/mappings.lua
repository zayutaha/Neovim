local map = vim.keymap.set

map("n", "<leader>ab", "<cmd>!./gradlew assembleDebug<cr>", { desc = "Build debug APK" })
map("n", "<leader>ar", "<cmd>!./gradlew installDebug<cr>", { desc = "Install debug APK" })
map(
  "n",
  "<leader>ae",
  "<cmd>!adb shell am force-stop com.yourapp.id && adb shell am start -n com.yourapp.id/.MainActivity<cr>",
  { desc = "Restart app activity" }
)
