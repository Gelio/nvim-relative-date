local M = {}

---@param current_date osdateparam
---@param target_date osdateparam
---@return string | nil
function M.get_relative_date(current_date, target_date)
	if current_date.yday == target_date.yday then
		return "today"
	elseif current_date.yday + 1 == target_date.yday then
		return "tomorrow"
	elseif current_date.yday - 1 == target_date.yday then
		return "yesterday"
	end

	return nil
end

return M
