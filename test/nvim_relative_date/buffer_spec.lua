local relative_date_buffer = require("nvim_relative_date.buffer")
local extmarks_utils = require("test.nvim_relative_date.relative_date_extmarks_utils")

describe("show_relative_dates_in_line_range", function()
	it("sets the extmarks for the dates in the line range", function()
		local lines, expected_extmarks = extmarks_utils.parse_test_text([[
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

		local extmarks = extmarks_utils.get_all_extmarks(bufnr)
		extmarks_utils.expect_extmarks_to_match(expected_extmarks, extmarks)

		-- NOTE: simulate some changes (the date in the first line changed)
		lines, expected_extmarks = extmarks_utils.parse_test_text([[
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

		extmarks = extmarks_utils.get_all_extmarks(bufnr)
		extmarks_utils.expect_extmarks_to_match(expected_extmarks, extmarks)
	end)
end)
