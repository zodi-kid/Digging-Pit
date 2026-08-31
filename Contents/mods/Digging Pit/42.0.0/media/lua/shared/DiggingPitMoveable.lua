-- Create new scrapping definition for DiggingPit material
local function setDiggingPitDefinition()
	-- ISMoveableDefinitions is supposed to be a singleton, so using it this way should be fine
    local moveableDefinitions = ISMoveableDefinitions.getInstance()
    if not moveableDefinitions then
        print("[DiggingPit]: 	ERROR: ISMoveableDefinitions.getInstance() returned nil")
        return
    end
	-- Use material 'DiggingPit', which we add in the next line; Perks.Farming is a placeholder to avoid errors
    moveableDefinitions.addScrapDefinition("DiggingPit", {"Base.Shovel"}, {}, Perks.Farming, 200, "Shoveling", true);
	moveableDefinitions.scrapDefinitions["DiggingPit"].recipeAnimNode = "DiggingPit_DigStone"
	moveableDefinitions.scrapDefinitions["DiggingPit"].recipeProp1 = "Shovel" -- Can't find a way to use tool from inventory
	-- Rewards for dismantling; they are required, but we set them to chance 0 so they are never produced
	moveableDefinitions.addScrapItem("DiggingPit", "Base.Stone2", 1, 0);
end

Events.OnGameBoot.Add(setDiggingPitDefinition)