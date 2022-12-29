local retry_common = require "Lib/retry_common"
require "Lib/utils"
local JSON = require 'Lib/JSON'

local module = {}

local cur_stat_code = nil

-- URLs like https://clara.io/api/scenes?derived=true&sceneId=2c296545-1204-4fc3-b470-c39bec65e86c&page=3&perPage=24&type=library


module.get_urls = function(file, url, is_css, iri)
	if cur_stat_code == 200 then
		
		local id = string.match(url, "^https?://clara%.io/api/scenes%?derived=true&sceneId=([a-f0-9%-]+)&page=[0-9]+&perPage=24&type=library")
		local page = string.match(url, "^https?://clara%.io/api/scenes%?derived=true&sceneId=[a-f0-9%-]+&page=([0-9]+)&perPage=24&type=library")
		assert(id)
		assert(page)
		
		-- Queue the interface page
		queue_request({url="https://clara.io/library?derived=true&sceneId=" .. id .. "&page=" .. page .. "&perPage=24"}, retry_common.only_retry_handler(10, {200}))
		
		
		local res = JSON:decode(get_body())
		for _, model in pairs(res["models"]) do
			queue_request({url="https://clara.io/view/" .. model["_id"]}, "view_model", true)
		end
		
		if res["page"] * 24 < res["total"] then
			queue_request({url="https://clara.io/api/scenes?derived=true&sceneId=" .. id .. "&page=" .. tostring(tonumber(page) + 1) .. "&perPage=24&type=library"}, current_handler)
		end
	end
end

module.httploop_result = function(url, err, http_stat)
	cur_stat_code = http_stat["statcode"]
	if cur_stat_code ~= 200 then
		retry_common.retry_unless_hit_iters(10)
	end
end


return module
