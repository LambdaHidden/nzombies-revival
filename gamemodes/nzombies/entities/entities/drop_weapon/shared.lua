AddCSLuaFile()

ENT.Type = "anim"
 
ENT.PrintName		= "drop_weapon"
ENT.Author			= "Alig96 & Hidden"
ENT.Contact			= "Don't"
ENT.Purpose			= ""
ENT.Instructions	= ""

function ENT:SetupDataTables()

	self:NetworkVar( "String", 0, "Gun" )
	self:NetworkVar( "Bool", 0, "GiveOnTouch" )
	
end

function ENT:Initialize()
	
	--self:PhysicsInit(SOLID_VPHYSICS)
	if SERVER then
		if self:GetGiveOnTouch() then
			self:SetTrigger(true)
		end
		local wepmodel = ents.Create(self:GetGun())
		self:SetModel(wepmodel:GetWeaponWorldModel())
		self:SetUseType(SIMPLE_USE)
	else
		self.NextParticle = CurTime()
	end
	--self:PhysicsInitSphere(60, "default_silent")
	self:SetSolid(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	self:SetMoveType(MOVETYPE_NONE)
	--self:SetSolid(SOLID_NONE)
	self:UseTriggerBounds(true, 0)
	self:SetMaterial("models/nzpowerups/mtl_x2icon_gold")
	--self:SetColor( Color(255,200,0) )
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
end

if SERVER then
	
	function ENT:StartTouch(hitEnt)
		if (hitEnt:IsValid() and hitEnt:IsPlayer()) then
			self:GiveGun(hitEnt)
		end
	end
	
	function ENT:Use(activator)
		self:GiveGun(activator)
	end
	
	function ENT:GiveGun(ply)
		if !ply:HasWeapon(self:GetGun()) then
				local givengun = ply:Give(self:GetGun())
				ply:Give(self:GetGun())
				ply:GetWeapon( self:GetGun() ):GiveMaxAmmo()
			else
				ply:GetWeapon( self:GetGun() ):GiveMaxAmmo()
			end
		self:EmitSound("nz/powerups/power_up_grab.wav")
		self:Remove()
	end
	
	local nextblink = CurTime() + 32
	function ENT:Think()
		if self.RemoveTime and CurTime() > self.RemoveTime then
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
			util.Effect( "powerup_glow_private", effectdata )
			self.NextParticle = CurTime() + particledelay
		end
		self:DrawModel()
	end
	
	function ENT:Think()
		if !self:GetRenderAngles() then self:SetRenderAngles(self:GetAngles()) end
		self:SetRenderAngles(self:GetRenderAngles()+(Angle(0,50,0)*FrameTime()))
	end
	--[[
	function ENT:GetNZTargetText()
		if !self:GetGiveOnTouch() then
			return "Press "..string.upper(input.LookupBinding("+use")).." for "..language.GetPhrase(self:GetGun())
		end
	end
	]]
	hook.Add( "PreDrawHalos", "drop_powerups_halos_wep", function()
		halo.Add( ents.FindByClass( "drop_weapon" ), Color( 0, 100, 200 ), 8, 8, 9 )
	end )
end