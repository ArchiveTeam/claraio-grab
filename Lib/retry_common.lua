local retry_common = {}
local socket = require "socket"



retry_common.retry_unless_hit_iters = function(max)
	local new_options = deep_copy(current_options)
	local cur_try = new_options["try"] or 1
	assert(cur_try <= max, "Giving up due to too many retries...") -- Stupid way to fail when it gives up
	new_options["try"] = cur_try + 1
	new_options["delay_until"] = socket.gettime() + 2^(cur_try + 1)
	queue_request(new_options, current_handler)
end

retry_common.only_retry_handler = function(max, allowed_status_codes)
	local handler = {}
	local allowed_sc_lookup = {}
	for _, v in pairs(allowed_status_codes) do
		allowed_sc_lookup[v] = true
	end
	handler.httploop_result = function(url, err, http_stat)
		if not allowed_sc_lookup[http_stat["statcode"]] then
			retry_common.retry_unless_hit_iters(max)
		end
	end
	return handler
end

return retry_common
