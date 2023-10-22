local M = {}

local timers = require("nvim_relative_date.timers")
local relative_date_buffer = require("nvim_relative_date.buffer")
local relative_date_autocmd = require("nvim_relative_date.autocmd")

-- TODO: allow enabling/disabling per buffer

---@type nvim_relative_date.FullConfig
local current_config = nil

---@param winid integer
---@return integer, integer
local function get_visible_window_lines_range(winid)
	return vim.fn.line("w0", winid), vim.fn.line("w$", winid)
end

local function show_relative_dates(bufnr)
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return
	end

	local buf_winids = vim.fn.win_findbuf(bufnr)
	if #buf_winids == 0 then
		return
	end

	local current_osdate = os.date("*t") --[[@as osdate]]

	for _, winid in ipairs(buf_winids) do
		-- 1-based, inclusive
		local start_line, end_line = get_visible_window_lines_range(winid)

		relative_date_buffer.show_relative_dates_in_line_range(
			bufnr,
			start_line,
			end_line,
			current_config.highlight_group,
			current_osdate
		)
	end
end

---@type table<integer, (fun(bufid: integer): nil) | nil>
local debounced_update_buffer_map = {}

---@param bufid integer
local function debounced_show_relative_dates(bufid)
	local debounced_update_buffer = debounced_update_buffer_map[bufid]
	if debounced_update_buffer == nil then
		debounced_update_buffer = timers.debounce(show_relative_dates, current_config.debounce_ms)
		debounced_update_buffer_map[bufid] = debounced_update_buffer
	end

	debounced_update_buffer(bufid)
end

---@param config nvim_relative_date.Config?
function M.setup(config)
	current_config = vim.tbl_extend("force", require("nvim_relative_date.config").default, config or {})

	-- TODO: clear all extmarks in buffers and previous autocmds

	relative_date_autocmd.setup({
		filetypes = current_config.filetypes,
		should_enable_buffer = current_config.should_enable_buffer,
		invalidate_buffer = show_relative_dates,
		debounced_invalidate_buffer = debounced_show_relative_dates,
	})
end

return M