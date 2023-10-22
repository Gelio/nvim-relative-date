local M = {}

---In Lua, wday=1 is Sunday
---@see https://www.lua.org/pil/22.1.html
local weekdays = {
	"Sunday",
	"Monday",
	"Tuesday",
	"Wednesday",
	"Thursday",
	"Friday",
	"Saturday",
}

---@param current_date osdate
---@param target_date osdate
---@return string | nil
function M.get_relative_date(current_date, target_date)
	if math.abs(current_date.year - target_date.year) > 1 then
		-- Relative dates are meaningful when there is at most 1 year difference
		-- (when both dates are close to the year boundary).
		-- Otherwise, there is no chance those dates will be different.
		return nil
	end

	local smaller_year = current_date.year
	if current_date.year > target_date.year then
		smaller_year = target_date.year
	end

	local smaller_year_ydays = os.date("*t", os.time({ year = smaller_year, month = 12, day = 31 })).yday

	local current_yday = current_date.yday + (current_date.year - smaller_year) * smaller_year_ydays
	local target_yday = target_date.yday + (target_date.year - smaller_year) * smaller_year_ydays

	if current_yday == target_yday then
		return "today"
	elseif current_yday + 1 == target_yday then
		return "tomorrow"
	elseif current_yday - 1 == target_yday then
		return "yesterday"
	end

	local beginning_of_current_week_yday = current_yday - (current_date.wday - 1)
	if beginning_of_current_week_yday - 7 > target_yday then
		-- Earlier than last week
		return nil
	elseif beginning_of_current_week_yday >= target_yday then
		return "last " .. weekdays[target_date.wday]
	elseif beginning_of_current_week_yday + 7 >= target_yday then
		return weekdays[target_date.wday]
	elseif beginning_of_current_week_yday + 14 >= target_yday then
		return "next " .. weekdays[target_date.wday]
	end

	return nil
end

return M
