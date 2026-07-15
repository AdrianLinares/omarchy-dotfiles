# Guarded: cargo env may not exist until Rust is installed (see README §5: brew install rustup-init).
if test -f "$HOME/.cargo/env.fish"
    source "$HOME/.cargo/env.fish"
end