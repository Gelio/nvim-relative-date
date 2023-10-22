local extmarks_utils = require("test.nvim-relative-date.relative_date_extmarks_utils")
local nvim_relative_date = require("nvim-relative-date")
local nvim_relative_date_autocmd = require("nvim-relative-date.autocmd")
local async_util = require("plenary.async.util")
local async_tests = require("plenary.async.tests")

local function get_test_text()
	local today_osdate = os.date("*t") --[[@as osdate]]
	local today = os.date("%Y-%m-%d")
	local yesterday = os.date(
		"%Y-%m-%d",
		os.time({ year = today_osdate.year, month = today_osdate.month, day = today_osdate.day - 1 })
	)
	local next_year = os.date(
		"%Y-%m-%d",
		os.time({ year = today_osdate.year + 1, month = today_osdate.month, day = today_osdate.day })
	)

	local test_text = string.format(
		[[
Hello, today is %s and I am working
RD:             %s (today)
on nvim-relative-date, which is a super cool
project I started %s.
RD:               %s (yesterday)
I hope to finish it by %s
]],
		today,
		today,
		yesterday,
		yesterday,
		next_year
	)

	return test_text
end

describe("updates extmarks after a delay", function()
	async_tests.it("when modifying the buffer", function()
		nvim_relative_date.setup()

		local bufnr = vim.api.nvim_create_buf(true, false)
		vim.bo[bufnr].filetype = "markdown"

		vim.api.nvim_win_set_buf(0, bufnr)
		vim.api.nvim_win_set_height(0, 10)

		assert.are.equal(0, #extmarks_utils.get_all_extmarks(bufnr))

		local lines, expected_extmarks = extmarks_utils.parse_test_text(get_test_text())

		vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, lines)
		vim.cmd.doautocmd("TextChanged")

		assert.are.equal(0, #extmarks_utils.get_all_extmarks(bufnr))

		async_util.sleep(300)

		extmarks_utils.expect_extmarks_to_match(expected_extmarks, extmarks_utils.get_all_extmarks(bufnr))
	end)

	async_tests.it("when scrolling", function()
		nvim_relative_date.setup()

		local bufnr = vim.api.nvim_create_buf(true, false)
		vim.bo[bufnr].filetype = "markdown"

		vim.api.nvim_win_set_buf(0, bufnr)
		vim.api.nvim_win_set_height(0, 1)

		assert.are.equal(0, #extmarks_utils.get_all_extmarks(bufnr))

		local lines, expected_extmarks = extmarks_utils.parse_test_text(get_test_text())

		vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, lines)
		vim.cmd.doautocmd("WinScrolled")

		assert.are.equal(0, #extmarks_utils.get_all_extmarks(bufnr))

		async_util.sleep(300)

		extmarks_utils.expect_extmarks_to_match({
			-- NOTE: only the extmark on the first line should be visible, since the
			-- window is only 1-line high
			expected_extmarks[1],
		}, extmarks_utils.get_all_extmarks(bufnr))

		vim.api.nvim_win_set_height(0, 10)
		vim.cmd.doautocmd("WinScrolled")

		async_util.sleep(300)

		extmarks_utils.expect_extmarks_to_match(expected_extmarks, extmarks_utils.get_all_extmarks(bufnr))
	end)
end)

async_tests.it("only updates the buffers that were changed", function()
	nvim_relative_date.setup()

	local js_bufnr = vim.api.nvim_create_buf(true, false)
	vim.bo[js_bufnr].filetype = "javascript"

	vim.api.nvim_win_set_buf(0, js_bufnr)
	local js_winid = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_height(js_winid, 10)

	local markdown_bufnr = vim.api.nvim_create_buf(true, false)
	vim.bo[markdown_bufnr].filetype = "markdown"

	vim.cmd("split")
	local markdown_winid = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(markdown_winid, markdown_bufnr)

	local lines, expected_extmarks = extmarks_utils.parse_test_text(get_test_text())

	-- PART: dates should not be detected in neither buffer after modifying only
	-- the js buffer
	vim.api.nvim_set_current_win(js_winid)
	vim.api.nvim_buf_set_lines(js_bufnr, 0, -1, true, lines)
	vim.cmd.doautocmd("TextChanged")

	async_util.sleep(300)

	-- NOTE: js buffers are not enabled automatically
	assert.are.equal(0, #extmarks_utils.get_all_extmarks(js_bufnr))
	-- NOTE: markdown buffer has not been changed yet
	assert.are.equal(0, #extmarks_utils.get_all_extmarks(markdown_bufnr))

	-- PART: dates are detected in the markdown buffer
	vim.api.nvim_set_current_win(markdown_winid)
	vim.api.nvim_buf_set_lines(markdown_bufnr, 0, -1, true, lines)
	vim.cmd.doautocmd("TextChanged")

	async_util.sleep(300)

	-- NOTE: js buffers are not enabled automatically
	assert.are.equal(0, #extmarks_utils.get_all_extmarks(js_bufnr))
	-- NOTE: markdown buffer has not been changed yet
	extmarks_utils.expect_extmarks_to_match(expected_extmarks, extmarks_utils.get_all_extmarks(markdown_bufnr))

	-- PART: plugin is turned off after disabling it for a given buffer
	-- TODO: make sure disabling the plugin in a buffer automatically clears
	-- every extmark in the buffer
	vim.api.nvim_buf_set_lines(markdown_bufnr, 0, -1, true, {})
	vim.cmd.doautocmd("TextChanged")
	async_util.sleep(300)

	nvim_relative_date_autocmd.disable_buffer(markdown_bufnr)
	vim.api.nvim_buf_set_lines(markdown_bufnr, 0, -1, true, lines)
	vim.cmd.doautocmd("TextChanged")

	async_util.sleep(300)

	-- NOTE: js buffers are not enabled automatically
	assert.are.equal(0, #extmarks_utils.get_all_extmarks(js_bufnr))
	-- NOTE: the plugin is disabled in the markdown buffer
	assert.are.equal(0, #extmarks_utils.get_all_extmarks(markdown_bufnr))
end)
