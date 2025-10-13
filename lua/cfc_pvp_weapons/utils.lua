CFCPvPWeapons = CFCPvPWeapons or {}

--- Selects an outcome from a weighted list of options.
---
--- @param outcomes table A list of outcome tables, each containing a `Weight` field (a positive number).
--- The outcomes must be sorted in descending order by weight.
--- You can auto-sort the list using `table.SortByMember( outcomes, "Weight", false )`.
--- CAUTION: A `_weightAccum` field will be written to each outcome table.
--- @param filter function? An optional filter function that takes an outcome and returns true to include it or false to exclude it.
--- @param predictionName string? An optional name to use for prediction-safe rng.
--- @return table The selected outcome table. nil if no valid outcomes are available.
function CFCPvPWeapons.GetWeightedOutcome( outcomes, filter, predictionName )
    local totalWeight = 0

    for _, outcome in ipairs( outcomes ) do
        if filter and not filter( outcome ) then
            outcome._weightAccum = false
        else
            totalWeight = totalWeight + outcome.Weight
            outcome._weightAccum = totalWeight
        end
    end

    local roll

    if predictionName and IsValid( GetPredictionPlayer() ) then
        roll = util.SharedRandom( predictionName, 0, totalWeight, GetPredictionPlayer():GetCurrentCommand():CommandNumber() )
    else
        roll = math.Rand( 0, totalWeight )
    end

    for _, outcome in ipairs( outcomes ) do
        local accum = outcome._weightAccum

        if accum and roll <= accum then
            return outcome
        end
    end
end
