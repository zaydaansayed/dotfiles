function fish_right_prompt
    set -l dim (set_color 777777)
    set -l yellow (set_color E99AFF)
    set -l normal (set_color normal)

    # Show last-command duration if slow (>5s). CMD_DURATION is ms.
    if set -q CMD_DURATION; and test "$CMD_DURATION" -gt 5000
        set -l secs (math "$CMD_DURATION / 1000")
        echo -n "$yellow{$secs"s"}$normal "
    end

    # Background jobs indicator
    set -l jobs (jobs -c 2>/dev/null | count)
    if test "$jobs" -gt 0
        echo -n "$yellow&$jobs$normal "
    end

    echo -n "$dim"(date "+%H:%M:%S")"$normal"
end
