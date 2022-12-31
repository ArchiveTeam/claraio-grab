local JSON = require 'Lib/JSON'
local retry_common = require "Lib/retry_common"

local module = {}

local cur_stat_code = nil

module.get_urls = function(file, url, is_css, iri)
	if cur_stat_code == 200 then
		local res = JSON:decode(get_body())
		if #res > 49 then
			error(">50 comments is not supported as I cannot find an example. If you see this please report it." .. url["url"])
		end
		
		for _, comm in pairs(res) do
			queue_request({url="https://clara.io/user/" .. comm["owner"]}, "user", true)
		end
	end
end

module.httploop_result = function(url, err, http_stat)
	cur_stat_code = http_stat["statcode"]
	if cur_stat_code ~= 200 then
		retry_common.retry_unless_hit_iters(10)
	end
end

module.write_to_warc = function(url, http_stat)
	local sc = http_stat["statcode"]
	return sc == 200
end

return module
