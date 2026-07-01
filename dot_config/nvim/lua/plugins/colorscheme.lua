return {
  -- Configure Catppuccin to the Macchiato flavour (matches the rest of the stack:
  -- zsh, fzf, bat, delta, eza, vivid, yazi, helix, tmux).
  {
    "catppuccin/nvim",
    name = "catppuccin",
    opts = { flavour = "macchiato" },
  },

  -- Tell LazyVim to load it.
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "catppuccin-macchiato" },
  },
}
