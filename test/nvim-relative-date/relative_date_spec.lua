local relative_date = require("nvim-relative-date.relative_date")

describe("get_relative_date", function()
	describe("when current date is in the middle of the year", function()
		local current_date = os.date("*t", os.time({ year = 2023, month = 10, day = 20 }))

		it("matches last Friday", function()
			local target_date = os.date("*t", os.time({ year = 2023, month = 10, day = 13 }))

			assert.are.equal("last Friday", relative_date.get_relative_date(current_date, target_date))
		end)

		it("matches next Sunday", function()
			local target_date = os.date("*t", os.time({ year = 2023, month = 10, day = 29 }))

			assert.are.equal("next Sunday", relative_date.get_relative_date(current_date, target_date))
		end)

		it("matches Sunday", function()
			local target_date = os.date("*t", os.time({ year = 2023, month = 10, day = 22 }))

			assert.are.equal("Sunday", relative_date.get_relative_date(current_date, target_date))
		end)

		it("matches last Sunday", function()
			local target_date = os.date("*t", os.time({ year = 2023, month = 10, day = 15 }))

			assert.are.equal("last Sunday", relative_date.get_relative_date(current_date, target_date))
		end)

		it("matches Monday", function()
			local target_date = os.date("*t", os.time({ year = 2023, month = 10, day = 16 }))

			assert.are.equal("Monday", relative_date.get_relative_date(current_date, target_date))
		end)

		it("matches today", function()
			assert.are.equal("today", relative_date.get_relative_date(current_date, current_date))
		end)

		it("matches tomorrow", function()
			local target_date = os.date("*t", os.time({ year = 2023, month = 10, day = 21 }))

			assert.are.equal("tomorrow", relative_date.get_relative_date(current_date, target_date))
		end)

		it("matches yesterday", function()
			local target_date = os.date("*t", os.time({ year = 2023, month = 10, day = 19 }))

			assert.are.equal("yesterday", relative_date.get_relative_date(current_date, target_date))
		end)

		it("does not match same date next year", function()
			local target_date = os.date("*t", os.time({ year = 2024, month = 10, day = 20 }))

			assert.are.equal(nil, relative_date.get_relative_date(current_date, target_date))
		end)
	end)

	describe("when current date is at the end of the year", function()
		local current_date = os.date("*t", os.time({ year = 2023, month = 12, day = 30 }))

		it("matches last Friday", function()
			local target_date = os.date("*t", os.time({ year = 2023, month = 12, day = 22 }))

			assert.are.equal("last Friday", relative_date.get_relative_date(current_date, target_date))
		end)

		it("matches next Sunday", function()
			local target_date = os.date("*t", os.time({ year = 2024, month = 1, day = 7 }))

			assert.are.equal("next Sunday", relative_date.get_relative_date(current_date, target_date))
		end)

		it("matches last Sunday", function()
			local target_date = os.date("*t", os.time({ year = 2023, month = 12, day = 24 }))

			assert.are.equal("last Sunday", relative_date.get_relative_date(current_date, target_date))
		end)

		it("matches Monday", function()
			local target_date = os.date("*t", os.time({ year = 2023, month = 12, day = 25 }))

			assert.are.equal("Monday", relative_date.get_relative_date(current_date, target_date))
		end)

		it("matches next Monday", function()
			local target_date = os.date("*t", os.time({ year = 2024, month = 1, day = 1 }))

			assert.are.equal("next Monday", relative_date.get_relative_date(current_date, target_date))
		end)

		it("matches tomorrow", function()
			local target_date = os.date("*t", os.time({ year = 2023, month = 12, day = 31 }))

			assert.are.equal("tomorrow", relative_date.get_relative_date(current_date, target_date))
		end)

		it("matches yesterday", function()
			local target_date = os.date("*t", os.time({ year = 2023, month = 12, day = 29 }))

			assert.are.equal("yesterday", relative_date.get_relative_date(current_date, target_date))
		end)
	end)
end)
