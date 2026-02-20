return {
	"MeanderingProgrammer/render-markdown.nvim",
	ft = { "markdown" },
	dependencies = { "nvim-treesitter/nvim-treesitter" },
	opts = {
		heading = {
			width = "block",
			border = true,
		},
		bullet = {
			icons = { "●", "○", "◆", "◇" },
		},
		checkbox = {
			custom = {
				in_progress = { raw = "[~]", rendered = "󰥔 ", highlight = "RenderMarkdownWarn" },
				canceled = { raw = "[_]", rendered = "󰜺 ", highlight = "RenderMarkdownError" },
			},
		},
		code = {
			border = "thin",
			width = "block",
		},
		pipe_table = {
			preset = "round",
		},
		dash = {
			width = "full",
		},
	},
}
