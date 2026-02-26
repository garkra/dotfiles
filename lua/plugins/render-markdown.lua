return {
	"MeanderingProgrammer/render-markdown.nvim",
	ft = { "markdown" },
	dependencies = { "nvim-treesitter/nvim-treesitter" },
	opts = {
		render_modes = true,
		anti_conceal = {
			enabled = true,
			ignore = {
				code_background = true,
				indent = true,
				sign = true,
				virtual_lines = true,
				-- check_icon = true,
				-- checkbox = true,
				check_scope = true,
				-- bullet = true,
			},
		},
		heading = {
			border = false,
			backgrounds = {},
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
