require "TimedActions/ISBaseTimedAction"

ISDigDirtAction = ISBaseTimedAction:derive("ISDigDirtAction");

local DigDirtRewards = {
	{ item = "Base.Stone2", 		chance = 0.05 },
	{ item = "Base.Clay", 			chance = 0.10 },
	{ item = "Base.SharpedStone", 	chance = 0.01 },
	--{ item = "Base.IronOre", 		chance = 0.05 },
	{ item = "Base.Worm", 			chance = 0.60 },
}

function ISDigDirtAction:isValid()
	-- Check tool is not null
	if not self.tool then
		return false
	end
	-- Check tool is non-broken, and correct type
	if self.tool:isBroken() or not self.tool:hasTag(ItemTag.DIG_GRAVE) then
		return false
	end
	-- Check player has tool
	if isClient() then
		if not self.character:getInventory():containsID(self.tool:getID()) then
			return false
		end
	else
		if not self.character:getInventory():contains(self.tool) then
			return false
		end
	end
	
	-- Check bag is not null
	if not self.emptyBag then
		return false
	end
	
	-- Check newBag too?
	
	-- Check bag is not used as container (and has items inside)
	if instanceof(self.emptyBag, "InventoryContainer") then
		if self.emptyBag:getInventory():isEmpty() == false then
			return false
		end
	end
	
	-- Check player has valid bag in inventory
	if isClient() then
		-- Has bag
		if not self.character:getInventory():containsID(self.emptyBag:getID()) then
			return false
		-- Bag is valid
		elseif not (self.emptyBag:hasTag(ItemTag.HOLD_DIRT) or self.emptyBag:getCurrentUsesFloat() < 1) then
			return false
		end           
    else
		-- Has bag
		if not self.character:getInventory():contains(self.emptyBag) then
			return false
		-- Bag is valid
		elseif not (self.emptyBag:hasTag(ItemTag.HOLD_DIRT) or self.emptyBag:getCurrentUsesFloat() < 1) then
			return false
		end
    end
	
	if diggingpitutils.isPlayerTooExhausted(self.character) then
		return false
	end
	
	if diggingpitutils.isPlayerTooPained(self.character) then
		return false
	end
	
	-- Check if player is standing opposite of the tile
	if not diggingpitutils.isOnOppositeSquare(self.character, self.entity) then
		return false
	end

	-- Check inventory space
	--local inventory = self.character:getInventory()
	--if inventory:getCapacityWeight() < inventory:getCapacity() then
		--return false
	--end

	-- If no condition to return false is met, the action is Valid
	return true
end

function ISDigDirtAction:waitToStart()
	-- Turn towards the Digging Pit
	self.character:faceThisObject(self.entity)
	-- Wait until it returns False
	return self.character:isTurning() or self.character:shouldBeTurning()
end

function ISDigDirtAction:start()
	if isClient() and self.tool then
        self.tool = self.character:getInventory():getItemById(self.tool:getID())
    end
	if isClient() and self.emptyBag then
        self.emptyBag = self.character:getInventory():getItemById(self.emptyBag:getID())
    end
	-- Inventory green bar on the digging tool to show progress
	if self.tool then
        self.tool:setJobType(self.text);
        self.tool:setJobDelta(0.0);
	end
	-- Inventory green bar on the empty bag to show progress
	if self.emptyBag then
        self.emptyBag:setJobType(self.text);
        --self.emptyBag:setJobDelta(0.0);
	end
	-- Role-play time
	--self:setActionAnim(BuildingHelper.getShovelAnim(self.tool));
	self:setActionAnim(self.animName);
	self:setOverrideHandModels(self.tool, nil);
	self.sound = self.character:playSound(self.soundProgress);
	addSound(self.character, self.character:getX(), self.character:getY(), self.character:getZ(), 10, 1)
end

function ISDigDirtAction:serverStart()
	--self.item = self.character:getPrimaryHandItem()
	self.tool = self.character:getInventory():getItemById(self.tool:getID())
	emulateAnimEvent(self.netAction, self.maxTime, self.eventName, nil)
end

-- Server side computing: changes to character, items, etc.
function ISDigDirtAction:animEvent(event, parameter)
	if not isClient() then
		if event == self.eventName then
			if self.tool then -- Sanity check
				-- Tool durability loss check
				if self.tool:damageCheck(0, 2, false) then
					ISWorldObjectContextMenu.checkWeapon(self.character)
				end
				-- Muscle strain
				local skill = self.character:getPerkLevel(Perks.Strength)
				local strain = (1 - (skill * 0.05))/10 * getGameTime():getMultiplier()
				self.character:addCombatMuscleStrain(self.tool, 1, strain)
			end
			-- Put your back into it >:)
			self.character:setMetabolicTarget(Metabolics.DiggingSpade);
			self:useEndurance()
			diggingpitutils.getDirty(self.character)
		end
	end
