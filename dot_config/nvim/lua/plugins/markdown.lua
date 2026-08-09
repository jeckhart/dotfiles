return {
  -- LazyVim's lang.markdown extra owns the base spec (build, ft, <leader>cp). Mermaid,
  -- KaTeX, sync scroll and auto-close are all mkdp defaults, so only the extra keybind
  -- and WSL2 browser routing are ours.
  {
    "iamcco/markdown-preview.nvim",
    keys = {
      { "<leader>mp", "<cmd>MarkdownPreviewToggle<cr>", ft = "markdown", desc = "Markdown preview toggle" },
    },
    init = function()
      -- mkdp's server shells out to its own browser opener and ignores $BROWSER, so
      -- WSL2 needs wsl-open named explicitly (same handler wsl2.zsh exports). Echo the
      -- URL as a fallback when interop is down and nothing can launch.
      if vim.fn.has("wsl") == 1 then
        vim.g.mkdp_browser = "wsl-open"
        vim.g.mkdp_echo_preview_url = 1
      end
    end,
  },

  -- Label the new <leader>m prefix; LazyVim reserves no group there.
  {
    "folke/which-key.nvim",
    opts = { spec = { { "<leader>m", group = "markdown" } } },
  },
}
