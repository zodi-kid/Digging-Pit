diggingpitutils = {};

local OppositeDirectionTable = {
	{ spriteName = "digging_pit_0", direction = IsoDirections.NE },
	{ spriteName = "digging_pit_1", direction = IsoDirections.SE },
	{ spriteName = "digging_pit_2", direction = IsoDirections.NW },
	{ spriteName = "digging_pit_3", direction = IsoDirections.SW },
}

function diggingpitutils.findOppositeSquare(entity)
	-- Give me something good
	if not entity or not entity:getSquare() or not entity:getSprite() then
		return false -- :(
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
	
	local destinationSquare = diggingpitutils.findOppositeSquare(entity)
	
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
	
	local destinationSquare = diggingpitutils.findOppositeSquare(entity)
	
	if not destinationSquare then return false end
	
	if destinationSquare == playerObj:getSquare() then
		-- Player is on tile opposite to entity
		return true
	else
		-- Player is NOT tile opposite to entity
		return false
	end
end

function diggingpitutils.isPlayerTooTired(playerObj)
	return playerObj:getMoodles():getMoodleLevel(MoodleType.TIRED) > 3
end

function diggingpitutils.isPlayerTooExhausted(playerObj)
	return playerObj:getMoodles():getMoodleLevel(MoodleType.ENDURANCE) > 2
end

function diggingpitutils.isPlayerTooPained(playerObj)
	return playerObj:getMoodles():getMoodleLevel(MoodleType.PAIN) > 3
end

-- Reuses the base-game logic to determine that a tile is not pavement, flooring, etc.
function diggingpitutils.IsTileDirt(params)
    return ISShovelGroundCursor.GetDirtGravelSand(params.square) == "dirt"
end

