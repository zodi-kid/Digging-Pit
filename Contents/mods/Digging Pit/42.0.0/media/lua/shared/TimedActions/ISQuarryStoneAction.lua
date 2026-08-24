require "TimedActions/ISBaseTimedAction"

ISQuarryStoneAction = ISBaseTimedAction:derive("ISQuarryStoneAction");

local QuarryStoneRewards = {
	{ item = "Base.Stone2", 		chance = 0.95 },
	{ item = "Base.Clay", 			chance = 0.20 },
	{ item = "Base.SharpedStone", chance = 0.10 },
	{ item = "Base.IronOre", 		chance = 0.05 },
}

function ISQuarryStoneAction:isValid()
	-- Check tool is not null
	if not self.item then
		return false
	end
	-- Check tool is non-broken, and correct type
	if self.item:isBroken() or not self.item:hasTag(ItemTag.PICK_AXE) then
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
	
	-- Check if player is standing opposite of the tile
	if not diggingpitutils.isOnOppositeSquare(self.character, entity) then
		return false
	end
	
	-- Check inventory space
	--local inventory = self.character:getInventory()
	--if inventory:getCapacityWeight() < inventory:getCapacity() then
		--return false
	--end
	
	return true
end

function ISQuarryStoneAction:waitToStart()
	-- Turn towards the Quarryging Pit
	self.character:faceThisObject(self.entity)
	-- Wait until it returns False
	return self.character:isTurning() or self.character:shouldBeTurning()
end

function ISQuarryStoneAction:start()
	if isClient() and self.item then
        self.item = self.character:getInventory():getItemById(self.item:getID())
    end
	-- Inventory green bar on the Quarryging tool to show progress
	if self.item then
        self.item:setJobType(getText("ContextMenu_QuarryStone"));
        self.item:setJobDelta(0.0);
	end
	-- Role-play time
	self:setActionAnim("DestroyFloor");
	self:setOverrideHandModels(self.item, nil);
	addSound(self.character, self.character:getX(),self.character:getY(),self.character:getZ(), 20, 10);
	--self.sound = self.character:playSound("Shoveling");	
end

function ISQuarryStoneAction:update()
	-- Called every game tick
	-- Make sure the player is still facing the Quarryging Pit
	self.character:faceThisObject(self.entity)
	-- Put your back into it >:)
	--self.character:setMetabolicTarget(Metabolics.HeavyWork);
	self.character:setMetabolicTarget(Metabolics.FitnessHeavy);
    local skill = self.character:getPerkLevel(Perks.Strength)
    local strain = (1 - (skill * 0.05))/10 * getGameTime():getMultiplier()
    if self.item then
		self.item:setJobDelta(self:getJobDelta());
        self.character:addCombatMuscleStrain(self.item, 1, strain)
    end
end

function ISQuarryStoneAction:stop()
	-- Interrupted
	--self.character:stopOrTriggerSound(self.sound)
    ISBaseTimedAction.stop(self)
	if self.item then
        self.item:setJobDelta(0.0);
    end
end

function ISQuarryStoneAction:perform()
	--- Finished
	--self.character:stopOrTriggerSound(self.sound)
	if self.item then
        self.item:getContainer():setDrawDirty(true); -- Makes the character dirty
        self.item:setJobDelta(0.0);
    end
	self.character:playSound("CraftMineralDepositRemove")
	
	local queue = ISTimedActionQueue.getTimedActionQueue(self.character)
	if #queue.queue == 1 and self:isValid() then
		local nextAction = ISQuarryStoneAction:new(self.character, self.entity, self.item)
		ISTimedActionQueue.addAfter(self, nextAction)
	end	
	
	
	ISBaseTimedAction.perform(self); -- Unqueue and log
	
end

function ISQuarryStoneAction:complete()
	-- Spawn reward in inventory or on the world
	local rewardInventory = false
	-- Roll for rewards
	for _, reward in ipairs(QuarryStoneRewards) do
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
end

function ISQuarryStoneAction:new (character, entity, pickaxe)
	local o = ISBaseTimedAction.new(self, character)
	o.character = character;
	o.entity = entity
	o.item = pickaxe;
	o.maxTime = 100;
	o.stopOnWalk = true;
	o.stopOnRun = true;
	o.stopOnAim = true;
	return o
end
