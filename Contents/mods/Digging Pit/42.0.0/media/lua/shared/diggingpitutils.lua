diggingpitutils = {};

function diggingpitutils.findOppositeSquare(entity)
	-- Give me something good
	if not entity or not entity:getSquare() or not entity:getSprite() then
		return false
	end
	
	local spriteName = entity:getSprite():getName()	
	local oppositeDirection = IsoDirections.NW -- Fallback value
	
	-- Find the opposite direction, to move there
	for _, sprites in ipairs(OppositeDirectionTable) do
		if sprites.spriteName == spriteName then
			oppositeDirection = sprites.direction
			break
		end
	end
	
	local targetSquare = entity:getSquare()
	local destinationSquare = targetSquare:getAdjacentSquare(oppositeDirection)
	
	-- Sanity check
	if not destinationSquare then
		return false
	else
		return destinationSquare
	end
end

function diggingpitutils.walkToOppositeSquare(playerObj, entity)
	-- Give me something good
	if not entity then return false end
	
	local destinationSquare = DiggingPitMenu.findOppositeSquare(entity)
	
	if not destinationSquare then return false end
	
	if destinationSquare == playerObj:getSquare() then
		-- No walk if already on the spot
		return true
	else
		-- Walk to tile in front of digging target
		return ISTimedActionQueue.add(ISWalkToTimedAction:new(playerObj, destinationSquare))
	end
end

function diggingpitutils.isOnOppositeSquare(playerObj, entity)
	-- Give me something good
	if not entity then return false end
	
	local destinationSquare = DiggingPitMenu.findOppositeSquare(entity)
	
	if not destinationSquare then return false end
	
	if destinationSquare == playerObj:getSquare() then
		-- Player is on tile opposite to entity
		return true
	else
		-- Player is NOT tile opposite to entity
		return false
	end
end