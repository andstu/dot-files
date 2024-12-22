--[[
Make sure you have these plugins installed:
* neovim/nvim-lspconfig
* williamboman/mason.nvim
* williamboman/mason-lspconfig.nvim
* hrsh7th/nvim-cmp
* hrsh7th/cmp-nvim-lsp
* L3MON4D3/LuaSnip
]]

local cmp = require('cmp')

cmp.setup({
	sources = {
		{name = 'path'},
		{name = 'nvim_lsp'},
		{name = 'luasnip', keyword_length = 2},
		{name = 'buffer', keyword_length = 3},
	},
	snippet = {
		expand = function(args)
			require('luasnip').lsp_expand(args.body)
		end,
	},
	formatting = {
		fields = {'abbr', 'menu', 'kind'},
		format = function(entry, item)
			local n = entry.source.name
			if n == 'nvim_lsp' then
				item.menu = '[LSP]'
			else
				item.menu = string.format('[%s]', n)
			end
			return item
		end,
	},
	mapping = cmp.mapping.preset.insert({
		-- confirm completion item
		['<Enter>'] = cmp.mapping.confirm({ select = true }),

		-- trigger completion menu
		['<C-Space>'] = cmp.mapping.complete(),

		-- scroll up and down the documentation window
		['<C-u>'] = cmp.mapping.scroll_docs(-4),
		['<C-d>'] = cmp.mapping.scroll_docs(4),

		-- jump to the next snippet placeholder
		['<C-f>'] = cmp.mapping(function(fallback)
			local luasnip = require('luasnip')
			if luasnip.locally_jumpable(1) then
				luasnip.jump(1)
			else
				fallback()
			end
		end, {'i', 's'}),

		-- jump to the previous snippet placeholder
		['<C-b>'] = cmp.mapping(function(fallback)
			local luasnip = require('luasnip')
			if luasnip.locally_jumpable(-1) then
				luasnip.jump(-1)
			else
				fallback()
			end
		end, {'i', 's'}),
	}),
})

-- Reserve a space in the gutter
-- This will avoid an annoying layout shift in the screen
vim.opt.signcolumn = 'yes'

-- Add borders to floating windows
vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(
vim.lsp.handlers.hover,
{border = 'rounded'}
)
vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(
vim.lsp.handlers.signature_help,
{border = 'rounded'}
)

-- Add cmp_nvim_lsp capabilities settings to lspconfig
-- This should be executed before you configure any language server
local lspconfig_defaults = require('lspconfig').util.default_config
lspconfig_defaults.capabilities = vim.tbl_deep_extend(
'force',
lspconfig_defaults.capabilities,
require('cmp_nvim_lsp').default_capabilities()
)

-- This is where you enable features that only work
-- if there is a language server active in the file
vim.api.nvim_create_autocmd('LspAttach', {
	callback = function(event)
		local opts = {buffer = event.buf}

		vim.keymap.set('n', 'K', '<cmd>lua vim.lsp.buf.hover()<cr>', opts)
		vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>', opts)
		vim.keymap.set('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<cr>', opts)
		vim.keymap.set('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<cr>', opts)
		vim.keymap.set('n', 'go', '<cmd>lua vim.lsp.buf.type_definition()<cr>', opts)
		vim.keymap.set('n', 'gr', '<cmd>lua vim.lsp.buf.references()<cr>', opts)
		vim.keymap.set('n', 'gs', '<cmd>lua vim.lsp.buf.signature_help()<cr>', opts)
		vim.keymap.set('n', 'gl', '<cmd>lua vim.diagnostic.open_float()<cr>', opts)
		vim.keymap.set('n', '<F2>', '<cmd>lua vim.lsp.buf.rename()<cr>', opts)
		vim.keymap.set({'n', 'x'}, '<F3>', '<cmd>lua vim.lsp.buf.format({async = true})<cr>', opts)
		vim.keymap.set('n', '<F4>', '<cmd>lua vim.lsp.buf.code_action()<cr>', opts)
	end,
})

require('mason').setup({})
require('mason-lspconfig').setup({
	ensure_installed = {'lua_ls', 'texlab', 'marksman', 'pyright', 'tflint', 'hydra_lsp', 'taplo', 'gopls'},
	handlers = {
		-- this first function is the "default handler"
		-- it applies to every language server without a custom handler
		function(server_name)
			require('lspconfig')[server_name].setup({})
		end,

		--ruff = function()
			--require('lspconfig').ruff.setup({
				--trace = 'messages',
				--init_options = {
					--settings = {
						--logLevel = 'debug',
					--}
				--}
			--})
		--end,

		-- this is the "custom handler" for `lua_ls`
		lua_ls = function()
			require('lspconfig').lua_ls.setup({
				settings = {
					Lua = {
						runtime = {
							version = 'LuaJIT',
						},
						diagnostics = {
							globals = {'vim'},
						},
						workspace = {
							library = {vim.env.VIMRUNTIME},
						},
					},
				},
			})
		end,
	},
})
