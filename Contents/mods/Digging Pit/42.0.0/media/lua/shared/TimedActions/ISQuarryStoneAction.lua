require "TimedActions/ISBaseTimedAction"

ISQuarryStoneAction = ISBaseTimedAction:derive("ISQuarryStoneAction");

local QuarryStoneRewards = {
	{ item = "Base.Stone2", 		chance = 0.95 },
	{ item = "Base.Clay", 			chance = 0.20 },
	{ item = "Base.SharpedStone", 	chance = 0.10 },
	{ item = "Base.IronOre", 		chance = 0.05 },
}

function ISQuarryStoneAction:isValid()
	-- Check tool is not null
	if not self.tool then
		return false
	end
	-- Check tool is non-broken, and correct type
	if self.tool:isBroken() or not self.tool:hasTag(ItemTag.PICK_AXE) then
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

function ISQuarryStoneAction:waitToStart()
	-- Turn towards the Quarryging Pit
	self.character:faceThisObject(self.entity)
	-- Wait until it returns False
	return self.character:isTurning() or self.character:shouldBeTurning()
end

function ISQuarryStoneAction:start()
	if isClient() and self.tool then
        self.tool = self.character:getInventory():getItemById(self.tool:getID())
    end
	-- Inventory green bar on the Quarryging tool to show progress
	if self.tool then
        self.tool:setJobType(self.text);
        self.tool:setJobDelta(0.0);
	end
	-- Role-play time
	self:setActionAnim(self.animName);
	self:setOverrideHandModels(self.tool, nil);
	addSound(self.character, self.character:getX(),self.character:getY(),self.character:getZ(), 20, 10);
	--self.soundPlaying = self.character:playSound("Shoveling");	
end

function ISQuarryStoneAction:serverStart()
	--self.item = self.character:getPrimaryHandItem()
	self.tool = self.character:getInventory():getItemById(self.tool:getID())
	emulateAnimEvent(self.netAction, self.maxTime, self.eventName, nil)
end

-- Server side computing: changes to character, items, etc.
function ISQuarryStoneAction:animEvent(event, parameter)
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
			self.character:setMetabolicTarget(Metabolics.HeavyWork);
			self:useEndurance()
			diggingpitutils.getDirty(self.character)
		end
	end
end

function ISQuarryStoneAction:useEndurance()
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

function ISQuarryStoneAction:update()
	-- Called every game tick
	-- Make sure the player is still facing the Digging Pit
	self.character:faceThisObject(self.entity)
    if self.tool then
		-- Progress bar
		self.tool:setJobDelta(self:getJobDelta());
    end
end

function ISQuarryStoneAction:stop()
	-- Interrupted
	--self.character:stopOrTriggerSound(self.soundPlaying)
    ISBaseTimedAction.stop(self)
	if self.tool then
        self.tool:setJobDelta(0.0);
    end
end

function ISQuarryStoneAction:perform()
	--- Finished
	--self.character:stopOrTriggerSound(self.soundPlaying)
	if self.tool then
        --self.tool:getContainer():setDrawDirty(true); -- Makes the character dirty
        self.tool:setJobDelta(0.0);
    end
	
	self.character:playSound(self.soundFinished)
	
	local queue = ISTimedActionQueue.getTimedActionQueue(self.character)
	if #queue.queue == 1 and self:isValid() then
		local nextAction = ISQuarryStoneAction:new(self.character, self.entity, self.tool)
		ISTimedActionQueue.addAfter(self, nextAction)
	end
	
	ISBaseTimedAction.perform(self); -- Unqueue and log
end

function ISQuarryStoneAction:complete()
	-- Roll for rewards
	for _, reward in ipairs(QuarryStoneRewards) do
		if ZombRandFloat(0, 1) <= reward.chance then
			-- Spawn reward on the world
			self.character:getSquare():SpawnWorldInventoryItem(reward.item, 0.0, 0.0, 0.0)
		end
	end
	-- reloads world inventory
	triggerEvent("OnContainerUpdate", self.character:getSquare())
end

function ISQuarryStoneAction:new (character, entity, pickaxe)
	local o = ISBaseTimedAction.new(self, character)
	o.character 	= character;	-- Class: IsoPlayer, extends IsoGameCharacter
	o.entity 		= entity 		-- Class: IsoObject
	o.tool 			= pickaxe; 		-- Class: HandWeapon, extends InventoryItem
	o.maxTime 		= 1500;
	o.eventName 	= "DiggingPit_QuarryStoneEvent"; -- Has to match <m_EventName> 	from media/AnimSets/player/actions
	o.text 			= getText("ContextMenu_QuarryStone");
	o.animName 		= "DiggingPit_QuarryStone"; 	-- Has to match <m_Name> 		from media/AnimSets/player/actions
	o.soundProgress = "";
	o.soundFinished = "CraftMineralDepositRemove";
	o.soundPlaying 	= nil;			-- Used to store the id of the sound playing, so it can be stopped later
	o.stopOnWalk 	= true;
	o.stopOnRun 	= true;
	o.stopOnAim 	= true;
	return o
end
