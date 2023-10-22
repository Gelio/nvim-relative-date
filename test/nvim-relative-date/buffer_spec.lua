local relative_date_buffer = require("nvim-relative-date.buffer")

local text_relative_date_line_prefix = "RD:"
local extmark_text_pattern = " %(%a+%)"

---@class RelativeDateExtmark
---@field line integer 0-based
---@field column integer 0-based
---@field text string

---@param test_text string
local function parse_test_text(test_text)
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
local function expect_extmarks_to_match(expected_extmarks, extmarks)
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

describe("show_relative_dates_in_line_range", function()
	it("sets the extmarks for the dates in the line range", function()
		local lines, expected_extmarks = parse_test_text([[
      Hello, today is 2023-10-22 and I am working
RD:                              (today)
      on nvim-relative-date, which is a super cool
      project I started 2023-10-21.
RD:                                (yesterday)
      I hope to finish it by 2024-01-01


      Last Monday was 2023-10-09
      and tomorrow is 2023-10-23
    ]])
		local bufnr = vim.api.nvim_create_buf(true, false)
		vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, lines)

		local highlight_group = "Red"
		local current_osdate = os.date("*t", os.time({ year = 2023, month = 10, day = 22 })) --[[@as osdate]]

		relative_date_buffer.show_relative_dates_in_line_range(
			bufnr,
			1,
			-- NOTE: only show the relative dates in the first paragraph
			4,
			highlight_group,
			current_osdate
		)

		local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, -1, 0, -1, { details = true })
		expect_extmarks_to_match(expected_extmarks, extmarks)

		-- NOTE: simulate some changes (the date in the first line changed)
		lines, expected_extmarks = parse_test_text([[
      Hello, today is 2023-09-22 and I am working
      on nvim-relative-date, which is a super cool
      project I started 2023-10-21.
RD:                                (yesterday)
      I hope to finish it by 2024-01-01


      Last Monday was 2023-10-09
      and tomorrow is 2023-10-23
    ]])
		vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, lines)

		relative_date_buffer.show_relative_dates_in_line_range(
			bufnr,
			1,
			-- NOTE: only show the relative dates in the first paragraph
			4,
			highlight_group,
			current_osdate
		)

		extmarks = vim.api.nvim_buf_get_extmarks(bufnr, -1, 0, -1, { details = true })
		expect_extmarks_to_match(expected_extmarks, extmarks)
	end)
end)
