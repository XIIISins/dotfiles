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

-- wifi off while the CalDigit TS4 dock is attached, back on when it's gone.
-- Both the dock's ethernet (10.0.60.0/24) and wifi (192.168.2.0/24) are
-- directly connected subnets, and the wifi on-link route beats the dock's
-- default route no matter the service order, so wifi has to be off.
-- Docked means both signals agree: the TS4's USB hubs are attached and its
-- ethernet NIC (identified by MAC) exists, so a lookalike or half-up dock
-- doesn't flip wifi.
local TS4_VENDOR_ID = 0x2188 -- CalDigit; shared with its Thunderbolt vendor ID
local TS4_NIC_MAC = "64:4b:f0:6a:4a:aa"
local wifiDevice = hs.wifi.interfaces()[1] or "en0"
local docked = nil
local debounce

local function ts4Attached()
  for _, dev in ipairs(hs.usb.attachedDevices()) do
    if dev.vendorID == TS4_VENDOR_ID and (dev.productName or ""):find("^TS4") then
      return true
    end
  end
  return false
end

local function setDocked(now)
  if now == docked then return end
  docked = now
  hs.task.new("/usr/sbin/networksetup",
    nil, { "-setairportpower", wifiDevice, now and "off" or "on" }):start()
  hs.notify.show("TS4 dock", now and "docked, wifi off" or "undocked, wifi on", "")
end

-- the NIC can show up a moment after the USB hubs, so retry a few times
local function syncWifi(retries)
  if not ts4Attached() then return setDocked(false) end
  -- ifconfig reports a placeholder MAC for the dock's NIC, networksetup the real one
  hs.task.new("/usr/sbin/networksetup", function(_, out)
    if out:lower():find("ethernet address: " .. TS4_NIC_MAC, 1, true) then
      setDocked(true)
    elseif retries > 0 then
      debounce = hs.timer.doAfter(2, function() syncWifi(retries - 1) end)
    else
      setDocked(false)
    end
  end, { "-listallhardwareports" }):start()
end

-- a dock attaches/detaches as a burst of USB events; wait for it to settle
TS4Watcher = hs.usb.watcher.new(function()
  if debounce then debounce:stop() end
  debounce = hs.timer.doAfter(2, function() syncWifi(3) end)
end):start()
syncWifi(3)

-- enables the `hs` command line tool (e.g. `hs -c 'hs.reload()'`)
require("hs.ipc")

-- start at login
hs.autoLaunch(true)
