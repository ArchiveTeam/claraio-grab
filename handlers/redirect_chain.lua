local urlparse = require("socket.url")
local retry_common = require "Lib/retry_common"

local module = {}

module.make_one_redirect_chain_handler = function(max_depth)
	local handler = {}
	handler.httploop_result = function(url, err, http_stat)
		local status_code = http_stat["statcode"]
		if status_code >= 300 and status_code < 400 then
			if max_depth == 0 then
				error("Max redirect depth reached")
			end
			local newloc = urlparse.absolute(url["url"], http_stat["newloc"])
			assert(newloc)
			queue_request({url=newloc}, module.make_one_redirect_chain_handler(max_depth - 1))
		elseif status_code >= 200 and status_code < 300 then
			-- Do nothing
		else
			retry_common.retry_unless_hit_iters(10)
		end
	end
	
	return handler
end


return module
