DiggingPitBuild = DiggingPitBuild or {}

function DiggingPitBuild.OnIsValid(params)
    return ISShovelGroundCursor.GetDirtGravelSand(params.square) == "dirt"
end