end

function ISDigDirtAction:useEndurance()
	if self.tool then
		local fatigue = self.tool:getWeight()
			* self.tool:getFatigueMod(self.character)
			* self.tool:getEnduranceMod()
			* self.character:getFatigueMod()
			* 0.1
		local balanceFactor = 0.041 -- used to fine-tune endurance draining
		fatigue = fatigue * balanceFactor
		self.character:getStats():remove(CharacterStat.ENDURANCE, fatigue)
	end
end

function ISDigDirtAction:update()
	-- Called every game tick
	-- Make sure the player is still facing the Digging Pit
	self.character:faceThisObject(self.entity)
    if self.tool then
		-- Progress bar
		self.tool:setJobDelta(self:getJobDelta());
    end
	if self.emptyBag then
		-- Progress bar
		self.emptyBag:setJobDelta(self:getJobDelta());
    end
end

function ISDigDirtAction:stop()
	-- Interrupted
	self.character:stopOrTriggerSound(self.sound)
    ISBaseTimedAction.stop(self)
	if self.tool then
        self.tool:setJobDelta(0.0);
    end
	if self.emptyBag then
        self.emptyBag:setJobDelta(0.0);
    end
end

function ISDigDirtAction:perform()
	--- Finished
	self.character:stopOrTriggerSound(self.sound)
	if self.tool then
        self.tool:setJobDelta(0.0);
    end
	if self.emptyBag then
		self.emptyBag:setJobDelta(0.0);
	end
	
	-- Repeat the action, unless conditions unmet or player queues something else
	--local queue = ISTimedActionQueue.getTimedActionQueue(self.character)
	--if #queue.queue == 1 and self:isValid() then
		--local nextAction = ISDigDirtAction:new(self.character, self.entity, self.tool)
		--ISTimedActionQueue.addAfter(self, nextAction)
	--end	
	
	getPlayerInventory(self.character:getPlayerNum()):refreshBackpacks();
	getPlayerLoot(self.character:getPlayerNum()):refreshBackpacks();
	
	ISBaseTimedAction.perform(self); -- Unqueue and log
end	

function ISDigDirtAction:complete()
	-- Fill bag with dirt
	print("[DiggingPit]:	Completed successfully")
	-- emptyBag -> newBag
	if self.emptyBag:hasTag(ItemTag.HOLD_DIRT) and (self.newBag == "Base.Dirtbag") then
		self.character:removeFromHands(self.emptyBag);
		-- Client-server handling of exchange
		self.character:getInventory():Remove(self.emptyBag);
		sendRemoveItemFromContainer(self.character:getInventory(), self.emptyBag);
		local item = self.character:getInventory():AddItem(self.newBag);
		sendAddItemToContainer(self.character:getInventory(), item);
		item:setUsedDelta(item:getUseDelta())
		sendItemStats(item)
	-- (empty)Bag + dirt
	elseif self.emptyBag:getCurrentUsesFloat() + self.emptyBag:getUseDelta() <= 1 then -- Should I floor it?
		self.emptyBag:setUsedDelta(self.emptyBag:getCurrentUsesFloat() + self.emptyBag:getUseDelta())
		sendItemStats(self.emptyBag)
	end

	-- Roll for rewards
	for _, reward in ipairs(DigDirtRewards) do
		if ZombRandFloat(0, 1) <= reward.chance then
			-- Spawn reward on the world
			self.character:getSquare():SpawnWorldInventoryItem(reward.item, 0.0, 0.0, 0.0)
		end
	end
	-- reloads world inventory
	triggerEvent("OnContainerUpdate", self.character:getSquare())
end

function ISDigDirtAction:new (character, entity, shovel, emptyBag)
	local o = ISBaseTimedAction.new(self, character)
	o.character 	= character;	-- Class: IsoPlayer, extends IsoGameCharacter
	o.entity 		= entity 		-- Class: IsoObject
	o.tool 			= shovel; 		-- Class: HandWeapon, extends InventoryItem
	o.emptyBag		= emptyBag
	o.newBag		= "Base.Dirtbag"
	o.maxTime 		= 100;
	o.eventName 	= "DiggingPit_DigDirtEvent"; 	-- Has to match <m_EventName> 	from media/AnimSets/player/actions
	o.text 			= getText("ContextMenu_DigDirt");
	o.animName 		= "DiggingPit_DigDirt"; 		-- Has to match <m_Name> 		from media/AnimSets/player/actions
	o.soundProgress = "Shoveling";
	o.soundFinished = "";
	o.stopOnWalk 	= true;
	o.stopOnRun 	= true;
	o.stopOnAim 	= true;
	--o.caloriesModifier = 8;
	return o	
end
