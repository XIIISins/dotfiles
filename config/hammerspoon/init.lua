-- machine-local settings (outside the repo), e.g. `return { window_focus = false }`
local ok, settings = pcall(dofile, os.getenv("HOME") .. "/.config/local/hammerspoon/init.lua")
if not ok or type(settings) ~= "table" then settings = {} end

-- directional window focus, like `bspc node -f <dir>`: cmd+ctrl+h/j/k/l
-- (turn off with window_focus = false where a window manager owns these keys)
if settings.window_focus ~= false then
  local mod = { "cmd", "ctrl" }
  local directions = {
    h = "focusWindowWest",
    j = "focusWindowSouth",
    k = "focusWindowNorth",
    l = "focusWindowEast",
  }

  for key, method in pairs(directions) do
    hs.hotkey.bind(mod, key, function()
      local win = hs.window.focusedWindow()
      if win then win[method](win) end
    end)
  end
end

-- cmd+return does something different in every app; swallow it for any keyboard
hs.hotkey.bind({ "cmd" }, "return", function() end)
hs.hotkey.bind({ "cmd" }, "padenter", function() end)

-- enables the `hs` command line tool (e.g. `hs -c 'hs.reload()'`)
require("hs.ipc")

-- start at login
hs.autoLaunch(true)
