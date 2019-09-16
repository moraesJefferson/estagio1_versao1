-- Puff visual effect
-- Puff can be either white when a ball, a block or a bug dies, or it can act as an explosion visualisation.

local _M = {}

local specs = {
	{w = 191, h = 180}
}

function _M.newPuff(params)
	local puff = display.newImageRect(params.g, 'image/personagens/fumaca.png', specs[1].w, specs[1].h)
	puff.x, puff.y = params.x, params.y
	local fromScale, toScale = math.random(0.1, 0.2), math.random(2, 3)
	puff:scale(fromScale, fromScale)

	if params.isExplosion then
		puff:setFillColor(1, 0.9, 0.5)
	end

	transition.to(puff, {time = math.random(200, 400), xScale = toScale, yScale = toScale, alpha = 0, onComplete = function(object)
		object:removeSelf()
	end})

	return puff
end

return _M