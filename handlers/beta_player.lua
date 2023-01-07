local JSON = require 'Lib/JSON'
local retry_common = require "Lib/retry_common"

local module = {}

local cur_stat_code = nil

module.get_urls = function(file, url, is_css, iri)
	if cur_stat_code == 200 then
		local res = string.match(get_body(), "xhr%.open%('GET', '(https://clara.io/resources/[a-f0-9]+)'")
		assert(res)
		queue_request({url=res}, retry_common.only_retry_handler(10, {200}))
	end
end

module.httploop_result = function(url, err, http_stat)
	cur_stat_code = http_stat["statcode"]
	if cur_stat_code ~= 200 then
		retry_common.retry_unless_hit_iters(3, true)
	end
end


module.write_to_warc = function(url, http_stat)
	local sc = http_stat["statcode"]
	return sc == 200
end



return module
