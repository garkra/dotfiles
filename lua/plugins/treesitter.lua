return {
	'nvim-treesitter/nvim-treesitter',
	lazy = false,
	build = ':TSInstall vimdoc lua typescript go javascript python rust',
}
