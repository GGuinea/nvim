require'nvim-treesitter.configs'.setup {

  -- A list of parser names, or "all" (the five listed parsers should always be installed)
  ensure_installed = { "lua", "vim", "help", "query", "javascript", "typescript", "elixir", "python", "css", "dockerfile", "graphql", "heex", "html", "json", "make", "markdown", "terraform", "yaml" },

  -- Install parsers synchronously (only applied to `ensure_installed`)
  sync_install = false,

  -- Automatically install missing parsers when entering buffer
  -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
  auto_install = true,

  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },
  require'nvim-treesitter.configs'.setup {
  autotag = {
    enable = true,
  }
}
}

