local wezterm = require 'wezterm'
local config = {}

config.set_environment_variables = {
  TERMINFO_DIRS = wezterm.home_dir .. '/.terminfo:' .. (os.getenv('TERMINFO_DIRS') or '')
}
config.term = 'wezterm'

config.check_for_updates = true

config.default_cursor_style = 'BlinkingBar'
config.cursor_blink_rate = 450
config.animation_fps = 60
config.cursor_blink_ease_in = "Linear"
config.cursor_blink_ease_out = "Linear"

config.adjust_window_size_when_changing_font_size = true
config.font_size = 16.0
config.font = wezterm.font_with_fallback {
    'CommitMono Nerd Font Mono',
    'Comic Mono'
}

config.color_scheme = 'Tokyo Night Storm'

config.macos_window_background_blur = 70

config.window_decorations = "INTEGRATED_BUTTONS | RESIZE | MACOS_FORCE_ENABLE_SHADOW"
config.window_background_opacity = 0.94
config.window_close_confirmation = 'NeverPrompt'
config.window_padding = {
  left = '2cell',
  right = '2cell',
  top = '2cell',
  bottom = '1cell',
}


config.enable_tab_bar = false
config.window_frame = {
        inactive_titlebar_bg = "none",
        active_titlebar_bg = "none",
}

local onep_auth = '/Users/chip/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock'
if #wezterm.glob(onep_auth) == 1 then
  config.default_ssh_auth_sock = onep_auth
end

return config