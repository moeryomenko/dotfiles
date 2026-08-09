# conf.d/z_elio_autostart.fish
# Auto-start elio (yazi-like file manager) in a NEW unsplit tmux window only.
# Guards:
#   - `status is-interactive`  excludes the Alacritty/Ghostty bootstrap shell
#     (`fish -l -c "tmux attach || tmux"`) and all non-interactive fish, so
#     tmux startup is never blocked ("don't break system").
#   - `set -q TMUX`            only runs inside an active tmux session.
#   - `#{window_panes}` == "1" new/unsplit window only; split panes get a
#     plain shell. If the query fails (empty), the check is false: fail-safe.
#   - `command -q elio`        silently skip if elio is not installed.
# This file sorts after elio.fish (lexical), so the `elio` wrapper function
# (cd-on-exit via --cwd-file) is already defined when this runs.
if status is-interactive
    and set -q TMUX
    and command -q elio
    set -l panes (tmux display-message -p '#{window_panes}' 2>/dev/null)
    if test "$panes" = "1"
        elio
    end
end
