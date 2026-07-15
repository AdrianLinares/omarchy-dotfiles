if status is-interactive
    # Commands to run in interactive sessions can go here
    # Install Fisher if not installed. Prefer `brew install fisher` (see README §5);
    # this bootstrap is a fallback and fails gracefully on network/git.io errors.
    if not functions -q fisher
        if command -q curl
            and curl -sL https://git.io/fisher 2>/dev/null | source
            fisher install jorgebucaran/fisher
        end
    end

end

# Detect Termux
set -l IS_TERMUX 0
if test -n "$TERMUX_VERSION"; or test -d /data/data/com.termux
    set IS_TERMUX 1
end

if test $IS_TERMUX -eq 1
    # Termux - use PREFIX for binaries
    set -x PATH $PREFIX/bin $HOME/.local/bin $HOME/.cargo/bin $PATH
else if test (uname) = Darwin
    # macOS - check for Apple Silicon vs Intel
    if test -f /opt/homebrew/bin/brew
        # Apple Silicon (M1/M2/M3)
        set BREW_BIN /opt/homebrew/bin/brew
    else if test -f /usr/local/bin/brew
        # Intel Mac
        set BREW_BIN /usr/local/bin/brew
    end
    set -x PATH $HOME/.local/bin $HOME/.opencode/bin $HOME/.volta/bin $HOME/.bun/bin $HOME/.nix-profile/bin /nix/var/nix/profiles/default/bin /usr/local/bin $HOME/.cargo/bin $PATH
else
    # Linux
    set BREW_BIN /home/linuxbrew/.linuxbrew/bin/brew
    set -x PATH $HOME/.local/bin $HOME/.opencode/bin $HOME/.volta/bin $HOME/.bun/bin $HOME/.nix-profile/bin /nix/var/nix/profiles/default/bin /usr/local/bin $HOME/.cargo/bin $PATH
end

# Only eval brew shellenv if brew is installed (not on Termux)
if test $IS_TERMUX -eq 0; and set -q BREW_BIN; and test -f $BREW_BIN
    eval ($BREW_BIN shellenv)
end

# Start selected terminal multiplexer
if status is-interactive; and command -q tmux; and not set -q TMUX; and not set -q ZELLIJ; and not set -q HERDR_ENV
    tmux new-session -A -s main
end

# Initialize tools (guarded: each degrades silently if the binary is missing,
# matching the `command -q tmux` pattern already used for the multiplexer above).
if command -q starship; starship init fish | source; end
if command -q zoxide;   zoxide init fish | source; end
if command -q atuin;    atuin init fish | source; end
if command -q fzf;      fzf --fish | source; end

# Carapace completions
set -Ux CARAPACE_BRIDGES 'zsh,fish,bash,inshellisense'

if command -q carapace
    if not test -d ~/.config/fish/completions
        mkdir -p ~/.config/fish/completions
    end

    if not test -f ~/.config/fish/completions/.initialized
        carapace --list | awk '{print $1}' | xargs -I{} touch ~/.config/fish/completions/{}.fish
        touch ~/.config/fish/completions/.initialized
    end

    carapace _carapace | source
end

set -g fish_greeting ""

# Enable vi mode
fish_vi_key_bindings

# Set nvim as default editor for opencode and other tools
set -gx EDITOR nvim
set -gx VISUAL nvim

## alias
if test (uname) = Darwin
    # BSD ls uses -G for color (not --color=auto, which is GNU coreutils only).
    alias ls='ls -G'
else if command -q gls
    alias ls='gls --color=auto'
else
    # coreutils not installed -> degrade to system ls (see README §5: brew install coreutils)
    alias ls='ls --color=auto'
end

alias fzfbat='fzf --preview="bat --theme=gruvbox-dark --color=always {}"'
alias fzfnvim='nvim (fzf --preview="bat --theme=gruvbox-dark --color=always {}")'

set -l foreground F3F6F9 normal
set -l selection 263356 normal
set -l comment 8394A3 brblack
set -l red CB7C94 red
set -l orange DEBA87 orange
set -l yellow FFE066 yellow
set -l green B7CC85 green
set -l purple A3B5D6 purple
set -l cyan 7AA89F cyan
set -l pink FF8DD7 magenta

# Syntax Highlighting Colors
set -g fish_color_normal $foreground
set -g fish_color_command $cyan
set -g fish_color_keyword $pink
set -g fish_color_quote $yellow
set -g fish_color_redirection $foreground
set -g fish_color_end $orange
set -g fish_color_error $red
set -g fish_color_param $purple
set -g fish_color_comment $comment
set -g fish_color_selection --background=$selection
set -g fish_color_search_match --background=$selection
set -g fish_color_operator $green
set -g fish_color_escape $pink
set -g fish_color_autosuggestion $comment

# Completion Pager Colors
set -g fish_pager_color_progress $comment
set -g fish_pager_color_prefix $cyan
set -g fish_pager_color_completion $foreground
set -g fish_pager_color_description $comment

# Clear only in interactive sessions (avoid erasing scrollback in non-interactive contexts).
if status is-interactive
    clear
end
