AddCSLuaFile()

cfc_simple_weapons.Include( "Convars" )


local tableInsert = table.insert
local mathCos = math.cos
local mathSin = math.sin
local mathDeg = math.deg
local mathClamp = math.Clamp

local PI_2 = math.pi * 2

local gridPattern
local ringsPattern


-- Primary fire
function SWEP:CanPrimaryFire()
    if self:HandleReloadAbort() then
        return false
    end

    if self:IsEmpty() then
        local ply = self:GetOwner()

        if ply:IsNPC() then
            if SERVER then
                ply:SetSchedule( SCHED_RELOAD ) -- Metropolice don't like reloading...
            end

            return false
        end

        if self:GetBurstFired() == 0 then
            self:Reload()
        end

        if not self:IsReloading() then
            self:EmitEmptySound()
        end

        self:SetNextFire( CurTime() + 0.2 )
        self:ForceStopFire()

        return false
    end

    return true
end

function SWEP:PrimaryFire()
    self:UpdateAutomatic()
    self:ConsumeAmmo()

    self:FireWeapon()

    local delay = self:GetDelay()

    self:ApplyRecoil()

    if self:ShouldPump() then
        self:SetNeedPump( true )
    end

    self:SetNextIdle( CurTime() + self:SequenceDuration() )
    self:SetNextFire( CurTime() + delay )
end

-- Alt fire
function SWEP:TryAltFire()
    if self:GetNextAltFire() > CurTime() or not self:CanAltFire() then
        return
    end

    self:AltFire()
end

function SWEP:CanAltFire()
    return true
end

function SWEP:AltFire()
end

function SWEP:UpdateAutomatic()
    local primary = self.Primary
    local firemode = self:GetFiremode()

    if firemode == 0 then
        primary.Automatic = false
    else
        primary.Automatic = true
    end

    if firemode > 0 then
        local count = self:GetBurstFired()

        if count + 1 >= firemode then
            self:ForceStopFire()
            self:SetBurstFired( 0 )
        else
            self:SetBurstFired( count + 1 )
        end
    end
end

function SWEP:FireWeapon()
    local ply = self:GetOwner()

    self:EmitFireSound()
    self:SendTranslatedWeaponAnim( ACT_VM_PRIMARYATTACK )
    ply:SetAnimation( PLAYER_ATTACK1 )
    self:HandleBullets()
end

function SWEP:HandleBullets()
    local ply = self:GetOwner()
    local primary = self.Primary
    local count = primary.Count
    if count <= 0 then return end

    local patternInfo = primary.SpreadPattern
    local damage = self:GetDamage()
    local dir = self:GetShootDir()

    local bullet = {
        Num = count,
        Src = ply:GetShootPos(),
        Dir = dir,
        TracerName = primary.TracerName,
        Tracer = primary.TracerName == "" and 0 or primary.TracerFrequency,
        Force = damage * 0.25,
        Damage = damage,
        Callback = function( _attacker, tr, dmg )
            dmg:ScaleDamage( self:GetDamageFalloff( tr.StartPos:Distance( tr.HitPos ) ) )
        end,
    }

    -- Regular spread mechanics
    if not patternInfo then
        bullet.Spread = self:GetSpread()
        self:ModifyBulletTable( bullet )
        if bullet.DontShoot then return end

        ply:FireBullets( bullet )

        return
    end

    -- Fixed spread
    bullet.Num = 1
    bullet.Spread = Vector( 0, 0, 0 )
    self:ModifyBulletTable( bullet )
    if bullet.DontShoot then return end

    local patternType = patternInfo.Type
    local dirAng = dir:Angle()
    local down = -dirAng:Up()
    local right = dirAng:Right()
    local xs, ys

    if patternType == "grid" then
        xs, ys = gridPattern( count, patternInfo, self )
    elseif patternType == "rings" then
        xs, ys = ringsPattern( count, patternInfo, self )
    else
        xs, ys = patternInfo.Func( count, patternInfo, self )
    end

    for i = 1, count do
        local ang = dir:Angle()
        ang:RotateAroundAxis( right, mathDeg( ys[i] ) )
        ang:RotateAroundAxis( down, mathDeg( xs[i] ) )

        bullet.Dir = ang:Forward()

        ply:FireBullets( bullet )
    end

    ply:FireBullets( bullet )
end

-- Allows the bullet table to be modified.
-- If you add `DontShoot = true` to the table, the bullet will not be fired.
function SWEP:ModifyBulletTable( _bullet )
end

function SWEP:ShouldPump()
    return self.Primary.PumpAction
end


----- PRIVATE FUNCTIONS -----

gridPattern = function( count, patternInfo, _wep )
    local rowCount = math.min( patternInfo.RowCount, count )
    local spreadX = patternInfo.SpreadX or patternInfo.Spread
    local spreadY = patternInfo.SpreadY or spreadX

    local colCount = count / rowCount
    local colCountFloor = math.floor( colCount )
    local lastColCount = nil

    if colCountFloor ~= colCount then
        local missingBullets = count - colCountFloor * rowCount
        lastColCount = missingBullets
        colCount = colCountFloor
        rowCount = rowCount + 1
    end

    local xs = {}
    local ys = {}

    local rowEndInd = rowCount - 1
    local colEndInd = colCount - 1
    local rowMult = 2 / rowEndInd
    local colMult = 2 / colEndInd
    local rowAdd = -1
    local colAdd = -1

    local colMultPost = 1

    if rowEndInd == 0 then
        rowMult = 0
        rowAdd = 0
    end

    if colEndInd == 0 then
        colMult = 0
        colAdd = 0
    end

    for r = 0, rowEndInd do
        local y = spreadY * ( r * rowMult + rowAdd )

        -- In case the number of bullets doesn't divide into the rows evenly.
        if lastColCount and r == rowEndInd then
            if lastColCount <= 1 then
                colEndInd = 0
                colMult = 0
                colAdd = 0
            elseif colCount <= 1 then
                colEndInd = lastColCount - 1
                colMult = 2 / colEndInd
                colAdd = -1
            else
                colEndInd = lastColCount - 1
                colMult = 2 / ( colEndInd * ( colCount - 1 ) )
                colAdd = -1 / ( colCount - 1 )

                if lastColCount < colCount then
                    colMultPost = 2
                end
            end
        end

        for c = 0, colEndInd do
            local x = spreadX * ( c * colMult + colAdd ) * colMultPost
            tableInsert( xs, x )
            tableInsert( ys, y )
        end
    end

    return xs, ys
end

ringsPattern = function( count, patternInfo, _wep )
    local rings = patternInfo.Rings

    local ringCount = #rings
    local bulletsLeft = count
    local xs = {}
    local ys = {}

    for i = 1, ringCount do
        local ring = rings[i]
        local amount = i == ringCount and bulletsLeft or mathClamp( ring.Count or math.huge, 0, bulletsLeft )
        local spreadX = ring.SpreadX or ring.Spread or 0
        local spreadY = ring.SpreadY or spreadX
        local thetaMult = ring.ThetaMult or 1
        local thetaAdd = ring.ThetaAdd or 0

        if amount <= 0 then
            thetaMult = 0
        else
            thetaMult = thetaMult * PI_2 / amount
        end

        for i2 = 0, amount - 1 do
            local theta = i2 * thetaMult + thetaAdd

            tableInsert( xs, spreadX * mathCos( theta ) )
            tableInsert( ys, spreadY * mathSin( theta ) )
        end

        bulletsLeft = bulletsLeft - amount

        if bulletsLeft <= 0 then break end
    end

    return xs, ys
end
