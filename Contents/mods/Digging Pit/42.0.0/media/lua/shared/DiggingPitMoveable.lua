-- Create new scrapping definition with new 'material' associated
local function setDiggingPitDefinition()
	-- ISMoveableDefinitions is supposed to be a singleton, so using it this way should be fine
    local moveableDefinitions = ISMoveableDefinitions.getInstance()
    if not moveableDefinitions then
        print("[DiggingPit]: 	ERROR: ISMoveableDefinitions.getInstance() returned nil")
        return
    end
	-- Use material 'DiggingPit', which we add in the next line; Perks.Woodwork is a placeholder to avoid errors
    moveableDefinitions.addScrapDefinition( "DiggingPit", {"Base.Shovel"}, {}, Perks.Woodwork, 10, "Shoveling", true);
    moveableDefinitions.addScrapItem("DiggingPit", "Base.Worm", 4, 90);
end

-- Because TileZed only allows materials from vanilla, we have to change it dynamically
local function setDiggingPitMaterial()
    local spriteNames = {
        "digging_pit_0",
        "digging_pit_1",
        "digging_pit_2",
        "digging_pit_3",
    }
	-- Change the 'material' property for all sprites
    for _, spriteName in ipairs(spriteNames) do
        local sprite = getSprite(spriteName) -- from IsoSpriteManager; returns IsoSprite
        if sprite then
			local properties = sprite:getProperties()
            properties:set("Material", "DiggingPit")
			--properties:set("Material", "Natural")
        else
            print("[DiggingPit]:	ERROR: Could not find sprite " .. spriteName)
        end
    end
end

Events.OnGameBoot.Add(setDiggingPitDefinition)
Events.OnInitGlobalModData.Add(setDiggingPitMaterial)
