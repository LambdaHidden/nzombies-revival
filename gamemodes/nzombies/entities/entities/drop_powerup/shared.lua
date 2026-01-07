AddCSLuaFile()

ENT.Type = "anim"
 
ENT.PrintName		= "drop_powerups_private"
ENT.Author			= "Alig96 and Hidden"
ENT.Contact			= "Don't"
ENT.Purpose			= ""
ENT.Instructions	= ""

function ENT:SetupDataTables()
	self:NetworkVar( "String", 0, "PowerUp" )
end

function ENT:Initialize()

	--self:SetPowerUp("dp")
	--self:SetModelScale(nzPowerUps:Get(self:GetPowerUp()).scale, 1)
	
	--self:PhysicsInit(SOLID_VPHYSICS)
	self:PhysicsInitSphere(60, "default_silent")
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_NONE)
	if SERVER then
		self:SetTrigger(true)
		self:SetUseType(SIMPLE_USE)
	else
		self.NextParticle = CurTime()
	end
	self:UseTriggerBounds(true, 20)
	--self:SetMaterial("models/shiny.vtf")
	--self:SetColor( Color(255,215,0) )
	--self:SetTrigger(true)
	
	--[[timer.Create( self:EntIndex().."_deathtimer", 30, 1, function()
		if IsValid(self) then
			timer.Destroy(self:EntIndex().."_deathtimer")
			if SERVER then
				self:Remove()
			end			
		end
	end)]]
	self.RemoveTime = CurTime() + 30
	
	local powerupData = nzPowerUps:Get(self:GetPowerUp())
	self.IsGlobal = powerupData.global
	
	if CLIENT then
		local tempPrivate = {}
		local tempGlobal = {}
		
		for k, v in ipairs(ents.FindByClass("drop_powerup")) do
			if v.IsGlobal then
				table.insert(tempGlobal, v)
			else
				table.insert(tempPrivate, v)
			end
		end
		privatePowerups = tempPrivate
		globalPowerups = tempGlobal
	end
end

if SERVER then
	function ENT:StartTouch(hitEnt)
		if (hitEnt:IsValid() and hitEnt:IsPlayer()) then
			nzPowerUps:Activate(self:GetPowerUp(), hitEnt, self)
			self:StopSound( "power_up_loop" )
			self:Remove()
		end
	end
	
	function ENT:Think()
		if self.RemoveTime and CurTime() > self.RemoveTime then
			self:StopSound( "power_up_loop" )
			self:Remove()
		end
	end
end

if CLIENT then
	--local glow = Material ( "sprites/glow04_noz" )
	--local col = Color(0,200,255,255)
	
	local particledelay = 0.1
	
	function ENT:Draw()
		if CurTime() > self.NextParticle then
			local effectdata = EffectData()
			effectdata:SetOrigin( self:GetPos() )
			util.Effect( self.IsGlobal and "powerup_glow" or "powerup_glow_private", effectdata )
			self.NextParticle = CurTime() + particledelay
		end
		self:DrawModel()
	end
	
	function ENT:Think()
		if !self:GetRenderAngles() then self:SetRenderAngles(self:GetAngles()) end
		self:SetRenderAngles(Angle(0,60,20)*math.sin((self.RemoveTime - CurTime())*0.6) + Angle(20,0,0)*math.sin((self.RemoveTime - CurTime())*0.4))
	end
	
	local privatePowerups = {}
	local globalPowerups = {}
	
	local color_private = Color( 0, 100, 200 )
	local color_global = Color( 50, 175, 50 )
	hook.Add( "PreDrawHalos", "drop_powerups_halos", function()
		--halo.Add( ents.FindByClass( "drop_powerup_private" ), Color( 0, 100, 200 ), 8, 8, 9 )
		halo.Add( privatePowerups, color_private, 2, 2, 2 )
		halo.Add( globalPowerups, color_global, 2, 2, 2 )
	end )
end
