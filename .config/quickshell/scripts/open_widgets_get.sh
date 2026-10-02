#!/bin/bash

if eww active-windows | grep -q "widget_clock"; then
    eww update widget_clock_open=true
else
    eww update widget_clock_open=false
fi

if eww active-windows | grep -q "widget_sys"; then
    eww update widget_sys_open=true
else
    eww update widget_sys_open=false
fi

if eww active-windows | grep -q "widget_music"; then
    eww update widget_music_open=true
else
    eww update widget_music_open=false
fi

if eww active-windows | grep -q "widget_calendar"; then
    eww update widget_calendar_open=true
else
    eww update widget_calendar_open=false
fi
