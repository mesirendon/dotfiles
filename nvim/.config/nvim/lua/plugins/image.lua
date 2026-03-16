return {
  "3rd/image.nvim",
  lazy = false,
  opts = {
    backend = "kitty",
    integrations = {
      markdown = {
        enabled = true,
        clear_in_insert_mode = true,
        only_render_image_at_cursor = false,
      },
      html = { enabled = false },
      css = { enabled = false },
    },
    max_width = 100,
    max_height = 40,
    editor_only_render_when_focused = true,
    tmux_show_only_in_active_window = true,
    hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.svg" },
  },
}
