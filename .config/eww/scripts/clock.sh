#!/bin/bash
# eww clock: pausable stopwatch + countdown timer with deflisten JSON output.
#
# State lives in ${XDG_RUNTIME_DIR:-/tmp}/eww-clock-<user>/ so it survives
# eww reloads but not reboots.
#
#   clock.sh stopwatch <start|pause|resume|toggle|reset>
#   clock.sh stopwatch-listen        # deflisten -> {"time":"HH:MM:SS","status":"idle|running|paused"}
#   clock.sh timer <set H M S|start [H M S]|pause|resume|toggle|reset|+60|-60>
#   clock.sh timer-listen            # deflisten -> {"time":..,"status":..,"total":..,"remaining":..}
#
# In yuck, display with e.g. {stopwatch_state.time} / {stopwatch_state.status}.

set -u

USER_NAME="${USER:-$(id -un 2>/dev/null || echo unknown)}"
STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/eww-clock-${USER_NAME}"
SW_FILE="$STATE_DIR/stopwatch"
TM_FILE="$STATE_DIR/timer"

mkdir -p "$STATE_DIR"

now() { date +%s.%N; }

fmt_hms() {
    # integer seconds -> HH:MM:SS (hours may exceed 23)
    local total="${1%.*}"
    [[ "$total" =~ ^- ]] && total=0
    [[ -z "$total" ]] && total=0
    printf "%02d:%02d:%02d" $((total / 3600)) $(( (total % 3600) / 60 )) $((total % 60))
}

# --- stopwatch state ---------------------------------------------------------
sw_init() {
    [[ -f "$SW_FILE" ]] || printf 'STATUS=idle\nELAPSED=0\nSTART=0\n' > "$SW_FILE"
}

sw_get() { # $1=key
    sw_init
    grep -E "^$1=" "$SW_FILE" 2>/dev/null | cut -d= -f2- | tail -n1
}

sw_save() { # STATUS ELAPSED START
    local tmp="$SW_FILE.tmp.$$"
    printf 'STATUS=%s\nELAPSED=%s\nSTART=%s\n' "$1" "$2" "$3" > "$tmp"
    mv -f "$tmp" "$SW_FILE"
}

sw_elapsed_now() {
    local status elapsed start
    status="$(sw_get STATUS)"; [[ -z "$status" ]] && status=idle
    elapsed="$(sw_get ELAPSED)"; [[ -z "$elapsed" ]] && elapsed=0
    if [[ "$status" == "running" ]]; then
        start="$(sw_get START)"; [[ -z "$start" ]] && start="$(now)"
        awk -v e="$elapsed" -v s="$start" -v n="$(now)" 'BEGIN { r = e + (n - s); if (r < 0) r = 0; printf "%.1f", r }'
    else
        awk -v e="$elapsed" 'BEGIN { if (e < 0) e = 0; printf "%.1f", e }'
    fi
}

sw_cmd() {
    local action="${1:-toggle}"
    local status elapsed
    status="$(sw_get STATUS)"; [[ -z "$status" ]] && status=idle
    elapsed="$(sw_elapsed_now)"
    case "$action" in
        start)
            if [[ "$status" == "idle" ]]; then
                sw_save "running" "0" "$(now)"
            elif [[ "$status" == "paused" ]]; then
                sw_save "running" "$elapsed" "$(now)"
            fi
            ;;
        pause)
            [[ "$status" == "running" ]] && sw_save "paused" "$elapsed" "0"
            ;;
        resume)
            [[ "$status" == "paused" ]] && sw_save "running" "$elapsed" "$(now)"
            ;;
        toggle)
            case "$status" in
                running) sw_save "paused" "$elapsed" "0" ;;
                paused)  sw_save "running" "$elapsed" "$(now)" ;;
                *)       sw_save "running" "0" "$(now)" ;;
            esac
            ;;
        reset|stop|clear)
            sw_save "idle" "0" "0"
            ;;
        *) echo "usage: $0 stopwatch <start|pause|resume|toggle|reset>" >&2; return 1 ;;
    esac
}

sw_listen() {
    sw_init
    while true; do
        # snapshot the whole state file at once so a concurrent control
        # command can't mix old + new values in one emitted frame
        local snap status elapsed start
        snap="$(cat "$SW_FILE" 2>/dev/null)"
        status="$(printf '%s' "$snap" | grep -E '^STATUS=' | cut -d= -f2- | tail -n1)"
        [[ -z "$status" ]] && status=idle
        elapsed="$(printf '%s' "$snap" | grep -E '^ELAPSED=' | cut -d= -f2- | tail -n1)"
        [[ -z "$elapsed" ]] && elapsed=0
        if [[ "$status" == "running" ]]; then
            start="$(printf '%s' "$snap" | grep -E '^START=' | cut -d= -f2- | tail -n1)"
            [[ -z "$start" ]] && start="$(now)"
            elapsed="$(awk -v e="$elapsed" -v s="$start" -v n="$(now)" 'BEGIN { r = e + (n - s); if (r < 0) r = 0; printf "%.1f", r }')"
        fi
        # integer seconds for display
        secs="$(awk -v e="$elapsed" 'BEGIN { printf "%d", e }')"
        printf '{"time":"%s","status":"%s"}\n' "$(fmt_hms "$secs")" "$status"
        if [[ "$status" == "running" ]]; then sleep 0.2; else sleep 0.5; fi
    done
}

