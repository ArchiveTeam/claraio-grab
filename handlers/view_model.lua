local retry_common = require "Lib/retry_common"
local one_redirect = require "handlers/one_redirect"
local scene_info_full = require "handlers/scene_info_full"
local comments = require "handlers/comments"
local beta_player = require "handlers/beta_player"
local redirect_chain = require "handlers/redirect_chain"

local module = {}

module.download_child_p = function(urlpos, parent, depth, start_url_parsed, iri, verdict, reason)
	if string.match(urlpos["url"]["url"], "jpe?g/?$") then
		queue_request({url=urlpos["url"]["url"]}, one_redirect.make_one_redirect_handler(retry_common.only_retry_handler(10, {200}), true))
	end

	if string.match(urlpos["url"]["url"], "gravatar") then
		queue_request({url=urlpos["url"]["url"]}, redirect_chain.make_one_redirect_chain_handler(2, true))
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
		queue_request({url="https://clara.io/api/scenes/" .. id .. "/thumbnail.jpg/"}, one_redirect.make_one_redirect_handler(retry_common.only_retry_handler(10, {200, 404}), true))
		queue_request({url="https://clara.io/api/scenes/" .. id}, scene_info_full)
		queue_request({url="https://clara.io/player/v2/" .. id .. "?wait=true"}, beta_player)
		queue_request({url="https://clara.io/embed/" .. id .. "?renderer=gl"}, retry_common.only_retry_handler(10, {200})) -- This doesn't get a special handler because it is broken in the live site
		-- E.g. https://clara.io/view/c38534ff-483f-4fc2-8f0b-b8ea131a5fe8 - I can't determine when it is that these options are used so I'll just get a bit of possibly-extraneous HTML each model
		-- N.b. for future reference, the /render view is broken on the live site as of writing
		queue_request({url=url["url"] .. "/webgl"}, retry_common.only_retry_handler(10, {200}))
		queue_request({url=url["url"] .. "/render"}, retry_common.only_retry_handler(10, {200}))
		-- This is used by /render
		queue_request({url="https://clara.io/embed/" .. id .. "?renderer=vray&hideLogo=true&header=false"}, retry_common.only_retry_handler(10, {200}))
	elseif sc == 404 then
		-- Nothing
	else
		retry_common.retry_unless_hit_iters(10)
	end
end

module.write_to_warc = function(url, http_stat)
	local sc = http_stat["statcode"]
	return sc == 200 or sc == 404
end

return module

