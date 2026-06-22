vim.opt.nu = true
vim.opt.relativenumber = true

vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

vim.opt.smartindent = true
vim.opt.wrap = true
vim.opt.linebreak = true

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.termguicolors = true

vim.opt.scrolloff = 8
vim.opt.smoothscroll = true
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

vim.opt.updatetime = 50

-- vim.opt.clipboard = "unnamedplus"

vim.opt.mouse = "a"

vim.opt.guicursor = "n-v-c-sm:block-blinkon500,i-ci-ve:ver25,r-cr-o:hor20"

vim.api.nvim_create_autocmd("FileType", {
	callback = function(args)
		pcall(vim.treesitter.start, args.buf)
		vim.wo[0].foldmethod = "expr"
		vim.wo[0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
	end,
})
vim.opt.foldlevelstart = 99

-- Opening files from inside a Neovim terminal (e.g. lazygit's `e`) in the
-- existing session is handled by flatten.nvim, which needs $EDITOR=nvim.
