-- Create new scrapping definition with new 'material' associated
local function setDiggingPitDefinition()
	-- ISMoveableDefinitions is supposed to be a singleton, so using it this way should be fine
    local moveableDefinitions = ISMoveableDefinitions.getInstance()
    if not moveableDefinitions then
        print("[DiggingPit]: 	ERROR: ISMoveableDefinitions.getInstance() returned nil")
        return
    end
	-- Use material 'DiggingPit', which we add in the next line; Perks.Woodwork is a placeholder to avoid errors
	--moveableDefinitions.addToolDefinition("DiggingPit", {"Base.Shovel"}, Perks.Woodwork, 10, "Shoveling", true);
    moveableDefinitions.addScrapDefinition("DiggingPit", {"Base.Shovel"}, {}, Perks.Woodwork, 10, "Shoveling", true);
    moveableDefinitions.addScrapItem("DiggingPit", "Base.Worm", 4, 90);
end

Events.OnGameBoot.Add(setDiggingPitDefinition)