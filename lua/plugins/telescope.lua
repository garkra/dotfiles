return {
	'nvim-telescope/telescope.nvim', version = '*',
	dependencies = {
		'nvim-lua/plenary.nvim',
		{ 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
	},
	keys = {
		{ '<leader>pf', function() require('telescope.builtin').find_files() end, desc = 'Telescope find files' },
		{ '<C-p>', function() require('telescope.builtin').git_files() end, desc = 'Telescope find git files' },
		{ '<leader>pg', function() require('telescope.builtin').live_grep() end, desc = 'Telescope live grep' },
		-- { '<leader>ps', function() require('telescope.builtin').grep_string( {search = vim.fn.input("Grep > ") }); end, desc = 'Telescope find files' },
		-- { '<leader>fb', function() require('telescope.builtin').buffers() end, desc = 'Telescope buffers' },
		-- { '<leader>fh', function() require('telescope.builtin').help_tags() end, desc = 'Telescope help tags' },
	},
}
