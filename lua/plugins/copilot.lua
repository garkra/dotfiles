return {
	"github/copilot.vim",
	event = "InsertEnter",
	init = function()
		vim.g.copilot_filetypes = {
			markdown = false,
		}
	end,
}
