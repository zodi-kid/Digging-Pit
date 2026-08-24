--if not ContextMenuCode then
--    ContextMenuCode = {}
--end

DiggingPitMenu = {}

local OppositeDirectionTable = {
	{ spriteName = "digging_pit_0", direction = IsoDirections.NE },
	{ spriteName = "digging_pit_1", direction = IsoDirections.SE },
	{ spriteName = "digging_pit_2", direction = IsoDirections.NW },
	{ spriteName = "digging_pit_3", direction = IsoDirections.SW },
}

function DiggingPitMenu.OnFillWorldObjectContextMenu(player, context, worldobjects, test)
	--print("Context menu script successfully ran")
	-- Copied from game code, I guess it is a sanity check
	if test and ISWorldObjectContextMenu.Test then return true end
	
	local playerObj = getSpecificPlayer(player) ---???
	
	-- Another blow for motorized miners, sorry :(
	if playerObj:getVehicle() then return false end

	-- Did the player click on a Digging Pit?
	local diggingPitFound = false
	for _, obj in ipairs(worldobjects) do
		if obj and obj:getSprite() then
			-- Really unsure how to identify the tile; using fallback with tilename just in case
			if obj:getName() == "Digging Pit" then
				--diggingPitFound = true
				entity = obj
				break
			elseif obj:getSprite():getName():find("digging_pit_0")
				or obj:getSprite():getName():find("digging_pit_1")
				or obj:getSprite():getName():find("digging_pit_2")
				or obj:getSprite():getName():find("digging_pit_3") then
				--diggingPitFound = true
				entity = obj
				break
			end
		end
	end
	
	-- No Digging Pit, no context menu options
	--if not diggingPitFound then return false end
	if not entity then return false end

	-- ???
	if test then return ISWorldObjectContextMenu.setTest() end
	
	--local entity = worldobjects[1] -- For convenience sake
	
	-- Create Main Option
	local DiggingPitOption = context:addOption(getText("ContextMenu_DiggingPit"), worldobjects, nil)
	-- DiggingPitOption.iconTexture = getTexture("media/digging_pit_icon")
	-- Initialize the base for the sub-options and let it hang from the Main Option
	local DiggingPitSubMenu = ISContextMenu:getNew(context)
	context:addSubMenu(DiggingPitOption, DiggingPitSubMenu)

	-- Find and return digging tool from character inventory (item with DIG_GRAVE tag)
	local shovel = playerObj:getInventory():getFirstEvalRecurse(
		function(item) -- I think this checks all items for the conditions, and returns the first true
			return not item:isBroken() and item:hasTag(ItemTag.DIG_GRAVE)
		end
	)
	-- Same for a pickaxe
	local pickaxe = playerObj:getInventory():getFirstEvalRecurse(
		function(item)
			return not item:isBroken() and item:hasTag(ItemTag.PICK_AXE)
		end
	)	
	
	-- Each option and its associated action
	local optionDigDirt = DiggingPitSubMenu:addOption(getText("ContextMenu_DigDirt"), nil,
			function() -- I hate all these callbacks
				--if luautils.walkAdj(playerObj, entity:getSquare(), false) then
				if diggingpitutils.walkToOppositeSquare(playerObj, entity) then
					ISTimedActionQueue.add(ISDigDirtAction:new(playerObj, entity, shovel))
				end
			end
	)
	
	local optionDigStone = DiggingPitSubMenu:addOption(getText("ContextMenu_DigStone"), nil,
		function()
			--if luautils.walkAdj(playerObj, entity:getSquare(), false) then
			if diggingpitutils.walkToOppositeSquare(playerObj, entity) then
				ISTimedActionQueue.add(ISDigStoneAction:new(playerObj, entity, shovel))
			end
		end
	)
	
	local optionQuarryStone = DiggingPitSubMenu:addOption(getText("ContextMenu_QuarryStone"), nil,
		function() -- I still hate them
			--if luautils.walkAdj(playerObj, entity:getSquare(), false) then
			if diggingpitutils.walkToOppositeSquare(playerObj, entity) then
				ISTimedActionQueue.add(ISQuarryStoneAction:new(playerObj, entity, pickaxe))
			end
		end
	)
	
	-- If the player is too tired, disable the action and add a tooltip to let them know
	if playerObj:getMoodles():getMoodleLevel(MoodleType.ENDURANCE) > 2 then
		optionDigDirt.notAvailable = true;
		optionDigDirt.toolTip = ISWorldObjectContextMenu.addToolTip();
		optionDigDirt.toolTip.description = getText("ContextMenu_TooTiredForDiggingPit");
		
		optionDigStone.notAvailable = true;
		optionDigStone.toolTip = ISWorldObjectContextMenu.addToolTip();
		optionDigStone.toolTip.description = getText("ContextMenu_TooTiredForDiggingPit");
		
		optionQuarryStone.notAvailable = true;
		optionQuarryStone.toolTip = ISWorldObjectContextMenu.addToolTip();
		optionQuarryStone.toolTip.description = getText("ContextMenu_TooTiredForDiggingPit");
	end
	
	-- If the player is in too much pain, disable the action and add a tooltip to let them know
	if playerObj:getMoodles():getMoodleLevel(MoodleType.PAIN) > 3 then
		optionDigDirt.notAvailable = true;
		optionDigDirt.toolTip = ISWorldObjectContextMenu.addToolTip();
		optionDigDirt.toolTip.description = getText("ContextMenu_TooMuchPainForDiggingPit");
		
		optionDigStone.notAvailable = true;
		optionDigStone.toolTip = ISWorldObjectContextMenu.addToolTip();
		optionDigStone.toolTip.description = getText("ContextMenu_TooMuchPainForDiggingPit");
		
		optionQuarryStone.notAvailable = true;
		optionQuarryStone.toolTip = ISWorldObjectContextMenu.addToolTip();
		optionQuarryStone.toolTip.description = getText("ContextMenu_TooMuchPainForDiggingPit");
	end
	
	-- If the player is missing a tool, disable the action and add a tooltip to let them know
	if not shovel then
		optionDigDirt.notAvailable = true;
		optionDigDirt.toolTip = ISWorldObjectContextMenu.addToolTip();
		optionDigDirt.toolTip.description = getText("ContextMenu_NeedShovel");
		
		optionDigStone.notAvailable = true;
		optionDigStone.toolTip = ISWorldObjectContextMenu.addToolTip();
		optionDigStone.toolTip.description = getText("ContextMenu_NeedShovel");
	end
	
	if not pickaxe then
		optionQuarryStone.notAvailable = true;
		optionQuarryStone.toolTip = ISWorldObjectContextMenu.addToolTip();
		optionQuarryStone.toolTip.description = getText("ContextMenu_NeedPickaxe");
	end
	
	return true
end

Events.OnFillWorldObjectContextMenu.Add(DiggingPitMenu.OnFillWorldObjectContextMenu)

function DiggingPitMenu.walkToOpposite(playerObj, entity)
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
	if not destinationSquare then return false end
	
	if destinationSquare == playerObj:getSquare() then
		-- No walk if already on the spot
		return true
	else
		-- Walk to tile in front of digging target
		return ISTimedActionQueue.add(ISWalkToTimedAction:new(playerObj, destinationSquare))
	end
end

function DiggingPitMenu.findOppositeSquare(entity)
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



function DiggingPitMenu.walkToOppositeSquare(playerObj, entity)
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