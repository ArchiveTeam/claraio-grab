local JSON = require 'Lib/JSON'
local retry_common = require "Lib/retry_common"
local redirect_chain = require "handlers/redirect_chain"

local module = {}

local cur_stat_code = nil

module.download_child_p = function(urlpos, parent, depth, start_url_parsed, iri, verdict, reason)
	if string.match(urlpos["url"]["url"], "gravatar") then
		queue_request({url=urlpos["url"]["url"]}, redirect_chain.make_one_redirect_chain_handler(2))
	end
end

module.get_urls = function(file, url, is_css, iri)
	if cur_stat_code == 200 then
		local username = string.match(url, "^https?://clara%.io/user/([^/%?]+)$")
		assert(username)
		queue_request({url="https://clara.io/api/users/" .. username}, retry_common.only_retry_handler(10, {200}))
		queue_request({url="https://clara.io/api/users/" .. username .. "/scenes?page=1&perPage=24&type=gallery"}, "user_creations_api_pages")
	end
end

module.httploop_result = function(url, err, http_stat)
	cur_stat_code = http_stat["statcode"]
	if cur_stat_code ~= 200 and cur_stat_code ~= 404 then
		retry_common.retry_unless_hit_iters(10)
	end
end

module.write_to_warc = function(url, http_stat)
	local sc = http_stat["statcode"]
	return sc == 200 or sc == 404
end


return module
