require "TimedActions/ISBaseTimedAction"

ISDigStoneAction = ISBaseTimedAction:derive("ISDigStoneAction");

local DigStoneRewards = {
	{ item = "Base.Stone2", 		chance = 0.95 },
	{ item = "Base.Clay", 			chance = 0.20 },
	{ item = "Base.SharpenedStone", chance = 0.10 },
	{ item = "Base.IronOre", 		chance = 0.05 },
}

function ISDigStoneAction:isValid()
	if isClient() then
		-- Check inventory space.
		local inventory = self.character:getInventory()
		if inventory:getCapacityWeight() >= inventory:getCapacity() then
			return false
		-- Check player still has valid shovel in inventory.
		elseif self.item then
			return 	self.character:getInventory():containsID(self.item:getID()) and
				self.item:hasTag(ItemTag.DIG_GRAVE) and
				not self.item:isBroken();
		end
	else
		return true
	end
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
        self.item:setJobType(getText("ContextMenu_Dig"));
        self.item:setJobDelta(0.0);
	end
	-- Role-play time
	self:setActionAnim(BuildingHelper.getShovelAnim(self.item));
	self:setOverrideHandModels(self.item, nil);
	self.sound = self.character:playSound("Shoveling");	
end

function ISDigStoneAction:update()
	-- Called every game tick
	-- Make sure the player is still facing the Digging Pit
	self.character:faceThisObject(self.entity)
	-- Put your back into it >:)
	self.character:setMetabolicTarget(Metabolics.DiggingSpade);
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
        self.item:getContainer():setDrawDirty(true); -- Makes the character dirty
        self.item:setJobDelta(0.0);
    end	
	ISBaseTimedAction.perform(self); -- Unqueue and log
end

function ISDigStoneAction:complete()
	-- Roll for rewards
	for _, reward in ipairs(DigStoneRewards) do
		if ZombRandFloat(0, 1) <= reward.chance then
			self.character:getInventory():AddItem(reward.item)
		end
	end
end

function ISDigStoneAction:new (character, entity, shovel)
	local o = ISBaseTimedAction.new(self, character)
	o.character = character;
	o.entity = entity
	o.item = shovel;
	o.maxTime = 100;
	o.stopOnWalk = true;
	o.stopOnRun = true;
	o.stopOnAim = true;
    --o.caloriesModifier = 1;
	return o
end
