#!/bin/bash
# Close based on actual window state, not the bool (which desyncs after
# hoverlost/Escape/reload). Never fail so && chains don't break.
if eww active-windows 2>/dev/null | grep -q ": ai_menu$"; then
	eww close ai_menu 2>/dev/null || true
fi
eww update ai_menu_toggle=false 2>/dev/null || true
exit 0
