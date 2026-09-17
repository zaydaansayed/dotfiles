#!/bin/bash

active=$(eww active-windows 2>/dev/null || true)
echo "$active" | grep -q ": copy-popup$" && eww close copy-popup 2>/dev/null || true
echo "$active" | grep -q ": loading-popup$" && eww close loading-popup 2>/dev/null || true
exit 0
