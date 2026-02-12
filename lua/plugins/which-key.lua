return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	opts = {},
	keys = {
		{ "<C-?>", function() require("which-key").show() end, desc = "Show all keybindings" },
	},
}
