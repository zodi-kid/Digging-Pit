require "TimedActions/ISBaseTimedAction"

ISCharmWormsAction = ISBaseTimedAction:derive("ISCharmWormsAction");

local CharmWormRewards = {
	{ item = "Base.Worm", 	chance = 0.60 },
	{ item = "Base.Worm", 	chance = 0.30 },
	{ item = "Base.Worm", 	chance = 0.00 },
}

function ISCharmWormsAction:isValid()
	-- Check tool is not null
	if not self.tool then
		return false
	end
	-- Check tool is non-broken, and correct type
	if self.tool:isBroken() or not (self.tool:getType() == "WoodenStick2") then
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
	if self.character:getPerkLevel(Perks.PlantScavenging) < 6 then
		return false
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

function ISCharmWormsAction:waitToStart()
	-- Turn towards the Digging Pit
	self.character:faceThisObject(self.entity)
	-- Wait until it returns False
	return self.character:isTurning() or self.character:shouldBeTurning()
end

function ISCharmWormsAction:start()
	if isClient() and self.tool then
        self.tool = self.character:getInventory():getItemById(self.tool:getID())
    end
	-- Inventory green bar on the digging tool to show progress
	if self.tool then
        self.tool:setJobType(self.text);
        self.tool:setJobDelta(0.0);
	end
	-- Role-play time
	--self:setActionAnim(BuildingHelper.getShovelAnim(self.tool));
	self:setActionAnim(self.animName);
	self:setOverrideHandModels(self.tool, nil);
	self.soundPlaying = self.character:playSound(self.soundProgress);
	addSound(self.character, self.character:getX(), self.character:getY(), self.character:getZ(), 5, 1)
end

function ISCharmWormsAction:serverStart()
	--self.item = self.character:getPrimaryHandItem()
	self.tool = self.character:getInventory():getItemById(self.tool:getID())
	emulateAnimEvent(self.netAction, self.maxTime, self.eventName, nil)
end

-- Server side computing: changes to character, items, etc.
function ISCharmWormsAction:animEvent(event, parameter)
	if not isClient() then
		if event == self.eventName then
			local newTime = getTimestampMs()
			print("[DiggingPit]: 	Worm charming time " .. (newTime - self.time))
			self.time = newTime
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

function ISCharmWormsAction:useEndurance()
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

function ISCharmWormsAction:update()
	-- Called every game tick
	-- Make sure the player is still facing the Digging Pit
	self.character:faceThisObject(self.entity)
    if self.tool then
		-- Progress bar
		self.tool:setJobDelta(self:getJobDelta());
    end
end

function ISCharmWormsAction:stop()
	-- Interrupted
	self.character:stopOrTriggerSound(self.soundPlaying)
    ISBaseTimedAction.stop(self)
	if self.tool then
        self.tool:setJobDelta(0.0);
    end
end

function ISCharmWormsAction:perform()
	--- Finished
	self.character:stopOrTriggerSound(self.soundPlaying)
	if self.tool then
        self.tool:setJobDelta(0.0);
    end
	
	-- Repeat the action, unless conditions unmet or player queues something else
	local queue = ISTimedActionQueue.getTimedActionQueue(self.character)
	if #queue.queue == 1 and self:isValid() then
		local nextAction = ISCharmWormsAction:new(self.character, self.entity, self.tool)
		ISTimedActionQueue.addAfter(self, nextAction)
	end	
	
	ISBaseTimedAction.perform(self); -- Unqueue and log
end

function ISCharmWormsAction:complete()
	local skillBonus = math.max(0, self.character:getPerkLevel(Perks.PlantScavenging) - 6)
	-- Roll for rewards
	for _, reward in ipairs(CharmWormRewards) do
		if ZombRandFloat(0, 1) <= (reward.chance + skillBonus*0.05) then
			-- Add reward to player inventory
			local rewardItem = self.character:getInventory():AddItem(reward.item)
			if rewardItem then
				sendAddItemToContainer(self.character:getInventory(), rewardItem)
			end
		end
	end
	-- reloads player inventory
	getPlayerInventory(self.character:getPlayerNum()):refreshBackpacks();
	getPlayerLoot(self.character:getPlayerNum()):refreshBackpacks();
end

function ISCharmWormsAction:new (character, entity, rod)
	local o = ISBaseTimedAction.new(self, character)
	o.character 	= character;	-- Class: IsoPlayer, extends IsoGameCharacter
	o.entity 		= entity 		-- Class: IsoObject
	o.tool 			= rod; 		-- Class: HandWeapon, extends InventoryItem
	o.maxTime 		= self:getDuration();
	o.eventName 	= "DiggingPit_CharmWormsEvent"; -- Has to match <m_EventName> 	from media/AnimSets/player/actions
	o.text 			= getText("ContextMenu_CharmWorms");
	o.animName 		= "DiggingPit_CharmWorms"; 		-- Has to match <m_Name> 		from media/AnimSets/player/actions
	o.soundProgress = "MakeFireNotchedPlank";
	o.soundFinished = "";
	o.soundPlaying 	= nil;			-- Used to store the id of the sound playing, so it can be stopped later
	o.stopOnWalk 	= true;
	o.stopOnRun 	= true;
	o.stopOnAim 	= true;
	o.time 			= getTimestampMs()
	return o	
end

function ISCharmWormsAction:getDuration()
	return 3000 -- Anim: 4.084s
end