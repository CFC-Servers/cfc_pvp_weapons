AddCSLuaFile()

DEFINE_BASECLASS( "cfc_simple_ent_grenade_base" )

ENT.Base = "cfc_simple_ent_grenade_base"

ENT.Model = Model( "models/weapons/w_eq_fraggrenade.mdl" )

ENT.BubbleRadius = 200
ENT.BubbleDuration = 5
ENT.BubbleGrowDuration = 0.25
ENT.BubbleShrinkDuration = 0.25
ENT.EffectLingerOutsideBubble = 0


local uniqueIncr = 0

local setModelScale


function ENT:Explode()
    local bubble, cosmeticBubbles = self:CreateBubble()

    cosmeticBubbles = cosmeticBubbles or {}

    if not IsValid( bubble ) then
        self:Remove()
        return
    end

    if not setModelScale then
        local entMeta = FindMetaTable( "Entity" )

        -- Get the original function, in case the server wraps it for anticrash purposes.
        setModelScale = entMeta._SetModelScale or entMeta.SetModelScale
    end

    uniqueIncr = uniqueIncr + 1
    local bubbleID = uniqueIncr
    local selfObj = self

    local function setBubbleScale( scale, duration )
        setModelScale( bubble, scale, duration )

        for _, cosmeticBubble in ipairs( cosmeticBubbles ) do
            if IsValid( cosmeticBubble ) then
                local scaleMult = cosmeticBubble._bubbleScaleMult or 1

                setModelScale( cosmeticBubble, scale * scaleMult, duration )
            end
        end
    end

    setBubbleScale( 0.1, 0 )
    bubble:SetUpPhysics()
    bubble:Activate()
    bubble:GetPhysicsObject():EnableMotion( false )
    bubble:SetTrigger( true )


    local touchedEnts = {}

    function bubble:StartTouch( ent )
        if not IsValid( ent ) then return end -- Don't trigger on the world, etc
        if touchedEnts[ent] then return end -- Shouldn't happen more than once per tick, but for just in case.

        local didTouch = selfObj:BubbleStartTouch( ent ) -- Allow the grenade to tell us it ignored the touch, so we don't trigger its end touch later.
        if not didTouch then return end

        touchedEnts[ent] = true

        if selfObj.EffectLingerOutsideBubble > 0 then
            timer.Remove( "CFC_PvPWeapons_BubbleGrenade_EndEffectLinger_" .. bubbleID .. "_" .. ent:EntIndex() )
        end
    end

    function bubble:Touch( ent )
        if not IsValid( ent ) then return end
        if not touchedEnts[ent] then return end -- Ignore touches that the grenade ignored.

        selfObj:BubbleTouch( ent )
    end

    function bubble:EndTouch( ent )
        if not IsValid( ent ) then return end
        if not touchedEnts[ent] then return end -- Ignore touches that the grenade ignored.

        selfObj:BubbleEndTouch( ent )
        touchedEnts[ent] = nil

        local linger = selfObj.EffectLingerOutsideBubble

        if linger <= 0 then
            selfObj:BubbleEndEffect( ent )
        else
            timer.Create( "CFC_PvPWeapons_BubbleGrenade_EndEffectLinger_" .. bubbleID .. "_" .. ent:EntIndex(), linger, 1, function()
                if not IsValid( ent ) then return end

                selfObj:BubbleEndEffect( ent )
            end )
        end
    end


    local bubbleScale = self.BubbleRadius / 8
    local bubbleDuration = self.BubbleDuration
    local bubbleGrowDuration = self.BubbleGrowDuration
    local bubbleShrinkDuration = self.BubbleShrinkDuration

    -- Grow the bubble
    timer.Simple( 0, function()
        if not IsValid( bubble ) then return end

        setBubbleScale( bubbleScale, bubbleGrowDuration )
    end )

    -- Update the bubble's physics
    timer.Create( "CFC_PvPWeapons_BubbleGrenade_UpdateBubblePhys_" .. bubbleID, bubbleGrowDuration, 1, function()
        if not IsValid( bubble ) then return end

        setBubbleScale( bubbleScale, 0 ) -- Re-apply scale with deltatime of 0 to avoid slight desyncs and inconsistencies due to sorse jank.

        bubble:Activate()
        bubble:GetPhysicsObject():EnableMotion( false )
    end )

    -- Shrink the bubble
    if bubbleShrinkDuration > 0 then
        timer.Simple( bubbleDuration - bubbleShrinkDuration, function()
            if not IsValid( bubble ) then return end

            setBubbleScale( 0.1, bubbleShrinkDuration )
        end )
    end

    local _OnRemove = self.OnRemove or function() end

    -- Remove the bubble.
    -- Without the extra 1-tick delay, this will sometime cause a MASSIVE lag spike due to the cosmetic bubbles being removed while SetModelScale's deltatime is still running.
    -- No idea why that would happen, nor why it only happens with the cosmetic bubbles, but this fixes it.
    timer.Simple( bubbleDuration + engine.TickInterval(), function()
        local linger = selfObj.EffectLingerOutsideBubble

        -- Start the EndEffectLinger for all ents currently in the bubble, as :Remove() won't trigger :EndTouch().
        for ent in pairs( touchedEnts ) do
            if IsValid( ent ) then
                timer.Create( "CFC_PvPWeapons_BubbleGrenade_EndEffectLinger_" .. bubbleID .. "_" .. ent:EntIndex(), linger, 1, function()
                    if not IsValid( ent ) then return end
                    if not IsValid( selfObj ) then return end

                    selfObj:BubbleEndEffect( ent )
                end )
            end
        end

        for _, cosmeticBubble in ipairs( cosmeticBubbles ) do
            if IsValid( cosmeticBubble ) then
                cosmeticBubble:Remove()
            end
        end

        if IsValid( bubble ) then
            bubble:Remove()
        end

        -- Remove the grenade after enough time passes for all lingers to finish.
        -- This is so the grenade can continue to handle the logic of effects as they linger.
        timer.Simple( linger + 0.25, function()
            if not IsValid( selfObj ) then return end
            selfObj.OnRemove = _OnRemove -- No need for the early-remove check anymore.
            selfObj:Remove()
        end )
    end )

    -- Keep the grenade entity around to call functions on it and retain ownership, etc.
    function self:Think() end

    self:SetCollisionGroup( COLLISION_GROUP_IN_VEHICLE )
    self:SetNotSolid( true )
    self:GetPhysicsObject():EnableMotion( false )
    self:GetPhysicsObject():SetMass( 50000 )
    self:SetColor( Color( 0, 0, 0, 0 ) )
    self:SetMaterial( "engine/writestencil" )
    self:DrawShadow( false )

    -- Extra precautionary measures for if the grenade gets removed early by a map cleanup or something else.
    function self:OnRemove()
        for ent in pairs( touchedEnts ) do
            if IsValid( ent ) then
                timer.Remove( "CFC_PvPWeapons_BubbleGrenade_EndEffectLinger_" .. bubbleID .. "_" .. ent:EntIndex() )
                self:BubbleEndEffect( ent )
                touchedEnts[ent] = nil
            end
        end

        _OnRemove( self )
    end
end

function ENT:CreateBubble()
    local pos = self:WorldSpaceCenter()
    local bubble = ents.Create( "cfc_simple_ent_bubble" )
    bubble:SetPos( pos )
    bubble:SetAngles( Angle( 0, 0, 0 ) )
    bubble:Spawn()
    bubble:SetBubbleRadius( self.BubbleRadius )

    local cosmeticBubbles = {} -- Provide more bubble entities for adding extra visual layers. You can also add ent._bubbleScaleMult = NUMBER to them to scale them differently.

    return bubble, cosmeticBubbles
end

-- When an entity enters the bubble. Return true/false for if the entity should be affected by the bubble.
function ENT:BubbleStartTouch( _ent )
end

-- Called every tick while an allowed entity is inside the bubble.
function ENT:BubbleTouch( _ent )
end

-- Called when an allowed entity leaves the bubble.
function ENT:BubbleEndTouch( _ent )
end

-- Called when an allowed entity leaves the bubble, after the linger time.
function ENT:BubbleEndEffect( _ent )
end
