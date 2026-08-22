require "TimedActions/ISBaseTimedAction"

ISDigDirtAction = ISBaseTimedAction:derive("ISDigDirtAction");

function ISDigDirtAction:isValid()
    if isClient() and self.item then
        return 	self.character:getInventory():containsID(self.item:getID()) and
				self.item:hasTag(ItemTag.DIG_GRAVE) and
				not self.item:isBroken();
    else
        return true;
    end
end

function ISDigDirtAction:update()
	--- Called every game tick
	self.character:faceThisObject(self.entity)
end

function ISDigDirtAction:interruptWaitToStart()
	--- Wait until return false
	return false;
end

function ISDigDirtAction:start()
	self:setActionAnim(CharacterActionAnims.Dig);
	
end

function ISDigDirtAction:stop()
	--- When cancelled
	ISBaseTimedAction.stop(self)
end

function ISDigDirtAction:perform()
	--- When finished
	ISBaseTimedAction.perform(self);
	--ISTimedActionQueue.getTimedActionQueue(self.character):onCompleted(self);
	--ISLogSystem.logAction(self);
end

function ISDigDirtAction:new (character, entity, shovel)
	local o = ISBaseTimedAction.new(self, character)
	o.character = character;
	o.entity = entity
	o.item = shovel;
	o.maxTime = 30;
	o.stopOnWalk = true;
	o.stopOnRun = true;
	o.stopOnAim = true;
    --o.caloriesModifier = 1;
	return o
end
