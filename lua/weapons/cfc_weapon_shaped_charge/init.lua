AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

function SWEP:PrimaryAttack()

    self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
    
    if self:CanPrimaryAttack() == false then
        local ammo = self:GetOwner():GetAmmoCount( "shapedCharge" )
        
        if ammo == 0 then
            self:GetOwner():StripWeapon( "cfc_weapon_shaped_charge" )
            return
        end
        
        self:GetOwner():SetAmmo( ammo-1, "shapedCharge" )
        self:SetClip1( 1 )
    end
    
    local viewTrace = {}
	viewTrace.start = self:GetOwner():GetShootPos()
	viewTrace.endpos = self:GetOwner():GetShootPos() + 100 * self:GetOwner():GetAimVector()
	viewTrace.filter = {self:GetOwner()}
	local trace = util.TraceLine( viewTrace )
        
    local hitWorld = trace.HitNonWorld == false
    local maxCharges = GetConVar( "cfc_shaped_charge_maxcharges" ):GetInt()
    local hasMaxCharges = ( self:GetOwner().plantedCharges or 0 ) >= maxCharges
    local isPlayer = trace.Entity:IsPlayer()
    local isNPC = trace.Entity:IsNPC()
    
    if hitWorld or hasMaxCharges or isPlayer or isNPC then
        self:GetOwner():EmitSound( "common/wpn_denyselect.wav", 100, 100, 1, CHAN_WEAPON )
        return
    end
    
    if trace.Entity:IsValid() then
        local bomb = ents.Create( "cfc_shaped_charge" )
		bomb:SetPos( trace.HitPos )
        
        local FixAngles = trace.HitNormal:Angle()
        local FixRotation = Vector( 270, 180, 0 )

        FixAngles:RotateAroundAxis(FixAngles:Right(), FixRotation.x)
        FixAngles:RotateAroundAxis(FixAngles:Up(), FixRotation.y)
        FixAngles:RotateAroundAxis(FixAngles:Forward(), FixRotation.z)
        
        bomb:SetAngles( FixAngles )
		bomb.bombOwner = self:GetOwner()
        bomb:SetParent( trace.Entity )
		bomb:Spawn()
        
        self:TakePrimaryAmmo( 1 )
    end

    if self:GetOwner():GetAmmoCount( "shapedCharge" ) <= 0 then
        self:GetOwner():StripWeapon( "cfc_weapon_shaped_charge" )
    end
    
end

function SWEP:SecondaryAttack()
    self:PrimaryAttack()
    self:SetNextSecondaryFire( CurTime() + self.Primary.Delay )
end
