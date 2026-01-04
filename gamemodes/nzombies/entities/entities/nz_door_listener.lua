
--AddCSLuaFile()
--DEFINE_BASECLASS( "base_anim" )
ENT.Type = "point"
ENT.Base = "base_point"

ENT.PrintName		= ""
ENT.Author			= "Hidden"
ENT.Contact			= "steamcommunity.com/id/LambdaHidden (tell me you came because of this ENT in the comments)"
ENT.Purpose			= "Listens for a specific Door Link and outputs when this link is opened/closed. Links are set in Creative Mode in-game. Can also open/close door links. Will be removed if Map Extensions is not ticked in the loaded config."
ENT.Instructions	= ""

ENT.Spawnable			= false
ENT.AdminOnly			= false

AccessorFunc( ENT, "link", "Link", FORCE_STRING )

function ENT:Kill()
	SafeRemoveEntity(self)
end
function ENT:OpenLinkedDoors()
	nzDoors:OpenLinkedDoors(self:GetLink())
end
function ENT:CloseLinkedDoors()
	nzDoors:CloseLinkedDoors(self:GetLink())
end

function ENT:AcceptInput( inputName, activator, called, data )
	if self[inputName] then
		self[inputName](self)
	elseif ( string.Left( inputName, 8 ) == "FireUser" ) then
		self:TriggerOutput("OnUser"..string.Right(inputName, 1))
	end
end

function ENT:KeyValue( key, value )
	-- Outputs
	if ( string.Left( key, 2 ) == "On" ) then
		self:StoreOutput( key, value )
	elseif key == "link" then
		self:SetLink(value)
	end
end

function ENT:Initialize()
	
end

hook.Add( "OnDoorUnlocked", "nZListen_OnDoorUnlocked", function(door, link, rebuyable, ply)
	for k, v in ipairs(ents.FindByClass("nz_door_listener")) do
		if link == v:GetLink() then
			v:TriggerOutput("OnDoorOpened") 
		end
	end
end)
hook.Add( "OnDoorLocked", "nZListen_OnDoorLocked", function(door, link, rebuyable, ply)
	for k, v in ipairs(ents.FindByClass("nz_door_listener")) do
		if link == v:GetLink() then
			v:TriggerOutput("OnDoorClosed") 
		end
	end
end)