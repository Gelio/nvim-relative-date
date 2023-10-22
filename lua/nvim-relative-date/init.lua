local M = {}

local timers = require("nvim-relative-date.timers")
local relative_date_buffer = require("nvim-relative-date.buffer")
local relative_date_autocmd = require("nvim-relative-date.autocmd")

-- TODO: allow enabling/disabling per buffer

local highlight_group = "Comment"
local debounce_ms = 100

---@param winid integer
---@return integer, integer
local function get_visible_window_lines_range(winid)
	return vim.fn.line("w0", winid), vim.fn.line("w$", winid)
end

local function show_relative_dates(bufnr)
	vim.print("Updating for", bufnr)
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
			highlight_group,
			current_osdate
		)
	end
end

---@type table<integer, (fun(bufid: integer): nil) | nil>
local debounced_update_buffer_map = {}

---@param bufid integer
local function debounced_show_relative_dates(bufid)
	vim.print("Debounced update for", bufid)
	local debounced_update_buffer = debounced_update_buffer_map[bufid]
	if debounced_update_buffer == nil then
		debounced_update_buffer = timers.debounce(show_relative_dates, debounce_ms)
		debounced_update_buffer_map[bufid] = debounced_update_buffer
	end

	debounced_update_buffer(bufid)
end

function M.setup()
	relative_date_autocmd.setup({
		filetypes = { "markdown" },
		should_enable_buffer = function(bufnr)
			return vim.bo[bufnr].buftype == ""
		end,
		invalidate_buffer = show_relative_dates,
		debounced_invalidate_buffer = debounced_show_relative_dates,
	})
end

return M
