local utils = require("utils")

vim.g.nvim_tree_gitignore = 1
vim.g.nvim_tree_indent_markers = 1
vim.g.nvim_tree_git_hl = 1
vim.g.nvim_tree_highlight_opened_files = 1
vim.g.nvim_tree_add_trailing = 1
vim.g.nvim_tree_group_empty = 1
vim.g.nvim_tree_respect_buf_cwd = 1

utils.map("n", "<C-_>", ":NvimTreeToggle<CR>")
utils.map("i", "<C-_>", "<ESC>:NvimTreeToggle<CR>")

local tree_cb = require("nvim-tree.config").nvim_tree_callback
require("nvim-tree").setup({
	auto_close = true,
	hijack_cursor = true,
	update_cwd = true,
	diagnostics = {
		enable = true,
		icons = {
			hint = "",
			info = "",
			warning = "",
			error = "",
		},
	},
	update_focused_file = {
		enable = true,
		update_cwd = true,
		ignore_list = {},
	},
	view = {
		width = 32,
		side = "right",
		mappings = {
			custom_only = false,
			list = {
				{ key = "x", cb = tree_cb("vsplit") },
				{ key = "v", cb = tree_cb("split") },
			},
		},
	},
})
