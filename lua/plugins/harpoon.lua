return {
	"ThePrimeagen/harpoon",
	branch = "harpoon2",
	dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
	config = function()
		local harpoon = require("harpoon")
		harpoon:setup()

		local conf = require("telescope.config").values
		local function toggle_telescope(harpoon_files)
			local file_paths = {}
			for _, item in ipairs(harpoon_files.items) do
				table.insert(file_paths, item.value)
			end
			require("telescope.pickers")
				.new({}, {
					prompt_title = "Harpoon",
					finder = require("telescope.finders").new_table({ results = file_paths }),
					previewer = conf.file_previewer({}),
					sorter = conf.generic_sorter({}),
				})
				:find()
		end

		vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end, { desc = "Harpoon add file" })
		vim.keymap.set("n", "<leader>hr", function() harpoon:list():remove() end, { desc = "Harpoon remove file" })
		vim.keymap.set("n", "<C-e>", function() toggle_telescope(harpoon:list()) end, { desc = "Harpoon menu" })

		vim.keymap.set("n", "<C-j>", function() harpoon:list():select(1) end, { desc = "Harpoon file 1" })
		vim.keymap.set("n", "<C-k>", function() harpoon:list():select(2) end, { desc = "Harpoon file 2" })
		vim.keymap.set("n", "<C-l>", function() harpoon:list():select(3) end, { desc = "Harpoon file 3" })
		vim.keymap.set("n", "<C-;>", function() harpoon:list():select(4) end, { desc = "Harpoon file 4" })

		vim.keymap.set("n", "<C-S-J>", function() harpoon:list():prev() end, { desc = "Harpoon prev" })
		vim.keymap.set("n", "<C-S-K>", function() harpoon:list():next() end, { desc = "Harpoon next" })
	end,
}
