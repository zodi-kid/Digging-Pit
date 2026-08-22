--if not ContextMenuCode then
--    ContextMenuCode = {}
--end

-- Instead of the typical (context, entity, character, param), we have to use (context, data)
function ContextMenuCode.DiggingPitMenu(context, data)

	--local subMenu = context:getSubMenu(option.subOption)

	local optionDiggingPit = nil;
		for i,v in ipairs(context.options) do
			if v.name == getText("ContextMenu_DiggingPit") then
				optionDiggingPit = v;
				subOptionDiggingPit = context:getSubMenu(optionDiggingPit.subOption);
			end
		end

	-- We extract the entity, the character, and the param from data
	local entity = data.entity
	local character = data.playerObj
	
	-- Find and return digging tool from character inventory (item with DIG_GRAVE tag)
	local shovel = character:getInventory():getFirstEvalRecurse(
		function(item) -- I think this checks all items for the conditions, and returns the first true
			return not item:isBroken() and item:hasTag(ItemTag.DIG_GRAVE)
		end
	)
	-- Same for a pickaxe
	local pickaxe = character:getInventory():getFirstEvalRecurse(
		function(item)
			return not item:isBroken() and item:hasTag(ItemTag.PICK_AXE)
		end
	)	
	
	-- The different options
	
	
	
	
	local optionDigDirt = subOptionDiggingPit:addOption(getText("ContextMenu_DigDirt"), nil,
			function() -- I hate all these callbacks
				if luautils.walkAdj(character, entity:getSquare(), false) then
					ISTimedActionQueue.add(ISDigDirtAction:new(character, entity, shovel))
				end
			end
	)
	
	local optionDigStone = subOptionDiggingPit:addOption(getText("ContextMenu_DigStone"), nil,
		function()
			if luautils.walkAdj(character, entity:getSquare(), false) then
				ISTimedActionQueue.add(ISDigStoneAction:new(character, entity, shovel))
			end
		end
	)
	
	local optionQuarryStone = subOptionDiggingPit:addOption(getText("ContextMenu_QuarryStone"), nil,
		function() -- I still do
			if luautils.walkAdj(character, entity:getSquare(), false) then
				ISTimedActionQueue.add(ISQuarryStoneAction:new(character, entity, pickaxe))
			end
		end
	)
	
	if not shovel then
		optionDigDirt.notAvailable = true;
		optionDigDirt.toolTip = ISWorldObjectContextMenu.addToolTip();
		optionDigDirt.toolTip.description = getText("ContextMenu_No_Fuel");
		
		optionDigStone.notAvailable = true;
		optionDigStone.toolTip = ISWorldObjectContextMenu.addToolTip();
		optionDigStone.toolTip.description = getText("ContextMenu_No_Fuel");
	end
	
	if not pickaxe then
		optionQuarryStone.notAvailable = true;
		optionQuarryStone.toolTip = ISWorldObjectContextMenu.addToolTip();
		optionQuarryStone.toolTip.description = getText("ContextMenu_No_Fuel");
	end	
end