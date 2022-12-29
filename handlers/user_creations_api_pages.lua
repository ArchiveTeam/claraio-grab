local JSON = require 'Lib/JSON'
local retry_common = require "Lib/retry_common"

local module = {}

local cur_stat_code = nil

module.get_urls = function(file, url, is_css, iri)
	if cur_stat_code == 200 then
		local username = string.match(url, "^https://clara%.io/api/users/([^/]+)/scenes%?page=[0-9]+&perPage=24&type=gallery$")
		local page = string.match(url, "^https://clara%.io/api/users/[^/]+/scenes%?page=([0-9]+)&perPage=24&type=gallery$")
		assert(username)
		assert(page)
		
		queue_request({url="https://clara.io/api/users/" .. username}, retry_common.only_retry_handler(10, {200}))
		queue_request({url="https://clara.io/api/users/" .. username .. "/scenes?page=1&perPage=24&type=gallery"}, "user_creations_api_pages")
		
		-- Interface page
		queue_request({url="https://clara.io/user/" .. username .. "?page=" .. page .. "&perPage=24"}, retry_common.only_retry_handler(10, {200}))
		
		
		local res = JSON:decode(get_body())
		for _, model in pairs(res["models"]) do
			queue_request({url="https://clara.io/view/" .. model["_id"]}, "view_model", true)
		end
		
		if res["page"] * 24 < res["total"] then
			queue_request({url="https://clara.io/api/users/" .. username .. "/scenes?page=" .. tostring(tonumber(page) + 1) .. "&perPage=24&type=gallery"}, current_handler)
		end
	end
end

module.httploop_result = function(url, err, http_stat)
	cur_stat_code = http_stat["statcode"]
	if cur_stat_code ~= 200 and cur_stat_code ~= 404 then
		retry_common.retry_unless_hit_iters(10)
	end
end


return module
