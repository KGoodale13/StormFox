
--[[
	util.Is3DSkybox()	 -- return [true/false]
	util.SkyboxPos()	 -- return vector
	util.SkyboxScale()	 -- return number
	util.WorldToSkybox(Vector) -- return vector
	util.SkyboxToWorld(Vector) -- return vector
	util.MapOBBMaxs() 	 -- return vector
	util.MapOBBMins()	 -- return vector
	util.IsTF2Map()		 -- return [true/false]

	navmesh.GetNavAreaBySize(xyminsize) -- returns all navmeshs equal to or bigger than the input
]]
local sky_cam = nil
local sky_scale = 0
StormFox_DATA = StormFox_DATA or {}

if SERVER then
	local function SkyTexture(str,vec)
		vec = vec or Vector(0,0,0)
		if str == "TOOLS/TOOLSNODRAW" and vec.z < 0 then return true end
		if str == "TOOLS/TOOLSINVISIBLE" and vec.z < 0 then return true end
		if str == "TOOLS/TOOLSSKYBOX" then return true end
		if str == "**empty**" then return true end
		return false
	end
	local function ET(pos,pos2,mask)
		local t = util.TraceLine( {
			start = pos,
			endpos = pos + pos2,
			mask = mask
		} )
		local l = 0
		local norm = Vector(pos2.x,pos2.y,pos2.z)
			norm:Normalize()
		--print("Scan:",norm)
		while t.Hit and not t.Hitsky and l < 10 and not SkyTexture(t.HitTexture,norm) do
			l = l + 1
			--print("	",l,t.HitTexture)
			local sp = t.HitPos + norm * 3
			t = nil
			t = util.TraceLine( {
				start = sp,
				endpos = sp + pos2,
				mask = mask
			} )
		end
		--print("Don",t.HitTexture,not t.HitSky,t.Hit,not SkyTexture(t.HitTexture,norm))

		t.HitPos = t.HitPos or (pos + pos2)
		return t
	end

	local function scan()
		local l = ents.FindByClass("sky_camera")
		if #l < 1 then print("[StormFox] Not a 3D skybox. Clouds disabled!") return end
		sky_cam = l[1]
		sky_scale = l[1]:GetSaveTable().scale
		StormFox_DATA["skybox_pos"] = sky_cam:GetSaveTable()["m_skyboxData.origin"] or sky_cam:GetPos()
		StormFox_DATA["skybox_scale"] = sky_scale

		StormFox_DATA["mapobbmaxs"] =  game.GetWorld():GetSaveTable().m_WorldMaxs or Vector(0, 0, 0)
		StormFox_DATA["mapobbmins"] =  game.GetWorld():GetSaveTable().m_WorldMins or Vector(0, 0, 0)
		StormFox_DATA["mapobbcenter"] = StormFox_DATA["mapobbmins"] + (StormFox_DATA["mapobbmaxs"] - StormFox_DATA["mapobbmins"]) / 2

		-- Scan the skybox for its size
		local c = StormFox_DATA["skybox_pos"]
		local topZ = ET(c,Vector(0,0,16384)).HitPos.z
		local lowZ = ET(c,Vector(0,0,-16384)).HitPos.z

		local measurepos = Vector(c.x,c.y,topZ - 10)
		local topX = ET(measurepos,Vector(16384,0,0)).HitPos.x
		local lowX = ET(measurepos,Vector(-16384,0,0)).HitPos.x

		local topY = ET(measurepos,Vector(0,16384,0)).HitPos.Y
		local lowY = ET(measurepos,Vector(0,-16384,0)).HitPos.Y

		StormFox_DATA["skybox_obbmaxs"] = Vector(topX,topY,topZ) - c
		StormFox_DATA["skybox_obbmins"] = Vector(lowX,lowY,lowZ) - c
	end
	hook.Add("StormFox - PostEntity","StormFox - FindSkyBox",scan)

	function StormFox.Is3DSkybox()
		return IsValid(sky_cam)
	end
else
	function StormFox.Is3DSkybox()
		return StormFox_DATA["skybox_pos"] ~= nil
	end
end

function StormFox.SkyboxPos()
	return StormFox_DATA["skybox_pos"]
end

function StormFox.SkyboxScale()
	return StormFox_DATA["skybox_scale"]
end

function StormFox.SkyboxOBBMaxs()
	return StormFox_DATA["skybox_obbmaxs"]
end

function StormFox.SkyboxOBBMins()
	return StormFox_DATA["skybox_obbmins"]
end

function StormFox.WorldToSkybox(pos)
	if not util.Is3DSkybox() then return end
	local offset = pos / util.SkyboxScale()
	return util.SkyboxPos() + offset
end

function StormFox.SkyboxToWorld(pos)
	if not util.Is3DSkybox() then return end
	local set = pos - util.SkyboxPos()
	return set * util.SkyboxScale()
end

-- Thise don't give the world size .. but brushsize. This means that the topspace of the map might or might not count.
function StormFox.MapOBBMaxs()
	return StormFox_DATA["mapobbmaxs"]
end

function StormFox.MapOBBMins()
	return StormFox_DATA["mapobbmins"]
end

function StormFox.MapOBBCenter()
	return StormFox_DATA["mapobbcenter"]
end

function StormFox.IsTF2Map()
	local str = game.GetMap()
	return string.match(str, "^[(arena_)(cp_)(koth_)(cft_)(pl_)(plr_)(tr_)(sd_)(mvm_)(rd_)(ctf_)(pass_)]")
end