# --- timer state -------------------------------------------------------------
tm_init() {
    [[ -f "$TM_FILE" ]] || printf 'STATUS=idle\nTOTAL=300\nREMAINING=300\nEND=0\n' > "$TM_FILE"
}

tm_get() { # $1=key
    tm_init
    grep -E "^$1=" "$TM_FILE" 2>/dev/null | cut -d= -f2- | tail -n1
}

tm_save() { # STATUS TOTAL REMAINING END
    local tmp="$TM_FILE.tmp.$$"
    printf 'STATUS=%s\nTOTAL=%s\nREMAINING=%s\nEND=%s\n' "$1" "$2" "$3" "$4" > "$tmp"
    mv -f "$tmp" "$TM_FILE"
}

tm_remaining_now() {
    local status remaining end
    status="$(tm_get STATUS)"; [[ -z "$status" ]] && status=idle
    remaining="$(tm_get REMAINING)"; [[ -z "$remaining" ]] && remaining=0
    if [[ "$status" == "running" ]]; then
        end="$(tm_get END)"; [[ -z "$end" ]] && end="$(now)"
        awk -v r="$remaining" -v e="$end" -v n="$(now)" 'BEGIN { x = e - n; if (x < 0) x = 0; printf "%.1f", x }'
    else
        awk -v r="$remaining" 'BEGIN { if (r < 0) r = 0; printf "%.1f", r }'
    fi
}

tm_notify() {
    command -v notify-send >/dev/null 2>&1 && notify-send -a eww -u critical "Timer" "Time's up!" || true
    # best-effort sound without blocking the listener
    (command -v paplay >/dev/null 2>&1 && paplay /usr/share/sounds/freedesktop/stereo/complete.oga 2>/dev/null || true) &
}

tm_set_total() { # h m s -> echoes total
    local h="${1:-0}" m="${2:-0}" s="${3:-0}"
    h="${h%.*}"; m="${m%.*}"; s="${s%.*}"
    [[ "$h" =~ ^[0-9]+$ ]] || h=0; [[ "$m" =~ ^[0-9]+$ ]] || m=0; [[ "$s" =~ ^[0-9]+$ ]] || s=0
    (( m > 599 )) && m=599
    (( s > 599 )) && s=599
    echo $(( h * 3600 + m * 60 + s ))
}

tm_cmd() {
    local action="${1:-toggle}"; shift || true
    local status total remaining
    status="$(tm_get STATUS)"; [[ -z "$status" ]] && status=idle
    total="$(tm_get TOTAL)"; [[ "$total" =~ ^[0-9]+$ ]] || total=0
    remaining="$(tm_remaining_now)"

    case "$action" in
        set)
            total="$(tm_set_total "${1:-0}" "${2:-0}" "${3:-0}")"
            tm_save "idle" "$total" "$total" "0"
            ;;
        start)
            if [[ $# -ge 1 ]]; then
                total="$(tm_set_total "${1:-0}" "${2:-0}" "${3:-0}")"
                remaining="$total"
                status="idle"
            fi
            case "$status" in
                paused) tm_save "running" "$total" "$remaining" "$(awk -v r="$remaining" -v n="$(now)" 'BEGIN { printf "%.3f", n + r }')" ;;
                running) : ;; # no-op
                *) # idle or done -> (re)start from TOTAL
                    remaining="$total"
                    if (( total > 0 )); then
                        tm_save "running" "$total" "$remaining" "$(awk -v r="$remaining" -v n="$(now)" 'BEGIN { printf "%.3f", n + r }')"
                    else
                        tm_save "idle" "$total" "$total" "0"
                    fi
                    ;;
            esac
            ;;
        pause)
            if [[ "$status" == "running" ]]; then
                tm_save "paused" "$total" "$remaining" "0"
            fi
            ;;
        resume)
            if [[ "$status" == "paused" ]]; then
                tm_save "running" "$total" "$remaining" "$(awk -v r="$remaining" -v n="$(now)" 'BEGIN { printf "%.3f", n + r }')"
            elif [[ "$status" == "done" ]]; then
                tm_save "running" "$total" "$total" "$(awk -v r="$total" -v n="$(now)" 'BEGIN { printf "%.3f", n + r }')"
            elif [[ "$status" == "idle" && "$total" -gt 0 ]]; then
                tm_save "running" "$total" "$total" "$(awk -v r="$total" -v n="$(now)" 'BEGIN { printf "%.3f", n + r }')"
            fi
            ;;
        toggle)
            case "$status" in
                running) tm_save "paused" "$total" "$remaining" "0" ;;
                paused)  tm_save "running" "$total" "$remaining" "$(awk -v r="$remaining" -v n="$(now)" 'BEGIN { printf "%.3f", n + r }')" ;;
                done)    tm_save "running" "$total" "$total" "$(awk -v r="$total" -v n="$(now)" 'BEGIN { printf "%.3f", n + r }')" ;;
                *)       (( total > 0 )) && tm_save "running" "$total" "$total" "$(awk -v r="$total" -v n="$(now)" 'BEGIN { printf "%.3f", n + r }')" ;;
            esac
            ;;
        reset|stop|clear)
            tm_save "idle" "$total" "$total" "0"
            ;;
        +*|-*)
            # relative adjust in seconds, e.g. +60 / -30
            local delta="$action" new_total
            new_total="$(awk -v t="$total" -v d="$delta" 'BEGIN { x = t + d; if (x < 0) x = 0; printf "%d", x }')"
            if [[ "$status" == "running" ]]; then
                local new_rem new_end
                new_rem="$(awk -v r="$remaining" -v d="$delta" 'BEGIN { x = r + d; if (x < 0) x = 0; printf "%.1f", x }')"
                new_end="$(awk -v n="$(now)" -v r="$new_rem" 'BEGIN { printf "%.3f", n + r }')"
                tm_save "running" "$new_total" "$new_rem" "$new_end"
            else
                local new_r
                new_r="$(awk -v r="$remaining" -v d="$delta" -v t="$new_total" 'BEGIN { x = r + d; if (x < 0) x = 0; if (x > t) x = t; printf "%.1f", x }')"
                # keep idle remaining in sync with total when it was untouched
                if [[ "$status" == "idle" ]]; then new_r="$new_total"; fi
                tm_save "$status" "$new_total" "$new_r" "0"
            fi
            ;;
        *) echo "usage: $0 timer <set H M S|start [H M S]|pause|resume|toggle|reset|+SEC|-SEC>" >&2; return 1 ;;
    esac
}

