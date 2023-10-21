local M = {}

---Returns a function that matches the signature of `callback`.
---When called, schedules a timer that calls `callback` after `duration`
---milliseconds.
---During that time, if the function is called again, the timer is reset, and
---it starts counting `duration` milliseconds from scratch.
---
---@param callback fun(...: unknown[]): unknown
---@param duration_ms integer Number of milliseconds after which to call the `callback`
function M.debounce(callback, duration_ms)
	local latest_args = nil
	local timer = nil

	return function(...)
		latest_args = { ... }

		if timer ~= nil then
			vim.uv.timer_stop(timer)
		else
			timer = vim.uv.new_timer()
		end

		vim.uv.timer_start(timer, duration_ms, 0, function()
			vim.uv.close(timer)
			timer = nil
			vim.schedule_wrap(callback)(unpack(latest_args))
		end)
	end
end

return M
