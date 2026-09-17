function fish_prompt
    # Save exit status immediately -- must be first line
    set -l last_status $status

    # Colors from eww night_sky (eww/scss/colors.scss):
    # accent_1 salmon, accent_2 teal, accent_3 pink, accent_5 purple
    set -l salmon (set_color --bold E07D68)
    set -l purple (set_color --bold A358D1)
    set -l pink   (set_color --bold E99AFF)
    set -l teal   (set_color --bold 549D9D)
    set -l orange (set_color --bold FFB07C)
    set -l white  (set_color FFFFFF)
    set -l fail   (set_color --bold C26B59)
    set -l gray   (set_color 777777)
    set -l normal (set_color normal)

    # --- user@host (fast builtins, no subprocess) ---
    set -l cur_user $USER
    if test -z "$cur_user"
        set cur_user (whoami 2>/dev/null)
    end
    # prompt_hostname is a fish builtin, much faster than (hostname -s)
    set -l cur_host (prompt_hostname)

    # --- current directory, shortened to ~/... ---
    set -l directory (prompt_pwd)

    # --- python venv / conda ---
    set -l venv_str ""
    if set -q VIRTUAL_ENV
        set venv_str " ("(basename $VIRTUAL_ENV)")"
    else if set -q CONDA_DEFAULT_ENV
        set venv_str " ("(basename $CONDA_DEFAULT_ENV)")"
    end

    # --- git: branch + dirty flags ---
    # flags: * unstaged modified, + staged, ? untracked, ! conflict
    set -l git_str ""
    if command git rev-parse --is-inside-work-tree >/dev/null 2>&1
        set -l branch (command git branch --show-current 2>/dev/null)
        if test -z "$branch"
            # detached HEAD: show short sha
            set branch (command git rev-parse --short HEAD 2>/dev/null)
        end
        if test -n "$branch"
            set -l flags ""

            if not command git diff --quiet 2>/dev/null
                set flags "$flags*"
            end
            if not command git diff --cached --quiet 2>/dev/null
                set flags "$flags+"
            end
            # untracked: any output line means yes (count is newline-split, safe with spaces)
            set -l untracked (command git ls-files --others --exclude-standard 2>/dev/null)
            if test (count $untracked) -gt 0
                set flags "$flags?"
            end
            set -l conflicted (command git diff --name-only --diff-filter=U 2>/dev/null)
            if test (count $conflicted) -gt 0
                set flags "$flags!"
            end

            if test -n "$flags"
                set git_str " [$branch $flags]"
            else
                set git_str " [$branch]"
            end
        end
    end

    # --- line 1: info ---
    echo -n "$gray╭─$normal "
    echo -n "$purple$cur_user$normal"
    echo -n "$white@$normal"
    echo -n "$pink$cur_host$normal"
    echo -n "$white | $normal$salmon$directory$normal"
    if test -n "$venv_str"
        echo -n "$orange$venv_str$normal"
    end
    if test -n "$git_str"
        echo -n "$teal$git_str$normal"
    end
    echo # newline -> line 2

    # --- line 2: prompt char + exit status ---
    # NOTE: set -l inside if/else is block-scoped in fish,
    # so define the variable BEFORE the branch (this was the old bug).
    set -l prompt_char ""
    if test $last_status -eq 0
        set prompt_char "$teal❯$normal"
    else
        set prompt_char "$fail✗ $last_status ❯$normal"
    end
    echo -n "$gray╰─$normal $prompt_char "
end