tm_listen() {
    tm_init
    while true; do
        # snapshot the whole state file at once so a concurrent control
        # command can't mix old + new values in one emitted frame
        local snap status total remaining end
        snap="$(cat "$TM_FILE" 2>/dev/null)"
        status="$(printf '%s' "$snap" | grep -E '^STATUS=' | cut -d= -f2- | tail -n1)"
        [[ -z "$status" ]] && status=idle
        total="$(printf '%s' "$snap" | grep -E '^TOTAL=' | cut -d= -f2- | tail -n1)"
        [[ "$total" =~ ^[0-9]+$ ]] || total=0
        remaining="$(printf '%s' "$snap" | grep -E '^REMAINING=' | cut -d= -f2- | tail -n1)"
        [[ -z "$remaining" ]] && remaining=0
        if [[ "$status" == "running" ]]; then
            end="$(printf '%s' "$snap" | grep -E '^END=' | cut -d= -f2- | tail -n1)"
            [[ -z "$end" ]] && end="$(now)"
            remaining="$(awk -v e="$end" -v n="$(now)" 'BEGIN { x = e - n; if (x < 0) x = 0; printf "%.1f", x }')"
            if awk -v r="$remaining" 'BEGIN { exit !(r <= 0) }'; then
                tm_save "done" "$total" "0" "0"
                status="done"; remaining="0"
                tm_notify
            fi
        fi
        local rem_int
        rem_int="$(awk -v r="$remaining" 'BEGIN { printf "%d", r }')"
        local show="$rem_int"
        # when idle, show the armed duration (TOTAL) instead of stale remaining
        [[ "$status" == "idle" ]] && show="$total"
        local progress
        progress="$(awk -v t="$total" -v r="$rem_int" 'BEGIN { if (t <= 0) printf "0"; else { p = r * 100 / t; if (p < 0) p = 0; if (p > 100) p = 100; printf "%d", p } }')"
        printf '{"time":"%s","status":"%s","total":%d,"remaining":%d,"progress":%d}\n' \
            "$(fmt_hms "$show")" "$status" "$total" "$rem_int" "$progress"
        if [[ "$status" == "running" ]]; then sleep 0.2; else sleep 0.5; fi
    done
}

subcommand="${1:-}"; shift || true
case "$subcommand" in
    stopwatch) sw_cmd "$@" ;;
    stopwatch-listen|stopwatch_listen|sw-listen) sw_listen ;;
    timer) tm_cmd "$@" ;;
    timer-listen|timer_listen|tm-listen) tm_listen ;;
    status) # debug helper: prints both states
        echo "stopwatch: $(cat "$SW_FILE" 2>/dev/null | tr '\n' ' ')"
        echo "timer: $(cat "$TM_FILE" 2>/dev/null | tr '\n' ' ')"
        ;;
    *) echo "usage: $0 {stopwatch|stopwatch-listen|timer|timer-listen} ..." >&2; exit 1 ;;
esac
