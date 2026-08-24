require "TimedActions/ISBaseTimedAction"

ISDigStoneAction = ISBaseTimedAction:derive("ISDigStoneAction");

local DigStoneRewards = {
	{ item = "Base.Stone2", 		chance = 0.95 },
	{ item = "Base.Clay", 			chance = 0.20 },
	{ item = "Base.SharpedStone", chance = 0.10 },
	{ item = "Base.IronOre", 		chance = 0.05 },
}

function ISDigStoneAction:isValid()
	-- Check tool is not null
	if not self.item then
		return false
	end
	-- Check tool is non-broken, and correct type
	if self.item:isBroken() or not self.item:hasTag(ItemTag.DIG_GRAVE) then
		return false
	end
	-- Check player has tool
	if isClient() then
		if not self.character:getInventory():containsID(self.item:getID()) then
			return false
		end
	else
		if not self.character:getInventory():contains(self.item) then
			return false
		end
	end
	-- Check inventory space
	--local inventory = self.character:getInventory()
	--if inventory:getCapacityWeight() < inventory:getCapacity() then
		--return false
	--end
	
	return true
end

function ISDigStoneAction:waitToStart()
	-- Turn towards the Digging Pit
	self.character:faceThisObject(self.entity)
	-- Wait until it returns False
	return self.character:isTurning() or self.character:shouldBeTurning()
end

function ISDigStoneAction:start()
	if isClient() and self.item then
        self.item = self.character:getInventory():getItemById(self.item:getID())
    end
	-- Inventory green bar on the digging tool to show progress
	if self.item then
        self.item:setJobType(getText("ContextMenu_DigStone"));
        self.item:setJobDelta(0.0);
	end
	-- Role-play time
	self:setActionAnim(BuildingHelper.getShovelAnim(self.item));
	self:setOverrideHandModels(self.item, nil);
	self.sound = self.character:playSound("Shoveling");
	addSound(self.character, self.character:getX(), self.character:getY(), self.character:getZ(), 10, 1)
end

function ISDigStoneAction:update()
	-- Called every game tick
	-- Make sure the player is still facing the Digging Pit
	self.character:faceThisObject(self.entity)
	-- Put your back into it >:)
	
	--CURRENTLY, IT DOES NOT SEEM TO DRAIN STAMINA
	--self.character:setMetabolicTarget(Metabolics.DiggingSpade);
	self.character:setMetabolicTarget(Metabolics.FitnessHeavy);
    local skill = self.character:getPerkLevel(Perks.Strength)
    local strain = (1 - (skill * 0.05))/10 * getGameTime():getMultiplier()
    if self.item then
		self.item:setJobDelta(self:getJobDelta());
        self.character:addCombatMuscleStrain(self.item, 1, strain)
    end
end

function ISDigStoneAction:stop()
	-- Interrupted
	self.character:stopOrTriggerSound(self.sound)
    ISBaseTimedAction.stop(self)
	if self.item then
        self.item:setJobDelta(0.0);
    end
end

function ISDigStoneAction:perform()
	--- Finished
	self.character:stopOrTriggerSound(self.sound)
	if self.item then
        self.item:setJobDelta(0.0);
    end
	
	-- Repeat the action, unless conditions unmet or player queues something else
	local queue = ISTimedActionQueue.getTimedActionQueue(self.character)
	if #queue.queue == 1 and self:isValid() then
		local nextAction = ISDigStoneAction:new(self.character, self.entity, self.item)
		ISTimedActionQueue.addAfter(self, nextAction)
	end	
	
	ISBaseTimedAction.perform(self); -- Unqueue and log
end

function ISDigStoneAction:complete()
	local rewardInventory = false
	-- Roll for rewards
	for _, reward in ipairs(DigStoneRewards) do
		if ZombRandFloat(0, 1) <= reward.chance then
			if rewardInventory then
				local rewardItem = self.character:getInventory():AddItem(reward.item)
				if rewardItem then
					sendAddItemToContainer(self.character:getInventory(), rewardItem)
				end
			else
				self.character:getSquare():SpawnWorldInventoryItem(reward.item, 0.0, 0.0, 0.0)
			end
		end
	end
	-- I don't know if placing it outside the loop really helps performance
	if rewardInventory then
		-- refresh player inventory
		self.item:getContainer():setDrawDirty(true);
	else
		-- refresh world inventory
	end
end

function ISDigStoneAction:new (character, entity, shovel)
	local o = ISBaseTimedAction.new(self, character)
	o.character = character;
	o.entity = entity
	o.item = shovel;
	o.maxTime = 180;
	o.stopOnWalk = true;
	o.stopOnRun = true;
	o.stopOnAim = true;
	return o
end
