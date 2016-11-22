asteroids = {}
asteroids.MAXRADIUS = 100	
asteroids.MINRADIUS = 10
asteroids.CREATE_CHANCE = 20  --chance = 1/value
asteroids.DEFAULT_NODENAME = "default:stone"
asteroids.MAX_LAYERS = 20
asteroids.MIN_HIGH = 2000



----------------------------------------------------------------------------------------------------------
--ORES
----------------------------------------------------------------------------------------------------------
asteroids.registered_ores = {}
for i = 1, asteroids.MAX_LAYERS do
        asteroids.registered_ores[i] = {used=0, ores={}}
end

function asteroids.register_ore(
                node_name,  --name of the node for the ore
		chance, --chance for generation of the ore (real chance = chance/1000
		max_high, --max and min are between 1 and asteroids.MAX_LAYERS (normaly 20) one layer are 5 nodes
		min_high) -- 20 is most down 1 is on surface
		print("ASTERORE:", node_name, chance, max_high, min_high)
		for i=max_high, min_high do
		        local used = asteroids.registered_ores[i].used
			local ores = asteroids.registered_ores[i].ores
			local node_id = minetest.get_content_id(node_name)
			if (node_name == "PLANETMATERIAL1" or node_name == "PLANETMATERIAL2") then
			        node_id = node_name
			end
                        ores[node_id]={c1=used, c2=used+chance}
			asteroids.registered_ores[i] = {used = used+chance, ores=ores}
		end
end


--ores:
print("ASTEROIDS REGISTER ORES")
asteroids.register_ore("PLANETMATERIAL1", 950, 1, 1)
asteroids.register_ore("PLANETMATERIAL2", 50, 1, 3)
asteroids.register_ore("PLANETMATERIAL1", 700, 2, 2)
asteroids.register_ore("default:gravel", 200, 2, 3)
asteroids.register_ore("default:water_source",        700, 3, 3)
asteroids.register_ore("default:lava_source",  900, 7, asteroids.MAX_LAYERS)

asteroids.register_ore("default:stone_with_iron",         50, 3, 5)
asteroids.register_ore("default:stone_with_copper",    40, 5, 7)
asteroids.register_ore("default:stone_with_gold",        30, 7, 9)
asteroids.register_ore("default:stone_with_mese",      20, 8, 10)
asteroids.register_ore("default:stone_with_diamond", 20, 9, 11)


print("MOREORES?: ", minetest.get_modpath("moreores"))
if not (minetest.get_modpath("moreores") == nil) then
        print("ASTEROID ADD MOREORES")
        asteroids.register_ore("moreores:mineral_tin",        60, 2, 5)
        asteroids.register_ore("moreores:mineral_silver",    30, 5, 7)
	asteroids.register_ore("moreores:mineral_mithril",   10, 7, 9)
end


print("ASTEROIDS ORE_REGISTRATION [ ok ]")
----------------------------------------------------------------------------------------------------------
--PLANETTYPES
----------------------------------------------------------------------------------------------------------
print("ASTEROIDS REGISTER PLANETTYPES")
asteroids.registered_planettypes = {}
function asteroids.register_planettype(material1, material2)
        print(material1, material2)
        function table.shallow_deep_copy(t)
                local t2 = {}
                for k,v in pairs(t) do
		        if type(v) == "table" then
		                t2[k] = table.shallow_deep_copy(v)
			else
			        t2[k] = v
			end
                end
                return t2
        end
        local ores = asteroids.registered_ores
	
        local planettype = table.shallow_deep_copy(ores) --clone of org ores
	for i=1, asteroids.MAX_LAYERS do
		for node_id, chance in pairs(ores[i].ores) do
		        --Reset PLANETMATERIAL
		        if node_id == "PLANETMATERIAL1" then
				planettype[i].ores[minetest.get_content_id(material1)] = chance
				planettype[i].ores[node_id] = nil
			elseif node_id == "PLANETMATERIAL2" then
				planettype[i].ores[minetest.get_content_id(material2)] = chance
				planettype[i].ores[node_id] = nil
			end
		end
	end
	--print(dump(planettype))
        table.insert(asteroids.registered_planettypes, 1, planettype)
end

asteroids.register_planettype("default:dirt", "default:sand")
asteroids.register_planettype("default:ice", "default:snowblock")
asteroids.register_planettype("default:stone", "default:gravel")
asteroids.register_planettype("default:sandstone", "default:desert_sand")


print("ASTEROIDS PLANETTYPE_REGISTRATION [ ok ]")








----------------------------------------------------------------------------------------------------------
--MAPGENERATION
----------------------------------------------------------------------------------------------------------



--SPHERE
--from worldedit
function asteroids.sphere(pos, radius, ores)


        local volume = function(pos1, pos2)
	        pos1 = {x=pos1.x, y=pos1.y, z=pos1.z}
	        pos2 = {x=pos2.x, y=pos2.y, z=pos2.z}
	        if pos1.x > pos2.x then
		        pos2.x, pos1.x = pos1.x, pos2.x
	        end
	        if pos1.y > pos2.y then
		        pos2.y, pos1.y = pos1.y, pos2.y
	        end
	        if pos1.z > pos2.z then
		        pos2.z, pos1.z = pos1.z, pos2.z
	        end
	        return (pos2.x - pos1.x + 1) *
		        (pos2.y - pos1.y + 1) *
		        (pos2.z - pos1.z + 1)
        end

        local pos1 = vector.subtract(pos, radius)
	local pos2 = vector.add(pos, radius)
	
	local manip = minetest.get_voxel_manip()
	local emerged_pos1, emerged_pos2 = manip:read_from_map(pos1, pos2)
	local area = VoxelArea:new({MinEdge=emerged_pos1, MaxEdge=emerged_pos2})
	
	local data = {}
	local c_ignore = minetest.get_content_id("ignore")
	for i = 1, volume(area.MinEdge, area.MaxEdge) do
		data[i] = c_ignore
	end

	-- Fill selected area with node
	local node_id = minetest.get_content_id(asteroids.DEFAULT_NODENAME)
	local min_radius, max_radius = radius * (radius - 1), radius * (radius + 1)
	local offset_x, offset_y, offset_z = pos.x - area.MinEdge.x, pos.y - area.MinEdge.y, pos.z - area.MinEdge.z
	local stride_z, stride_y = area.zstride, area.ystride
	for z = -radius, radius do
		-- Offset contributed by z plus 1 to make it 1-indexed
		local new_z = (z + offset_z) * stride_z + 1
		for y = -radius, radius do
			local new_y = new_z + (y + offset_y) * stride_y
			for x = -radius, radius do
				local squared = x * x + y * y + z * z
				if squared <= max_radius then
					-- Position is on surface of sphere
					local i = new_y + (x + offset_x)
					local rnd = math.random(1,1000)
					local curr_node_id = node_id
					for node, chance in pairs(ores) do
					        --print(node, dump(chance), rnd)
					        if chance.c1 < rnd and rnd < chance.c2 then
						        curr_node_id = node
							break
						end
					end
					data[i] = curr_node_id
				end
			end
		end
	end

	manip:set_data(data)
	manip:write_to_map()
	manip:update_map()
end

--PLACE PLANET TO POS
asteroids.generate_asteroid = function(pos, radius)
        if asteroids.registered_planettypes == {} then return end
	
        minetest.chat_send_all(minetest.pos_to_string(pos)..radius)
	
	--Set Planettype:
        local planettype = math.random(1, table.getn(asteroids.registered_planettypes))
       planettype = asteroids.registered_planettypes[planettype]
       --Create Layers:
        for i=1, asteroids.MAX_LAYERS do
		local currend_rad = radius-i*5
		if currend_rad > 5 then
		        local ores = planettype[i].ores
			--print(dump(nodes))
			asteroids.sphere(pos, currend_rad, ores)
	        end
	end
	minetest.chat_send_all(minetest.pos_to_string(pos)..radius.." generated")
end	

--GETS PLANET POS
minetest.register_on_generated(function(minp, maxp, seed)
	local chance = math.random(1, asteroids.CREATE_CHANCE)
	if not (chance == 5) then return end
	
	local x = math.random(minp.x, maxp.x)
	local y = math.random(minp.y, maxp.y)
	local z = math.random(minp.z, maxp.z)
	local pos = {x=x,y=y,z=z}
	local radius = math.random(asteroids.MINRADIUS, asteroids.MAXRADIUS)
	if y > asteroids.MIN_HIGH then
	        asteroids.generate_asteroid(pos, radius)
	end
end)
print("ASTEROIDS LOADED")
