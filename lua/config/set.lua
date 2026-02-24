vim.opt.nu = true
vim.opt.relativenumber = true

vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

vim.opt.smartindent = true
vim.opt.wrap = true

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.termguicolors = true

vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

vim.opt.updatetime = 50

-- vim.opt.clipboard = "unnamedplus"

vim.opt.mouse = "a"

vim.opt.guicursor = "n-v-c-sm:block-blinkon500,i-ci-ve:ver25,r-cr-o:hor20"

vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldlevelstart = 99

-- When running inside a Neovim terminal (e.g. lazygit), use nvr to open
-- files in the existing Neovim instance instead of nesting a new one
if vim.fn.has("nvim") == 1 and vim.fn.executable("nvr") == 1 then
	vim.env.EDITOR = "nvr -cc split --remote-wait +'set bufhidden=wipe'"
	vim.env.VISUAL = "nvr -cc split --remote-wait +'set bufhidden=wipe'"
	vim.env.GIT_EDITOR = "nvr -cc split --remote-wait +'set bufhidden=wipe'"
end
