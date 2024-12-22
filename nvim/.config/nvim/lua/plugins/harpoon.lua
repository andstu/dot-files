return {
	"theprimeagen/harpoon",
	branch= "harpoon2",
	dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim", },
	opts = {
		settings = {
			save_on_toggle = true,
		},
	},
	keys = function ()
		local keys = {
			{
				"<leader>a",
				function ()
					require("harpoon"):list():add()
				end,
				desc = "Harpoon File",
			},
			{
				"<leader>A",
				function ()
					local harpoon = require("harpoon")
					harpoon.ui:toggle_quick_menu(harpoon:list())
				end,
				desc = "Harpoon Quick Menu",
			},
		}

		local file_keys = {"h","j","k","l",";"}

		for i = 1, 5 do
			table.insert(keys, {
				"<leader>" .. file_keys[i],
				function ()
					require("harpoon"):list():select(i)
				end,
				desc = "Harpoon to File " .. i,
			})
		end

		return keys
	end,

}
