#!/bin/bash
eww update sysnotif_type="information"
eww update sysnotif_text_main="Do you wanna print this image?"
eww update sysnotif_text_butr="Yes"
eww update sysnotif_text_butl="No"
eww update sysnotif_commandbl="eww close system_notification"
eww open system_notification
