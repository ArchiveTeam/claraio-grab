--require "strict"

local module = {}


local old_queue_request = queue_request
queue_request = function(options, handler, backfeed)
	if options["url"] ~= "https://i1.wp.com/clara.io/img/default_avatar.png?ssl=1" then
		old_queue_request(options, handler, backfeed)
	end
end


return module
