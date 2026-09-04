-------------------
---- AUTOSTART ----
-------------------

-- Use these as examples and dont delete them if you dont know what your doing

 hl.on("hyprland.start", function ()
   -- Unseen background tasks
   hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=Hyprland")
   hl.exec_cmd("wl-paste --watch cliphist store")
   hl.exec_cmd("hypridle")

   -- Visual tasks
   hl.exec_cmd("mako")
   hl.exec_cmd("~/dotfiles/.config/eww/scripts/notification_popup.sh") 
   hl.exec_cmd("eww open bar")
   hl.exec_cmd("hyprpaper")
   hl.exec_cmd("sleep 1 && eww open dock")

   -- Tasks that go to the tray
   hl.exec_cmd("udiskie --tray") 
   hl.exec_cmd("kdeconnectd")
end)

-- You may add programs to start-up as you use your PC

-------------------------------------------------------------------------------- 
------------------------ MADE BY ZAYDAAN SAYED 2026 ----------------------------
--------------------------------------------------------------------------------
