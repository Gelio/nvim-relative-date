local M = {}

local augroup = vim.api.nvim_create_augroup("nvim-relative-date", {})
local enabled_bufscoped_variable_name = "nvim-relative-date-enabled"

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

	-- TODO: see if this can be replaced by registering a buffer-local WinScrolled autocmd
	vim.api.nvim_create_autocmd("WinScrolled", {
		group = augroup,
		callback = function(opt)
			local bufnr = opt.buf

			-- TODO: update only the region of the window that was scrolled

			if vim.b[bufnr][enabled_bufscoped_variable_name] then
				opts.debounced_invalidate_buffer(bufnr)
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
	vim.b[opts.bufnr][enabled_bufscoped_variable_name] = true
	opts.invalidate_buffer(opts.bufnr)

	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
		group = augroup,
		buffer = opts.bufnr,
		callback = function()
			opts.debounced_invalidate_buffer(opts.bufnr)
		end,
	})
end

---@param bufnr integer
function M.disable_buffer(bufnr)
	vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
	vim.b[bufnr][enabled_bufscoped_variable_name] = false
end

function M.clear()
	vim.api.nvim_clear_autocmds({ group = augroup })

	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_valid(bufnr) then
			-- NOTE: we do not use `M.disable_buffer` because it would repeatedly
			-- clear autocmds for each buffer individually, which is already handled
			-- by removing ALL autocmds at the beginning of `M.clear`
			vim.b[bufnr][enabled_bufscoped_variable_name] = false
		end
	end
end

return M
