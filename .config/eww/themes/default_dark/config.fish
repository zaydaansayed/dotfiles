############################
# Fish Config ##############
############################

status is-interactive; or return

alias ls="ls --color=auto"
alias grep="grep --color=auto"

set -gx SUDO_EDITOR nvim

function rice
	cd ~/dotfiles/.config
	nvim
end

function dotgit
    cd ~/dotfiles
    lazygit
end

fish_add_path ~/.opencode/bin
