-- Yazi plugin initialization.
--
-- Plugins are PINNED in package.toml and installed by
-- run_onchange_after_install-yazi-packages.sh.tmpl via `ya pkg install`.
-- Keys live in keymap.toml; previewers/preloaders/fetchers in yazi.toml.
--
-- Curated set INSTALLED (see package.toml): catppuccin-macchiato flavor, git (linemode),
--   smart-enter, full-border, duckdb (data preview).
-- Trash: yazi's built-in `d` uses the macOS native trash (~/.Trash, Finder-visible, "Put
--   Back" works). recycle-bin.yazi/restore.yazi were evaluated and REJECTED on macOS: they
--   browse trash-cli's ~/.local/share/Trash, which never sees Finder-trashed files (different
--   on-disk format), so the delete→restore round-trip is broken here. Use Finder to restore.
-- Optional plugins considered and deliberately LEFT OUT:
--   jump-to-char, toggle-pane, mime-ext (perf vs accuracy tradeoff), mediainfo.yazi
--   (needs ffmpeg+mediainfo), cd-git-root.yazi, mactag.yazi (macOS Finder tags), bookmark
--   plugins whoosh/bunny/yamb (overlap the shell's zoxide), lazygit.yazi (user uses GitButler).
--   Add one by appending to package.toml, then re-run `ya pkg install`.

-- git: show git status as a linemode in the file list (order = sign-column priority).
require("git"):setup({ order = 1500 })

-- full-border: rounded full border — pairs with the Catppuccin Macchiato flavor.
require("full-border"):setup({ type = ui.Border.ROUNDED })

-- zoxide (built-in): cross-session frecency JUMP, bound to `z` in keymap.toml.
-- update_db = true so yazi and the shell (configs/zoxide.zsh) share ONE zoxide DB and
-- reinforce each other's frecency. The fzf built-in (bound to `Z`) needs no setup here —
-- it inherits FZF_DEFAULT_OPTS (configs/fzf.zsh) so it's already Catppuccin Macchiato.
require("zoxide"):setup({ update_db = true })

-- duckdb: preview CSV/TSV/JSON/Parquet (+ .db/.duckdb) as tables (previewers in yazi.toml).
require("duckdb"):setup()
