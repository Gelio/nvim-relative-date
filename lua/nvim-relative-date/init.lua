local M = {}

-- TODO: allow enabling/disabling per buffer

local namespace_id = vim.api.nvim_create_namespace("nvim-relative-date")
local highlight_group = "Comment"

---@param winid integer
---@return integer, integer
local function get_visible_window_lines_range(winid)
	return vim.fn.line("w0", winid), vim.fn.line("w$", winid)
end

local iso_date_pattern = "%d%d%d%d%-%d%d%-%d%d"

local function show_relative_dates(bufnr)
	vim.api.nvim_buf_clear_namespace(bufnr, namespace_id, 0, -1)

	local buf_winids = vim.fn.win_findbuf(bufnr)
	if #buf_winids == 0 then
		return
	end

	for _, winid in ipairs(buf_winids) do
		-- 1-based, inclusive
		local start_line, end_line = get_visible_window_lines_range(winid)
		local visible_buffer_lines = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, true)

		vim.api.nvim_buf_clear_namespace(bufnr, namespace_id, start_line - 1, end_line)

		for line_index, line in ipairs(visible_buffer_lines) do
			local match_start_index = 1

			while true do
				-- 1-based, inclusive
				local start_column, end_column = line:find(iso_date_pattern, match_start_index)
				if start_column == nil or end_column == nil then
					break
				end

				match_start_index = start_column + 1

				local matched_iso_date = line:sub(start_column, end_column)

				local line_nr = (start_line - 1) + (line_index - 1)
				vim.api.nvim_buf_set_extmark(bufnr, namespace_id, line_nr, end_column, {
					virt_text = {
						-- TODO: parse the date and say whether it is relative
						{ string.format(" hey %s ", matched_iso_date), highlight_group },
					},
					virt_text_pos = "inline",
				})
			end
		end
	end
end

function M.setup()
	local augroup = vim.api.nvim_create_augroup("nvim-relative-date", {})

	vim.api.nvim_create_autocmd({ "BufWinEnter", "WinScrolled", "TextChanged", "TextChangedI" }, {
		callback = function(event)
			-- TODO: debounce
			show_relative_dates(event.buf)
		end,
		pattern = "*",
		group = augroup,
	})
end

return M
