--if not ContextMenuCode then
--    ContextMenuCode = {}
--end

function ContextMenuCode.DiggingPitMenu(context, entity, character, param)
	-- Find and return digging tool from character inventory (item with DIG_GRAVE tag)
	local shovel = character:getInventory():getFirstEvalRecurse(
		function(item) -- I think this checks all items for the conditions, and returns the first true
			return not item:isBroken() and item:hasTag(ItemTag.DIG_GRAVE)
		end
	)
	-- Same for a pickaxe
	local pick = character:getInventory():getFirstEvalRecurse(
		function(item)
			return not item:isBroken() and item:hasTag(ItemTag.PICK_AXE)
		end
	)	
	
	-- The different options
	local optionDigDirt = context:addOption(getText("ContextMenu_DigDirt"), nil,
			function() -- I hate all these callbacks
				if luautils.walkAdj(character, entity:getSquare(), false) then
					ISTimedActionQueue.add(ISDigDirtAction:new(character, entity, shovel)
				end
			end
	)
	
	local optionDigStone = context:addOption(getText("ContextMenu_DigStone"), nil,
		function()
			if luautils.walkAdj(character, entity:getSquare(), false) then
				ISTimedActionQueue.add(ISDigStoneAction:new(character, entity, shovel)
			end
		end
	)
	
	local optionQuarryStone = context:addOption(getText("ContextMenu_QuarryStone"), nil,
		function() -- I still do
			if luautils.walkAdj(character, entity:getSquare(), false) then
				ISTimedActionQueue.add(ISQuarryStoneAction:new(character, entity, pickaxe)
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
)