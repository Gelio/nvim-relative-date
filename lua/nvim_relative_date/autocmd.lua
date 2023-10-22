local M = {}

local augroup = vim.api.nvim_create_augroup("nvim_relative_date", {})

---@class nvim_relative_date.AutocmdSetupOpts
---@field filetypes string[]
---@field should_enable_buffer fun(bufnr: integer): boolean
---@field invalidate_buffer fun(bufnr: integer): nil
---@field debounced_invalidate_buffer fun(bufnr: integer): nil

---@param opts nvim_relative_date.AutocmdSetupOpts
function M.setup(opts)
	M.clear()

	vim.api.nvim_create_autocmd("FileType", {
		group = augroup,
		pattern = vim.fn.join(opts.filetypes, ","),
		callback = function(opt)
			local bufnr = opt.buf

			if opts.should_enable_buffer(bufnr) then
				M.enable_buffer({
					bufnr = bufnr,
					debounced_invalidate_buffer = opts.debounced_invalidate_buffer,
					invalidate_buffer = opts.invalidate_buffer,
				})
			end
		end,
	})
end

---@class nvim_relative_date.EnableBufferOpts
---@field bufnr integer
---@field invalidate_buffer fun(bufnr: integer): nil
---@field debounced_invalidate_buffer fun(bufnr: integer): nil

---@param opts nvim_relative_date.EnableBufferOpts
function M.enable_buffer(opts)
	opts.invalidate_buffer(opts.bufnr)

	-- TODO: use nvim_buf_attach (`on_lines`) to only invalidate the lines that changed
	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
		group = augroup,
		buffer = opts.bufnr,
		callback = function()
			opts.debounced_invalidate_buffer(opts.bufnr)
		end,
	})

	vim.api.nvim_create_autocmd("WinScrolled", {
		group = augroup,
		buffer = opts.bufnr,
		callback = function()
			-- TODO: update only the region of the window that was scrolled
			opts.debounced_invalidate_buffer(opts.bufnr)
		end,
	})
end

---@param bufnr integer
function M.disable_buffer(bufnr)
	vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
end

function M.clear()
	vim.api.nvim_clear_autocmds({ group = augroup })
end

return M
