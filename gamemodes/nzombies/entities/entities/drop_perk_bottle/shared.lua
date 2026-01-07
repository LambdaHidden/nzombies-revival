AddCSLuaFile()

ENT.Type = "anim"
 
ENT.PrintName		= "Perk Bottle"
ENT.Author			= "Alig96, Chtidino & Hidden"
ENT.Contact			= "Don't"
ENT.Purpose			= ""
ENT.Instructions	= ""

function ENT:SetupDataTables()
	self:NetworkVar( "Bool", 0, "Empty" )
	self:NetworkVar( "Bool", 1, "Shared" )
end

function ENT:Initialize()
	
	--self:PhysicsInit(SOLID_VPHYSICS)
	self:SetModel("models/nzpowerups/perk_bottle.mdl")
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
	
	if CLIENT then
		local tempPrivate = {}
		local tempShared = {}
		
		for k, v in ipairs(ents.FindByClass("drop_perk_bottle")) do
			if v:GetShared() then
				table.insert(tempShared, v)
			else
				table.insert(tempPrivate, v)
			end
		end
		privateBottles = tempPrivate
		sharedBottles = tempShared
	end
end

if SERVER then
	function ENT:StartTouch(hitEnt)
		if (hitEnt:IsValid() and hitEnt:IsPlayer()) then
		if self:GetEmpty() and hitEnt.SetPerkLimit then
			if self:GetShared() then
				for k, v in pairs(player.GetAllPlaying()) do
					v:SetPerkLimit(hitEnt:GetPerkLimit() + 1)
				end
			else
				hitEnt:SetPerkLimit(hitEnt:GetPerkLimit() + 1)
			end
		else
			local available = nzMapping.Settings.wunderfizzperks or nzPerks:GetList()
			local blockedperks = {
				["wunderfizz"] = true, -- lol, this would happen
				["pap"] = true
			}
			local tbl = {}
			for k,v in pairs(available) do
				if !p:HasPerk(k) and !blockedperks[k] then
					table.insert(tbl, k)
				end
			end
			
			if self:GetShared() then
				for _, p in pairs(player.GetAllPlaying()) do
					p:GivePerk(tbl[math.random(1, #tbl)])
				end
			else
				hitEnt:GivePerk(tbl[math.random(1, #tbl)])
			end
			
		end
			self:EmitSound("nz/powerups/power_up_grab.wav")
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
		if self:GetEmpty() then
			self:SetBodygroup(0, 1)
		else
			self:SetBodygroup(0, 0)
		end
		if CurTime() > self.NextParticle then
			local effectdata = EffectData()
			effectdata:SetOrigin( self:GetPos() )
			util.Effect( self:GetShared() and "powerup_glow" or "powerup_glow_private", effectdata ) --powerup_glow_global
			self.NextParticle = CurTime() + particledelay
		end
		self:DrawModel()
	end
	
	function ENT:Think()
		if !self:GetRenderAngles() then self:SetRenderAngles(self:GetAngles()) end
		self:SetRenderAngles(Angle(0,60,20)*math.sin((self.RemoveTime - CurTime())*0.6) + Angle(20,0,0)*math.sin((self.RemoveTime - CurTime())*0.4))
	end
	
	local privateBottles = {}
	local sharedBottles = {}
	local color_private = Color( 0, 100, 200 )
	local color_shared = Color( 50, 175, 50 )
	hook.Add( "PreDrawHalos", "drop_powerups_halos_bottle", function()
		halo.Add( privateBottles, color_private, 2, 2, 2 ) -- 8, 8, 9
		halo.Add( sharedBottles, color_shared, 2, 2, 2 )
	end )
	--[[
	hook.Add( "PreDrawHalos", "drop_powerups_halos_bottle", function()
		local full, empty = {}, {}
		
		for k, v in pairs( ents.FindByClass( "drop_powerup_private" )) do
			if v.GetEmpty and v:GetEmpty() then
				table.insert(empty, v)
			else
				table.insert(full, v)
			end
		end
		halo.Add( empty, Color( 0, 100, 200 ), 8, 8, 9 )
		halo.Add( full, Color( 50, 175, 50 ), 8, 8, 6 )
	end )]]
end
