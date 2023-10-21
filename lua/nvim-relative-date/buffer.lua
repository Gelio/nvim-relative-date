local M = {}

local relative_date = require("nvim-relative-date.relative_date")

local namespace_id = vim.api.nvim_create_namespace("nvim-relative-date")

local iso_date_pattern = "(%d%d%d%d)%-(%d%d)%-(%d%d)"

---@param bufnr integer
---@param start_line integer 1-based, inclusive
---@param end_line integer 1-based, inclusive
---@param highlight_group string Name of the highlight group to use
---@param current_osdate osdate
function M.show_relative_dates_in_line_range(bufnr, start_line, end_line, highlight_group, current_osdate)
	vim.api.nvim_buf_clear_namespace(bufnr, namespace_id, start_line - 1, end_line)

	local visible_buffer_lines = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, true)

	vim.api.nvim_buf_clear_namespace(bufnr, namespace_id, start_line - 1, end_line)

	for line_index, line in ipairs(visible_buffer_lines) do
		local match_start_index = 1

		while true do
			-- 1-based, inclusive
			local start_column, end_column, year_str, month_str, day_str =
				line:find(iso_date_pattern, match_start_index)
			if start_column == nil or end_column == nil then
				break
			end

			match_start_index = start_column + 1

			local target_date = os.date("*t", os.time({ year = year_str, month = month_str, day = day_str })) --[[@as osdate]]

			local target_relative_date = relative_date.get_relative_date(current_osdate, target_date)

			if target_relative_date ~= nil then
				-- 0-based
				local line_nr = (start_line - 1) + (line_index - 1)
				vim.api.nvim_buf_set_extmark(bufnr, namespace_id, line_nr, end_column, {
					virt_text = {
						{ string.format(" (%s)", target_relative_date), highlight_group },
					},
					virt_text_pos = "inline",
				})
			end
		end
	end
end

return M
