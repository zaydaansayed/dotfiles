############################
# Fish Config ##############
############################

status is-interactive; or return

alias ls="ls --color=auto"
alias grep="grep --color=auto"

set -gx SUDO_EDITOR nvim

function dotgit
    cd ~/dotfiles
    lazygit
end

fish_add_path ~/.opencode/bin

# Auto-run fastfetch when opening Kitty (new window/tab only, not subshells)
if type -q fastfetch
    if test "$TERM" = "xterm-kitty"; or set -q KITTY_WINDOW_ID
        if not set -q SHLVL; or test "$SHLVL" -le 2
            fastfetch
        end
    end
end
