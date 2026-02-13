return {
	'nvim-treesitter/nvim-treesitter',
	lazy = false,
	build = ':TSInstall vimdoc lua typescript tsx go javascript python rust c cpp',
}
