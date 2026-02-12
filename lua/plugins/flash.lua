return {
	"folke/flash.nvim",
	event = "VeryLazy",
	opts = {
		modes = {
			search = {
				enabled = true,
			},
		},
	},
	keys = {
		{ "<leader>s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash jump" },
		{ "<C-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle flash search" },
	},
}
