## Oh My Zsh
export ZSH=$HOME/.oh-my-zsh
# auto-update
zstyle ':omz:update' mode auto

# plugins
plugins=(git tmux extract fd ripgrep zoxide nvm cargo yarn)
NVM_AUTOLOAD=1

source $ZSH/oh-my-zsh.sh


## General

# environment variables
export USER=dev
export SHELL=/usr/bin/zsh
export EDITOR=nvim
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# alias
alias vim="nvim"
alias ls="exa"
alias l="exa -l"
alias ll="exa -la"

alias rankmirror="RUN reflector --country CA,CH,DE,FR,GB,JP,KR,SG,TW,US --protocol https --delay 1 --fastest 5 --save /etc/pacman.d/mirrorlist --verbose"
alias pubip="curl https://api.ipify.org"

if command -v trash-put &> /dev/null; then
	alias tp="trash-put"
fi

# fzf
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
_gen_fzf_default_opts() {
    local base03="#002b36"
    local base02="#073642"
    local base01="#586e75"
    local base00="#657b83"
    local base0="#839496"
    local base1="#93a1a1"
    local base2="#eee8d5"
    local base3="#fdf6e3"
    local yellow="#b58900"
    local orange="#cb4b16"
    local red="#dc322f"
    local magenta="#d33682"
    local violet="#6c71c4"
    local blue="#268bd2"
    local cyan="#2aa198"
    local green="#859900"

    export FZF_DEFAULT_OPTS="
    --color fg:-1,bg:-1,hl:$blue,fg+:$base2,bg+:$base02,hl+:$blue
    --color info:$yellow,prompt:$yellow,pointer:$base3,marker:$base3,spinner:$yellow 
    --preview 'bat --color=always --style=numbers --line-range=:500 {}' "
}
_gen_fzf_default_opts

# tsc
tsc () {
    if [ "$#" -ne 2 ]; then
        echo "Usage: $0 SESSION-NAME WORKING-DIRECTORY" >&2
        return 1
    elif [[ -e "$2" && ! -d "$2" ]]; then
        echo "tsc: $2 is not a directory" >&2
        return 2
    else
        mkdir -p $2
        tmux new-session -d -s $1 -c $2
        if [ -z "$TMUX" ]; then
            tmux attach -t $1
        else
            tmux switch -t $1
        fi
    fi
}

# starship
eval "$(starship init zsh)"

# conda
eval "$($HOME/.miniconda3/bin/conda shell.zsh hook)"

# svm
[ -f "$HOME/.svm/svm.sh" ] && source "$HOME/.svm/svm.sh"
