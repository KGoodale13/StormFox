
local BufferAngle = Angle(0,0,0)
local sky_center = Vector(0,0,0)

local CloudMaterials = {}
	CloudMaterials[1] = {(Material("stormfox/clouds/part1.png")),(Material("stormfox/clouds/part1_out.png"))}
-- Init clouds
local Clouds = {}
	for i = 1,10 do -- Create 'render-layers'
		Clouds[i] = {}
	end

-- Calculate math stuff
	local ran,clamp,abs,min,diff,max = math.random,math.Clamp,math.abs,math.min,math.AngleDifference,math.max
	local cloudPolys = {}
	local totalCloudPolys = 30
	local totalCloudPolysAng = 360 / totalCloudPolys
	for i = 1,totalCloudPolys  do
		local a = (360 / (totalCloudPolys - 1)) * (i - 1)
		local x,y = math.cos(math.rad(a)),math.sin(math.rad(a))
		local u,v = (x + 1) / 2,(y + 1) / 2
			u = -0.1 + u * 1.2
			v = -0.1 + v * 1.2

		cloudPolys[i] = {x = x,y = y,u = u,v = v}
	end
	local function CreateCloud(x,y,size,life,density)
		if not matid then matid = 1 end
		local t = {
				x = x,
				y = y,
				z = 0,
				size = size,
				life = life,
				density = density,
				mat = ran(1,#CloudMaterials),
				random = ran(360),
				d = 9000,
				dot = 0,
				ang_dir = 0,
				render_ang = Angle(0,0,0)
			}
		table.insert(Clouds[ran(#Clouds)], t)
	end

-- Render clouds
	-- Buffer the data
	local pPos = Vector(0,0,0)
	local function RenderCloud(CloudData)
		-- Render the base
		local mat = Matrix()
		mat:Rotate(CloudData.render_ang)
		mat:SetScale(Vector(1,1,1))
		local cPos = sky_center + Vector(CloudData.x,CloudData.y,-CloudData.z * StormFox.SkyboxScale() * 0.1)
		mat:SetTranslation(cPos)
		local s = CloudData.size / 2
		--render.DrawSphere(cPos,10 + math.cos(CurTime()) * 10,30,30,Color(0,255,0))
		local cloudColor = Color(83,85,123,255)
		cam.PushModelMatrix( mat )
			render.SetMaterial(CloudMaterials[CloudData.mat][1])
			mesh.Begin( MATERIAL_QUADS, 1 );
				mesh.Position(Vector(0,-s,s))
				mesh.Color(cloudColor.r,cloudColor.g,cloudColor.b,cloudColor.a)
				mesh.TexCoord(0,0,1)
				mesh.Normal(Vector(0,0,-1))
				mesh.AdvanceVertex()

				mesh.Position(Vector(0,-s,-s))
				mesh.Color(cloudColor.r,cloudColor.g,cloudColor.b,cloudColor.a)
				mesh.TexCoord(0,0,0)
				mesh.Normal(Vector(0,0,-1))
				mesh.AdvanceVertex()

				mesh.Position(Vector(0,s,-s))
				mesh.Color(cloudColor.r,cloudColor.g,cloudColor.b,cloudColor.a)
				mesh.TexCoord(0,1,0)
				mesh.Normal(Vector(0,0,-1))
				mesh.AdvanceVertex()

				mesh.Position(Vector(0,s,s))
				mesh.Color(cloudColor.r,cloudColor.g,cloudColor.b,cloudColor.a)
				mesh.TexCoord(0,1,1)
				mesh.Normal(Vector(0,0,-1))
				mesh.AdvanceVertex()
			mesh.End( );
			render.SetMaterial(CloudMaterials[CloudData.mat][2])

			mesh.Begin( MATERIAL_POLYGON, #cloudPolys +1 );
				mesh.Position(Vector(0,0,0))
				mesh.Color(255,255,255,0)
				mesh.TexCoord(0,0.5,0.5)
				mesh.Normal(Vector(0,0,1))
				mesh.AdvanceVertex()

				local mr = 0
				for i,d in ipairs(cloudPolys) do
					local a = -i * totalCloudPolysAng - CloudData.random

					local light_amount = max(CloudData.dot,0.1)
					local ang_away = diff(a,CloudData.ang_dir + 90) * 100
					mesh.Position(Vector(0,d.x * s * 1.2,d.y * s * 1.2))

					local alpha = clamp(ang_away * light_amount,clamp(255 * (CloudData.dot - 0.7) * 3,0,255),255)

					mesh.TexCoord(0,d.u,d.v)
					mesh.Normal(Vector(0,0,-1))
					mesh.Color(144,255,0,alpha)
					mesh.AdvanceVertex()

				end
				mesh.Position(Vector(0,0,0))
				mesh.Color(255,255,255,0)
				mesh.TexCoord(0,0.5,0.5)
				mesh.Normal(Vector(0,0,1))
				mesh.AdvanceVertex()
			mesh.End( );

		cam.PopModelMatrix()
		cam.Start3D2D(cPos,Angle(0,0,180),1)
			surface.SetFont("default")
			surface.SetTextColor(Color(255,255,255))
			surface.SetTextPos(0,0)
			surface.DrawText("DOT: " .. math.Round(CloudData.dot,2))
			surface.SetTextPos(0,20)
			surface.DrawText("ang: " .. math.Round(CloudData.ang_dir,2))
			surface.SetMaterial(Material("gui/arrow"))
			surface.SetDrawColor(Color(255,255,255))
			surface.DrawTexturedRectRotated(0,0,100,40,CloudData.ang_dir or 0)
		cam.End3D2D()
	end
	hook.Add("Think","StormFox - CloudUpdate",function()
		if true then return end
		local flTime = StormFox.GetTime()
		BufferAngle = StormFox.GetMoonAngle( flTime ) -- When we fix clouds we also need to update this because moon and sun angles were changed

		local scale = StormFox.SkyboxScale()
		sky_center = StormFox.SkyboxPos() + Vector(0,0,StormFox.SkyboxOBBMaxs().z - 300)
		for layer,l_clouds in ipairs(Clouds) do
			for i,CloudData in pairs(l_clouds) do
				local pos = sky_center + Vector(CloudData.x,CloudData.y,0)

				local offset = pPos - pos
				local angletowards = offset:Angle()

				local x = clamp(offset.x / scale * 1.5,-65,65)
				local y = clamp(offset.y / scale * 1.5,-65,65)

				local ra = (pos - pPos):Angle()

				Clouds[layer][i].render_ang = ra
				Clouds[layer][i].z = abs(x) + abs(y)


				local dot = angletowards:Forward():Dot(BufferAngle:Forward())

				Clouds[layer][i].ang_dir = -(pos - (pPos - BufferAngle:Forward() * pos.z * 0.5)):Angle().yaw + 90
				Clouds[layer][i].dot = dot

			end
		end
	end)


	hook.Add("PostDrawOpaqueRenderables","StormFox - CloudRender",function(b,skybox)
		if not LocalPlayer() then return end -- Check if player is valid
		if not StormFox or not StormFox.ClientSettings.clouds then return end
		if not StormFox.Is3DSkybox() then return end -- Check if its a valid 3D skybox
			pPos = StormFox.WorldToSkybox(LocalPlayer():GetPos() + Vector(0,0,30))
		if LocalPlayer():GetPos():WithinAABox(StormFox.SkyboxPos() + StormFox.SkyboxOBBMins() - Vector(0,0,10),StormFox.SkyboxPos() + StormFox.SkyboxOBBMaxs()) and skybox then return end


		for layer,l_clouds in ipairs(Clouds) do
			local sky_center = StormFox.SkyboxPos() + Vector(0,0,StormFox.SkyboxOBBMaxs().z - layer * 10)
			for _,CloudData in pairs(l_clouds) do
				RenderCloud(CloudData,sky_center)
			end
		end
	end)
