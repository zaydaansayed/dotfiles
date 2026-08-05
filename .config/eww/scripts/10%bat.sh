#!/bin/bash
eww update sysnotif_text_main="Battery low 10%"
eww update sysnotif_text_butr="Low power mode"
eww update sysnotif_text_butl="Cancel"
eww update sysnotif_commandr="eww close system_notification && tlpctl power-saver &"
eww update sysnotif_commandl="eww close system_notification"
eww open system_notification
