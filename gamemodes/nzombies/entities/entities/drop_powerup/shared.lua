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

	self.PowerUpActive = false

	--self:SetPowerUp("dp")
	--self:SetModelScale(nzPowerUps:Get(self:GetPowerUp()).scale, 1)
	
	--self:PhysicsInit(SOLID_VPHYSICS)
	self:PhysicsInitSphere(60, "default_silent")
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_NONE)
	self:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
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
	
	local nearest = self:FindNearestPlayer(self:GetPos())
	
	if IsValid(nearest) then
		self:OOBTest(nearest)
	end
	
	timer.Simple(0, function()
		if IsValid(self) then
			self.PowerUpActive = true
			self:SetSolid(SOLID_OBB)
		end
	end)
end

if SERVER then
	function ENT:Use(ply)
		if not self.PowerUpActive then return end
	
		if ply:IsValid() then
			nzPowerUps:Activate(self:GetPowerUp(), ply, self)
			self:StopSound( "power_up_loop" )
			self:Remove()
		end
	end

	function ENT:StartTouch(hitEnt)
		if not self.PowerUpActive then return end
	
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

-- From nZR
function ENT:OOBTest(ply)
	if CLIENT then return end
	if not IsValid(ply) then return end

	local size = Vector(2, 2, 2)
	local entpos = ply:WorldSpaceCenter()
	local pos = self:WorldSpaceCenter()

	local tr = util.TraceLine({
		start = pos,
		endpos = entpos,
		filter = {self, ply},
		mask = MASK_SOLID_BRUSHONLY
	})

	-- Check 1, trace to player, if interrupted by world, teleport infront of a barricade closest to player
	if tr.HitWorld then
		local barricade = self:FindNearestBarricade(entpos)
		if barricade and IsValid(barricade) then
			--print('Powerup1, Trace to player blocked by world')
			local normal = (ply:GetPos() - barricade:GetPos()):GetNormalized()
			local fwd = barricade:GetForward()
			local dot = fwd:Dot(normal)

			if 0 < dot then
				self:SetPos(barricade:GetPos() + vector_up*5 + fwd*50)
			else
				self:SetPos(barricade:GetPos() + vector_up*5 + fwd*-50)
			end
			return
		end
	end

	-- Check 2, raycast to player, if interrupted by a barricade, teleport infront of that barricade
	for k, v in pairs(ents.FindAlongRay(pos, entpos, -size, size)) do
		if v:GetClass() == "breakable_entry" then
			--print('Powerup2, Barricade blocking raycast to player')
			local normal = (ply:GetPos() - v:GetPos()):GetNormalized()
			local fwd = v:GetForward()
			local dot = fwd:Dot(normal)

			if 0 < dot then
				self:SetPos(v:GetPos() + vector_up*5 + fwd*50)
			else
				self:SetPos(v:GetPos() + vector_up*5 + fwd*-50)
			end
			return
		end
	end

	-- Check 3, if theres a barricade next to us at all, place on side with player
	for k, v in pairs(ents.FindInSphere(pos, 60)) do
		if v:GetClass() == "breakable_entry" then
			--print('Powerup3, Barricade too close')
			local ply2 = self:FindNearestPlayer(v:GetPos())
			if ply2 and IsValid(ply2) then
				local normal = (self:GetPos() - v:GetPos()):GetNormalized()
				local normal2 = (ply2:GetPos() - v:GetPos()):GetNormalized()
				local fwd = v:GetForward()
				local dot = fwd:Dot(normal)
				local dot2 = fwd:Dot(normal2)

				if 0 < dot2 and dot > 0 then
					self:SetPos(v:GetPos() + vector_up*50 + fwd*50)
				elseif 0 > dot2 and dot < 0 then
					self:SetPos(v:GetPos() + vector_up*50 + fwd*-50)
				end
				return
			end
		end
	end
end

-- From nZR
function ENT:FindNearestPlayer(pos)
	if not pos then
		pos = self:GetPos()
	end

	local nearbyents = {}
	for k, v in player.Iterator() do
		if v:Alive() then
			table.insert(nearbyents, v)
		end
	end

	if table.IsEmpty(nearbyents) then return end
	if #nearbyents > 1 then
		table.sort(nearbyents, function(a, b) return tobool(a:GetPos():DistToSqr(pos) < b:GetPos():DistToSqr(pos)) end)
	end
	return nearbyents[1]
end

-- From nZR
function ENT:FindNearestBarricade(pos)
	if not pos then
		pos = self:GetPos()
	end

	local nearbyents = {}
	for k, v in pairs(ents.FindInSphere(pos, 2048)) do
		if v:GetClass() == "breakable_entry" then
			table.insert(nearbyents, v)
		end
	end

	if table.IsEmpty(nearbyents) then return end
	if #nearbyents > 1 then
		table.sort(nearbyents, function(a, b) return tobool(a:GetPos():DistToSqr(pos) < b:GetPos():DistToSqr(pos)) end)
	end
	return nearbyents[1]
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
