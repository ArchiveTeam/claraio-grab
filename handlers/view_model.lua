local retry_common = require "Lib/retry_common"
local one_redirect = require "handlers/one_redirect"
local scene_info_full = require "handlers/scene_info_full"
local comments = require "handlers/comments"
local beta_player = require "handlers/beta_player"
local redirect_chain = require "handlers/redirect_chain"

local module = {}

module.download_child_p = function(urlpos, parent, depth, start_url_parsed, iri, verdict, reason)
	if string.match(urlpos["url"]["url"], "jpe?g/?$") then
		queue_request({url=urlpos["url"]["url"]}, one_redirect.make_one_redirect_handler(retry_common.only_retry_handler(10, {200})))
	end

	if string.match(urlpos["url"]["url"], "gravatar") then
		queue_request({url=urlpos["url"]["url"]}, redirect_chain.make_one_redirect_chain_handler(2))
	end
end

module.httploop_result = function(url, err, http_stat)
	local id = string.match(url["url"], "^https?://clara%.io/view/([a-f0-9%-]+)$")
	assert(id) -- Do this even if status code is weird
	local sc = http_stat["statcode"]
	if sc == 200 then
		queue_request({url="https://clara.io/api/scenes/" .. id .. "?shallow=true"}, retry_common.only_retry_handler(10, {200}))
		queue_request({url="https://clara.io/api/scenes/" .. id .. "?shallowCloneInfo=true"}, retry_common.only_retry_handler(10, {200}))
		queue_request({url="https://clara.io/library?derived=true&sceneId=" .. id}, "derived_from_first_page")
		queue_request({url="https://clara.io/api/scenes/" .. id .. "/comments?page=1&perPage=50"}, comments)
		queue_request({url="https://clara.io/api/scenes/" .. id .. "/thumbnail.jpg/"}, one_redirect.make_one_redirect_handler(retry_common.only_retry_handler(10, {200})))
		queue_request({url="https://clara.io/api/scenes/" .. id}, scene_info_full)
		queue_request({url="https://clara.io/player/v2/" .. id .. "?wait=true"}, beta_player)
		queue_request({url="https://clara.io/embed/" .. id .. "?renderer=gl"}, retry_common.only_retry_handler(10, {200})) -- This doesn't get a special handler because it is broken in the live site
	elseif sc == 404 then
		-- Nothing
	else
		retry_common.retry_unless_hit_iters(10)
	end
end

return module

