local JSON = require 'Lib/JSON'
local retry_common = require "Lib/retry_common"
require "Lib/utils"

local module = {}

local cur_stat_code = nil


module.get_urls = function(file, url, is_css, iri)
	if cur_stat_code == 200 then
		local res = JSON:decode(get_body())
		for _, v in pairs(res["files"]) do
			queue_request({url="https://clara.io/resources/" .. v["hash"] .. v["suffix"] .. "?filename=" .. minimal_escape(v["name"])}, retry_common.only_retry_handler(10, {200}))
			-- These will be identical to the ["hash"]-derived one
			for _, hash_type in pairs({"sha1", "md5"}) do
				if v[hash_type] then
					queue_request({url="https://clara.io/resources/" .. v[hash_type] .. v["suffix"] .. "?filename=" .. minimal_escape(v["name"])}, retry_common.only_retry_handler(10, {200, 404}))
				end
			end
			queue_request({url="https://clara.io/resources/" .. v["hash"] .. "lzma1" .. "?filename=" .. minimal_escape(v["name"])}, retry_common.only_retry_handler(10, {200, 404})) -- I cannot be bothered to write a parser for the thing that determines whether these are present, hence why 404 is allowd.
		end
		
		for _, v in pairs(res["thumbnails"]) do
			if v["hash"] and v["hash"] ~= "ok" then
				queue_request({url="https://clara.io/resources/" .. v["hash"]}, retry_common.only_retry_handler(10, {200, 504}))
			end
		end
		
		-- Now the uploading user
		queue_request({url="https://clara.io/user/" .. res["owner"]}, "user", true)
		
		-- And the parent submission, if it exists
		if res["cloneOf"] then
			queue_request({url="https://clara.io/view/" .. res["cloneOf"]}, "view_model", true)
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
