-- Spawns the super cinderblock randomly on maps with navmesh
-- if terminator nextbot is installed

local newEvent = {
    defaultPercentChancePerMin = 0.05, -- very rare

    navmeshEvent = true,
    variants = {
        {
            variantName = "theSuperCinderBlock",
            getIsReadyFunc = nil,
            unspawnedStuff = {
                {
                    class = "cfc_cinder_block",
                    spawnAlgo = "steppedRandomRadius", -- randomly spawn it somewhere in the map

                }
            },
            thinkInterval = nil, -- makes it default to terminator_Extras.activeEventThinkInterval
            concludeOnMeet = true,
        },
    },
}

terminator_Extras.RegisterEvent( newEvent, "cfc_pvp_weapons_supercinder" )
