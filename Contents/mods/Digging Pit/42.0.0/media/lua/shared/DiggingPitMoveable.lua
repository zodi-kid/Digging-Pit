local function diggingPitDefinition()
    local moveableDefinitions = ISMoveableDefinitions.getInstance()
    if not moveableDefinitions then
        print("[DiggingPit]: 	ERROR: ISMoveableDefinitions.getInstance() returned nil")
        return
    end
    moveableDefinitions.addScrapDefinition( "DiggingPit", {"Base.Shovel"}, {}, Perks.Woodwork, 0, "Shoveling", true);
    moveableDefinitions.addScrapItem("DiggingPit", "Base.Stone2", 4, 90);    
    print("[DiggingPit]: 	Added Digging Pit to Moveable Definitions")
end

local function setDiggingPitMaterial()
    local spriteNames = {
        "digging_pit_0",
        "digging_pit_1",
        "digging_pit_2",
        "digging_pit_3",
    }

    for _, spriteName in ipairs(spriteNames) do
        local sprite = getSprite(spriteName) -- from IsoSpriteManager; returns IsoSprite

        if sprite then
            local properties = sprite:getProperties()
            properties:set("Material", "DiggingPit")

            print("[DiggingPit] Set Material=DiggingPit for " .. spriteName)
        else
            print("[DiggingPit] ERROR: Could not find sprite " .. spriteName)
        end
    end
end

Events.OnGameBoot.Add(diggingPitDefinition)
Events.OnGameStart.Add(setDiggingPitMaterial)
