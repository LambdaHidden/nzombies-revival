
	-- Weapon base courtesy of CptFuzzies SWEP Bases project
	-- Recoded to do more balanced damage

SWEP.Author			= ""
SWEP.Contact		= ""
SWEP.Purpose		= ""
SWEP.Instructions	= ""

SWEP.ViewModelFOV	= 60
SWEP.ViewModelFlip	= false
SWEP.ViewModel		= "models/weapons/knife/v_knife.mdl"
SWEP.WorldModel		= "models/weapons/knife/w_knife.mdl"
--SWEP.AnimPrefix		= "crowbar"
SWEP.HoldType		= "knife"

SWEP.UseHands = true

SWEP.Spawnable			= false
SWEP.AdminSpawnable		= false
--SWEP.DrawCrosshair		= false

CROWBAR_RANGE	= 75.0
CROWBAR_REFIRE	= 0.4

--SWEP.Primary.Sound			= "nz/knife/weapons/whoosh.wav"
--SWEP.Primary.Hit			= Sound("nz/bowie/swing/bowie_swing_01")
SWEP.Primary.Range			= CROWBAR_RANGE
SWEP.Primary.Damage			= 75
SWEP.Primary.DamageType		= DMG_CLUB
SWEP.Primary.Force			= 0.75
SWEP.Primary.ClipSize		= -1
SWEP.Primary.Delay			= CROWBAR_REFIRE
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic		= true
SWEP.Primary.Ammo			= "None"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= "None"

SWEP.NZPreventBox = true



/*---------------------------------------------------------
   Name: SWEP:Initialize( )
   Desc: Called when the weapon is first loaded
---------------------------------------------------------*/
function SWEP:Initialize()
	self:SetWeaponHoldType( self.HoldType )
end


/*---------------------------------------------------------
   Name: SWEP:PrimaryAttack( )
   Desc: +attack1 has been pressed
---------------------------------------------------------*/
function SWEP:PrimaryAttack()

	// Only the player fires this way so we can cast
	local pPlayer		= self.Owner;

	if ( !pPlayer ) then
		return;
	end

	// Make sure we can swing first
	if ( !self:CanPrimaryAttack() ) then return end

	local vecSrc		= pPlayer:GetShootPos();
	local vecDirection	= pPlayer:GetAimVector();

	local trace			= {}
		trace.start		= vecSrc
		trace.endpos	= vecSrc + ( vecDirection * self:GetRange() )
		trace.filter	= pPlayer
	
	local traceHit		= util.TraceLine( trace )

	if ( traceHit.Hit ) then

		if math.random(0,1) == 0 then
			self:SendWeaponAnim( ACT_VM_HITCENTER )
			pPlayer:SetAnimation( PLAYER_ATTACK1 )
			self.nzHolsterTime = CurTime() + 1
			self:EmitSound("nz/knife/knife_stab.wav")
			--timer.Simple(0.1, function() self:EmitSound("nz/knife/knife_stab.wav") end)
		else
			self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
			pPlayer:SetAnimation( PLAYER_ATTACK1 )
			self.nzHolsterTime = CurTime() + 0.5
			self:EmitSound("nz/knife/knife_slash.wav")
			--timer.Simple(0.1, function() self:EmitSound("nz/knife/knife_slash.wav") end)
			--self.Owner:ViewPunch( Angle( math.Rand(-3, -2.5), math.Rand(-7, -4.5), 0 ) )
		end

		self.Weapon:SetNextPrimaryFire( CurTime() + self:GetFireRate() );
		self.Weapon:SetNextSecondaryFire( CurTime() + self.Weapon:SequenceDuration() );

		self:Hit( traceHit, pPlayer )
		--timer.Simple(0.1, function() self:Hit( traceHit, pPlayer ); end)

		return

	end

	self.Weapon:EmitSound("nz/knife/whoosh.wav")

	self.Weapon:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
	pPlayer:SetAnimation( PLAYER_ATTACK1 );
	--self.Owner:ViewPunch( Angle( math.Rand(-3, -2.5), math.Rand(-7, -4.5), 0 ) )

	self.Weapon:SetNextPrimaryFire( CurTime() + self:GetFireRate() );
	self.Weapon:SetNextSecondaryFire( CurTime() + self.Weapon:SequenceDuration() );

	self:Swing( traceHit, pPlayer );

	return

end


/*---------------------------------------------------------
   Name: SWEP:SecondaryAttack( )
   Desc: +attack2 has been pressed
---------------------------------------------------------*/
function SWEP:SecondaryAttack()
	return false
end

/*---------------------------------------------------------
   Name: SWEP:Reload( )
   Desc: Reload is being pressed
---------------------------------------------------------*/
function SWEP:Reload()
	return false
end

//-----------------------------------------------------------------------------
// Purpose: Get the damage amount for the animation we're doing
// Input  : hitActivity - currently played activity
// Output : Damage amount
//-----------------------------------------------------------------------------
function SWEP:GetDamageForActivity( hitActivity )
	return nzRound:InProgress() and 30 + (45/nzRound:GetNumber()) or 75
end

/*---------------------------------------------------------
   Name: SWEP:Deploy( )
   Desc: Whip it out
---------------------------------------------------------*/
function SWEP:Deploy()

	self.Weapon:SendWeaponAnim( ACT_VM_DRAW )
	self:SetDeploySpeed( self.Weapon:SequenceDuration() )

	return true

end


function SWEP:Hit( traceHit, pPlayer )

	local vecSrc = pPlayer:GetShootPos();

	if ( SERVER ) then
		pPlayer:TraceHullAttack( vecSrc, traceHit.HitPos, Vector( -5, -5, -5 ), Vector( 5, 5, 36 ), self:GetDamageForActivity(), self.Primary.DamageType, self.Primary.Force );
	end

	// self:AddViewKick();

end



function SWEP:Swing( traceHit, pPlayer )
end


function SWEP:CanPrimaryAttack()
	return true
end


function SWEP:CanSecondaryAttack()
	return false
end

function SWEP:SetDeploySpeed( speed )

	self.m_WeaponDeploySpeed = tonumber( speed / GetConVarNumber( "phys_timescale" ) )

	self.Weapon:SetNextPrimaryFire( CurTime() + speed )
	self.Weapon:SetNextSecondaryFire( CurTime() + speed )

end



function SWEP:Drop( vecVelocity )
if ( !CLIENT ) then
	self:Remove();
end
end

function SWEP:GetRange()
	return	self.Primary.Range;
end

function SWEP:GetFireRate()
	return	self.Primary.Delay;
end