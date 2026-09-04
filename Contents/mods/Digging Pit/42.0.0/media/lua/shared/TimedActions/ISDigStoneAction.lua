require "TimedActions/ISBaseTimedAction"

ISDigStoneAction = ISBaseTimedAction:derive("ISDigStoneAction");

local DigStoneRewards = {
	{ item = "Base.Stone2", 		chance = 0.60 },
	{ item = "Base.Clay", 			chance = 0.10 },
	{ item = "Base.SharpedStone", 	chance = 0.08 },
	{ item = "Base.IronOre", 		chance = 0.02 },
}

function ISDigStoneAction:isValid()
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

function ISDigStoneAction:waitToStart()
	-- Turn towards the Digging Pit
	self.character:faceThisObject(self.entity)
	-- Wait until it returns False
	return self.character:isTurning() or self.character:shouldBeTurning()
end

function ISDigStoneAction:start()
	if isClient() and self.tool then
        self.tool = self.character:getInventory():getItemById(self.tool:getID())
    end
	-- Inventory green bar on the digging tool to show progress
	if self.tool then
        self.tool:setJobType(self.text);
        self.tool:setJobDelta(0.0);
	end
	-- Role-play time
	self:setActionAnim(self.animName);
	self:setOverrideHandModels(self.tool, nil);
	self.soundPlaying = self.character:playSound(self.soundProgress);
	addSound(self.character, self.character:getX(), self.character:getY(), self.character:getZ(), 10, 1)
end

function ISDigStoneAction:serverStart()
	--self.item = self.character:getPrimaryHandItem()
	self.tool = self.character:getInventory():getItemById(self.tool:getID())
	emulateAnimEvent(self.netAction, self.maxTime, self.eventName, nil)
end

-- Server side computing: changes to character, items, etc.
function ISDigStoneAction:animEvent(event, parameter)
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

function ISDigStoneAction:useEndurance()
	if self.tool then
		local fatigue = self.tool:getWeight()
			* self.tool:getFatigueMod(self.character)
			* self.tool:getEnduranceMod()
			* self.character:getFatigueMod()
			* 0.1
		local balanceFactor = 0.11 -- used to fine-tune endurance draining
		fatigue = fatigue * balanceFactor
		self.character:getStats():remove(CharacterStat.ENDURANCE, fatigue)
	end
end

function ISDigStoneAction:update()
	-- Called every game tick
	-- Make sure the player is still facing the Digging Pit
	self.character:faceThisObject(self.entity)
    if self.tool then
		-- Progress bar
		self.tool:setJobDelta(self:getJobDelta());
    end
end

function ISDigStoneAction:stop()
	-- Interrupted
	self.character:stopOrTriggerSound(self.soundPlaying)
    ISBaseTimedAction.stop(self)
	if self.tool then
        self.tool:setJobDelta(0.0);
    end
end

function ISDigStoneAction:perform()
	--- Finished
	self.character:stopOrTriggerSound(self.soundPlaying)
	if self.tool then
        self.tool:setJobDelta(0.0);
    end
	
	-- Repeat the action, unless conditions unmet or player queues something else
	local queue = ISTimedActionQueue.getTimedActionQueue(self.character)
	if #queue.queue == 1 and self:isValid() then
		local nextAction = ISDigStoneAction:new(self.character, self.entity, self.tool)
		ISTimedActionQueue.addAfter(self, nextAction)
	end	
	
	ISBaseTimedAction.perform(self); -- Unqueue and log
end

function ISDigStoneAction:complete()
	-- Roll for rewards
	for _, reward in ipairs(DigStoneRewards) do
		if ZombRandFloat(0, 1) <= reward.chance then
			-- Spawn reward on the world
			self.character:getSquare():SpawnWorldInventoryItem(reward.item, 0.0, 0.0, 0.0)
		end
	end
	-- reloads world inventory
	triggerEvent("OnContainerUpdate", self.character:getSquare())
end

function ISDigStoneAction:new (character, entity, shovel)
	local o = ISBaseTimedAction.new(self, character)
	o.character 	= character;	-- Class: IsoPlayer, extends IsoGameCharacter
	o.entity 		= entity 		-- Class: IsoObject
	o.tool 			= shovel; 		-- Class: HandWeapon, extends InventoryItem
	o.maxTime 		= self:getDuration();			-- Miliseconds / 2??? If 10000 is used, it actually takes 20 seconds
	o.eventName 	= "DiggingPit_DigStoneEvent"; 	-- Has to match <m_EventName> 	from media/AnimSets/player/actions
	o.text 			= getText("ContextMenu_DigStone");
	o.animName 		= "DiggingPit_DigStone"; 		-- Has to match <m_Name> 		from media/AnimSets/player/actions
	o.soundProgress = "Shoveling";
	o.soundFinished = "";
	o.soundPlaying 	= nil;			-- Used to store the id of the sound playing, so it can be stopped later
	o.stopOnWalk 	= true;
	o.stopOnRun 	= true;
	o.stopOnAim 	= true;
	return o	
end

function ISDigStoneAction:getDuration()
	return 182.5 -- Anim: 3.75s
end