-- directional window focus, like `bspc node -f <dir>`: cmd+ctrl+h/j/k/l
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

-- cmd+return does something different in every app; swallow it for any keyboard
hs.hotkey.bind({ "cmd" }, "return", function() end)
hs.hotkey.bind({ "cmd" }, "padenter", function() end)

-- enables the `hs` command line tool (e.g. `hs -c 'hs.reload()'`)
require("hs.ipc")

-- start at login
hs.autoLaunch(true)
