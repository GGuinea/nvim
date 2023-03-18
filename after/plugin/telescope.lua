local builtin = require('telescope.builtin')
local telescope = require('telescope')
local actions = require "telescope.actions"

vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
vim.keymap.set('n', '<C-p>', builtin.git_files, {})
vim.keymap.set('n', '<leader>ps', function()
builtin.grep_string({search = vim.fn.input("Grep > ") });
end)
vim.keymap.set("n", "<leader>ft", ":Telescope live_grep<CR>", opts)
vim.keymap.set("n", "<leader>fo", ":Telescope oldfiles<CR>", opts)
vim.keymap.set("n", "<leader>fb", ":Telescope buffers<CR>", opts)
vim.keymap.set("n", "<leader>fs", ":Telescope git_status<CR>", opts)

telescope.setup {
  defaults = {
    mappings = {
      i = {
        ["<Down>"] = actions.cycle_history_next,
        ["<Up>"] = actions.cycle_history_prev,
        ["<C-j>"] = actions.move_selection_next,
        ["<C-k>"] = actions.move_selection_previous,
      },
    },
  },
}
