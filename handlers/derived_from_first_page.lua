local retry_common = require "Lib/retry_common"
require "Lib/utils"
require "Lib/table_show"

local module = {}

local cur_stat_code = nil


module.get_urls = function(file, url, is_css, iri)
	if cur_stat_code == 200 then
		local id = string.match(url, "^https?://clara%.io/library%?derived=true&sceneId=([a-f0-9%-]+)")
		assert(id)
		-- Now just queue API pages
		queue_request({url="https://clara.io/api/scenes?derived=true&sceneId=" .. id .. "&page=1&perPage=24&type=library"}, "derived_from_API_pages")
		-- Also queue this thing that gets called from the normal view page
		queue_request({url="https://clara.io/api/scenes?page=1&perPage=24&type=library&derived=true&sceneId=" .. id .. "&sort=-viewCount"}, retry_common.only_retry_handler(10, {200}))
	end
end

module.httploop_result = function(url, err, http_stat)
	cur_stat_code = http_stat["statcode"]
	if cur_stat_code ~= 200 then
		retry_common.retry_unless_hit_iters(10)
	end
end


return module
