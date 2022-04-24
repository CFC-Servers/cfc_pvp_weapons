include( "shared.lua" )

AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )


function SWEP:PrimaryAttack()
    self.plantTime = GetConVar( self.spawnClass .. "_planttime" ):GetInt()
    local canPlace = self:CanPlace()
    if not canPlace then self:GetOwner():EmitSound( "common/wpn_denyselect.wav", 100, 100, 1, CHAN_WEAPON ) return end
    if self.plantTime > 0 then
        self:StartPlanting( self:GetOwner() )
    else
        self:PlantCharge()
    end
end

function SWEP:StartPlanting( planter )
    if not self:CanStartNewPlant( planter ) then return end 
    self.NextPlantingSound = CurTime() + 1
    self.PlantingStartTime = CurTime()
    self.PlantingEndTime = CurTime() + self.plantTime
    self.PlantingStartEntity = planter:GetEyeTraceNoCursor().Entity
    self:PlantingThink( planter )
    self:EmitSound( "Plastic_Box.Strain", 80, 100 )
    self:EmitSound( "weapons/slam/mine_mode.wav", 80, 150 )
    self:EmitSound( "common/wpn_select.wav", 80, 130 )
    
    self.PlantingRoughness = CreateSound( self, "physics/flesh/flesh_scrape_rough_loop.wav" )
    self.PlantingRoughness:Play()

    local VMod = planter:GetViewModel()
    local rate = VMod:SequenceDuration( 3 )
    VMod:SendViewModelMatchingSequence( 3 )
    VMod:SetPlaybackRate( rate / self.plantTime )
    VMod:FrameAdvance()

end

function SWEP:CanStartNewPlant( planter ) 
    if self.plantTime <= 0 or not self.plantTime then return end
    if planter:GetVelocity():Length() > 65 then return false end
    if not planter:Alive() then return false end
    return true
end

function SWEP:ValidPlanting( planter )
    if not IsValid( self ) or not IsValid( planter ) then return false end
    if not planter:Alive() then return false end
    local trace = planter:GetEyeTraceNoCursor()
    if self.PlantingStartEntity ~= trace.Entity then return end
    if trace.StartPos:Distance( trace.HitPos ) > 100 then return false end
    if planter:GetVelocity():Length() > 65 then return false end
    return true 
end

function SWEP:PlantingThink( planter )
    if self.PlantingEndTime < CurTime() then self:PlantCharge() self:PlantingExit( planter ) return end
    local timePassed = CurTime() - self.PlantingStartTime
    timer.Simple( 0.1, function() 
        if not IsValid( self ) or not IsValid( planter ) then return end
        if not self:ValidPlanting( planter ) then self:PlantingExit( planter ) return end
        self:PlantingThink( planter ) 
    end )
    if self.NextPlantingSound > CurTime() then return end
    local timerDelay = math.Clamp( self.plantTime / timePassed - 1, 0.5, 1 )
    self.NextPlantingSound = CurTime() + timerDelay
    local Pitch = math.Clamp( 90 + timePassed * 10, 0, 150 )
end

function SWEP:PlantingExit( planter )
    self.PlantingRoughness:Stop()
    self.NextPlantingSound = CurTime() + 1
    self.PlantingStartTime = CurTime()
    self.PlantingEndTime = CurTime() + self.plantTime
    local VMod = planter:GetViewModel()
    VMod:SendViewModelMatchingSequence( 1 )
    VMod:FrameAdvance()
end


function SWEP:PlantCharge()
    self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )

    if self:CanPrimaryAttack() == false then
        local ammo = self:GetOwner():GetAmmoCount( self.Primary.Ammo )

        if ammo == 0 then
            self:GetOwner():StripWeapon( self.weapClass )
            return
        end

        self:GetOwner():SetAmmo( ammo - 1, self.Primary.Ammo )
        self:SetClip1( 1 )
    end    
    
    local canPlace, trace = self:CanPlace() 

    local bomb = ents.Create( self.spawnClass )
    bomb:SetPos( trace.HitPos )

    bomb.plantableOnPlayers = self.plantableOnPlayers
    bomb.physMaterial = self.physMaterial

    local fixAngles = trace.HitNormal:Angle()
    local fixRotation = Vector( 270, 180, 0 )

    fixAngles:RotateAroundAxis( fixAngles:Right(), fixRotation.x )
    fixAngles:RotateAroundAxis( fixAngles:Up(), fixRotation.y )
    fixAngles:RotateAroundAxis( fixAngles:Forward(), fixRotation.z )

    bomb:SetAngles( fixAngles )
    bomb.bombOwner = self:GetOwner()
    local ent = trace.Entity
    if ent:IsPlayer() then
        local attach = ent:LookupAttachment( "hips" )
        bomb:SetParent( ent, attach )
    else
        bomb:SetParent( ent ) 
    end
    bomb:Spawn()

    self:TakePrimaryAmmo( 1 )

    if self:GetOwner():GetAmmoCount( self.Primary.Ammo ) > 0 then return end
    self:GetOwner():StripWeapon( self.weapClass )

end

function SWEP:SecondaryAttack()
    self:PrimaryAttack()
    self:SetNextSecondaryFire( CurTime() + self.Primary.Delay )
end
