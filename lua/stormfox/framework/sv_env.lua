--[[-------------------------------------------------------------------------
 	Handles mapentities and entity functions

 	Get entities
	 	StormFox.GetSkyPaint()	returns env_skypaint
	 	StormFox.GetSun()		returns env_sun

	Map Bloom
		StormFox.SetMapBloom(n)

	Shadow
		StormFox.SetShadowColor(col)
		StormFox.SetShadowAngle(ang,forceday)
		StormFox.SetShadowDistance(dis)
		StormFox.SetShadowDisable(bool)

	Sun
		StormFox.SetSunAngle(ang,setShadow,forceday)
		StormFox.SetSunSize(size [0-100])
		StormFox.SetSunOverlaySize(size [0-100])
		StormFox.SetSunColor(Color)
		StormFox.SetSunOverlayColor(Color)
		StormFox.DebugSun() -- Returns sun position

	Maplight
		StormFox.SetMapLight(0-100)

 ---------------------------------------------------------------------------]]
local round,clamp = math.Round,math.Clamp

StormFox.env_skypaint = StormFox.env_skypaint or nil
StormFox.env_fog_controller = StormFox.env_fog_controller or nil
StormFox.shadow_control = StormFox.shadow_control or nil
StormFox.light_environment = StormFox.light_environment or nil



-- Scan/create mapentities
local function GetOrCreate( eEntClass )
	local tEnts = ents.FindByClass( eEntClass )
	local mapSupportConvar = GetConVar( "sf_disable_mapsupport" )
	if #tEnts > 0 then return tEnts[1] end
	if mapSupportConvar:GetBool() then return end -- Disabled mapsupport

	local ent = ents.Create( eEntClass )
	ent:Spawn();
	ent:Activate();
	print("[StormFox] Creating " .. eEntClass)
	return ent
end

local function printEntFoundStatus( bFound, sEntClass )
	local sStatus = bFound and "OK" or "Not Found"
	local cStatusColor = bFound and Color( 0, 255, 0 ) or Color( 255, 0, 0 )
	MsgC( "	", Color(255,255,255), sEntClass, " ", cStatusColor, sStatus, Color( 255, 255, 255), "\n" )
	StormFox.SetData( "has_" .. sEntClass, bFound )
end

-- Finds the ents on the map that stormfox uses and creates some of them if not found
local function FindEntities()
	print( "[StormFox] Scanning mapentities ..." )

	local tSunlist = ents.FindByClass( "env_sun" )
	for i = 1, #tSunlist do -- Remove any env_suns there should be only one but who knows
		tSunlist[ i ]:Fire( "TurnOff" )
		SafeRemoveEntity( tSunlist[ i ] )
	end

	StormFox.light_environment = StormFox.light_environment or ents.FindByClass( "light_environment" )[ 1 ] or nil
	StormFox.env_fog_controller = StormFox.env_fog_controller or GetOrCreate( "env_fog_controller" ) or nil
	StormFox.shadow_control = StormFox.shadow_control or ents.FindByClass( "shadow_control" )[ 1 ] or nil

	printEntFoundStatus( StormFox.light_environment, "light_environment" )
	printEntFoundStatus( StormFox.env_fog_controller, "env_fog_controller" )
	printEntFoundStatus( StormFox.shadow_control, "shadow_control" )
	hook.Call( "StormFox - PostEntityScan" )
end
hook.Add( "StormFox - PostEntity", "StormFox - FindEntities", FindEntities )

if #player.GetAll() > 0 then FindEntities() end


-- Shadow controls
function StormFox.SetShadowColor( cColor )
	if not StormFox.shadow_control then return end
	StormFox.shadow_control:SetKeyValue( "color", cColor.r .. " " .. cColor.g .. " " .. cColor.b )
end

function StormFox.SetShadowAngle( nShadowPitch )
	if not StormFox.shadow_control then return end
	nShadowPitch = (nShadowPitch + 180) % 360
	-- min 190 max 350
	local sAngleString = ( nShadowPitch + 180 ) .. " " .. StormFox.SunMoonAngle .. " " .. 0 .. " "
	StormFox.shadow_control:Fire( "SetAngles" , sAngleString , 0 )
end

function StormFox.SetShadowDistance( dis )
	if not StormFox.shadow_control then return end
	StormFox.shadow_control:SetKeyValue( "SetDistance", dis )
end

function StormFox.SetShadowDisable( bool )
	if not StormFox.shadow_control then return end
	StormFox.shadow_control:SetKeyValue( "SetShadowsDisabled", bool and 1 or 0 )
end

-- Maplight
local oldls = "-"
function StormFox.SetMapLight(light) -- 0-100
	if not IsValid(StormFox.light_environment) then
		light = 15 + (light * 0.7)
		local s = string.char(97 + clamp(light / 4,0,25))
		if s == oldls then return end
		engine.LightStyle(0,s)
		oldls = s
		return
	end
	local s = string.char(97 + clamp(light / 4,0,25))
	if s == oldls then return end
	oldls = s
	StormFox.light_environment:Fire("FadeToPattern", s ,0)
end

-- Support for envcitys sky-entity
hook.Add("StormFox - PostEntity","StormFox - StopWhiteBoxes",function()
	local skyCam = ents.FindByClass("sky_camera")[1] or nil
	if not IsValid(skyCam) then return end
	local tr = util.QuickTrace(skyCam:GetPos(),Vector(0,0,-1000))
	if not tr.Entity then return end
	if tr.Entity:GetClass() == "func_brush" and not tr.Entity:IsWorld() then
		SafeRemoveEntity(tr.Entity) -- just to be safe
	end
end)
