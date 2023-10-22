local M = {}

local text_relative_date_line_prefix = "RD:"
local extmark_text_pattern = " %(%a+%)"

---@class RelativeDateExtmark
---@field line integer 0-based
---@field column integer 0-based
---@field text string

---@param test_text string
function M.parse_test_text(test_text)
	---@type string[]
	local lines = vim.fn.split(test_text, "\n")

	---@type string[]
	local text_lines = {}
	---@type RelativeDateExtmark[]
	local expected_extmarks = {}

	for _, line in ipairs(lines) do
		if not vim.startswith(line, text_relative_date_line_prefix) then
			table.insert(text_lines, line)
		else
			local find_start_index = text_relative_date_line_prefix:len()
			while true do
				local start_index, end_index = string.find(line, extmark_text_pattern, find_start_index)
				if start_index == nil then
					break
				end
				find_start_index = start_index + 1

				---@type RelativeDateExtmark
				local extmark = {
					line = #text_lines - 1,
					column = start_index - 1,
					text = line:sub(start_index, end_index),
				}
				table.insert(expected_extmarks, extmark)
			end
		end
	end

	return text_lines, expected_extmarks
end

---@param expected_extmarks RelativeDateExtmark[]
---@param extmarks table[]
function M.expect_extmarks_to_match(expected_extmarks, extmarks)
	assert.are.same(
		expected_extmarks,
		vim.tbl_map(function(extmark)
			---@type RelativeDateExtmark
			return {
				line = extmark[2],
				column = extmark[3],
				text = extmark[4].virt_text[1][1],
			}
		end, extmarks)
	)
end

---@param bufnr integer
---@return unknown[]
function M.get_all_extmarks(bufnr)
	return vim.api.nvim_buf_get_extmarks(bufnr, -1, 0, -1, { details = true })
end

return M
