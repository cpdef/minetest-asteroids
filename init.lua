asteroids = {}
asteroids.DEFAULT_NODENAME = "asteroids:stone_replacement"
asteroids.MIN_HIGH = 2000

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

----------------------------------------------------------------------------------------------------------
--NODES
----------------------------------------------------------------------------------------------------------

minetest.register_node( "asteroids:stone_replacement", {
	description = "Stone",
	tiles = {"default_stone.png"},
	groups = {cracky = 3, stone = 1},
	drop = 'default:cobble',
	legacy_mineral = true,
	sounds = default.node_sound_stone_defaults(),
})


minetest.register_node( "asteroids:star_material1", {
	description = "Star Material",
	tiles = { "star_material1.png"},
	is_ground_content = true,
	groups = {cracky=3},
	light_source = LIGHT_MAX,
	sounds = default.node_sound_stone_defaults(),
	drop = "default:gold_ingot",
}) 

minetest.register_node( "asteroids:star_material2", {
	description = "Star Material",
	tiles = { "star_material2.png"},
	is_ground_content = true,
	groups = {cracky=3},
	light_source = LIGHT_MAX,
	sounds = default.node_sound_stone_defaults(),
	drop = "default:gold_ingot",
}) 

----------------------------------------------------------------------------------------------------------
--STAR NODES DAMAGE
----------------------------------------------------------------------------------------------------------
minetest.register_abm({
	nodenames = {"asteroids:star_material1", "asteroids:star_material2"},
	interval = 3,
	chance = 1,
	action = function(pos, node)
	        for radius=1, 40, 10 do
		        for _, obj in pairs(minetest.get_objects_inside_radius(pos, radius)) do
			        if obj:is_player() then
				        obj:set_hp(obj:get_hp() - ((40-radius) / 10))
			        end
		        end
		end
	end,
})
--[[ DEPCREATED
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
--STAR!
asteroids.register_planettype("asteroids:star_material1", "asteroids:star_material2")


print("ASTEROIDS PLANETTYPE_REGISTRATION [ ok ]")
]]--
----------------------------------------------------------------------------------------------------------
-- NEWPLANETTYPES
----------------------------------------------------------------------------------------------------------
asteroids.registered_planets = {}


--[[
planet
    -chance
    -name
    -n*sphere
           -n*ore
	         -chance
		 -node_id
	   -chance_sum
           -radius

spheres: {{radius, {{node, chance}, ...}}, ...}
]]--


function asteroids.register_planet(planet_name, chance, spheres)
        local planet = {}
	planet.name = planet_name
	planet.chance = chance
	planet.spheres = {}
	for i=1,#spheres do
	        planet.spheres[i] = {}
		planet.spheres[i].radius = spheres[i][1]
		planet.spheres[i].ores = {}
		local sum_chances = 0
		for j=1,#spheres[i][2] do
		        local chance = spheres[i][2][j][2]
			local name = spheres[i][2][j][1]
			
		        chance_start = sum_chances+1
		        sum_chances = sum_chances+chance
			chance_end = sum_chances
			planet.spheres[i].ores[j] = {name=name,
			        c1 = chance_start,
				c2 = chance_end}
		end
		planet.spheres[i].sum_chances = sum_chances
	end
	table.insert(asteroids.registered_planets, 1, planet)
	end
	
function random_ore(sphere)
        rnd = math.random(1, sphere.sum_chances)
	for _, node in pairs(sphere.ores) do
	        if (node.c1 <= rnd) and (rnd <= node.c2) then
		        return minetest.get_content_id(node.name)
		end
	end
	return minetest.get_content_id(asteroids.DEFAULT_NODENAME)
end


--for now only one planet registered (for test)
asteroids.register_planet("one", 10, {
        {10, {
	        {"default:dirt", 1}, 
		{"default:stone", 2}
		}
	},
	{11, {
	        {"default:dirt", 1}, 
		{"default:sand", 2}
		}
	}
	})





----------------------------------------------------------------------------------------------------------
--MAPGENERATION
----------------------------------------------------------------------------------------------------------



--SPHERE
--from worldedit
function asteroids.sphere(pos, sphere)
        local radius = sphere.radius
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
					local i = new_y + (x + offset_x)
					data[i] = random_ore(sphere)
				end
			end
		end
	end

	manip:set_data(data)
	manip:write_to_map()
	manip:update_map()
end

--PLACE PLANET TO POS
asteroids.generate_asteroid = function(pos)
        if asteroids.registered_planettypes == {} then return end
	
	local choosen_planets = {}
	local planet_nr = 0
	for index, planet in pairs(asteroids.registered_planets) do
	        if math.random(1, planet.chance) == 1 then
		        table.insert(choosen_planets, 1, index)
			planet_nr = planet_nr + 1
		end
	end
	if planet_nr == 0 then return end
	
	local index = choosen_planets[math.random(1, planet_nr)]
        local planet = asteroids.registered_planets[index]
	minetest.chat_send_all(minetest.pos_to_string(pos)..planet.name)
	
        for _,sphere in pairs(planet.spheres) do
                asteroids.sphere(pos, sphere)
	end
	minetest.chat_send_all(minetest.pos_to_string(pos)..planet.name.." generated")
end	

--GETS PLANET POS
minetest.register_on_generated(function(minp, maxp, seed)
	local x = math.random(minp.x, maxp.x)
	local y = math.random(minp.y, maxp.y)
	local z = math.random(minp.z, maxp.z)
	local pos = {x=x,y=y,z=z}
	if y > asteroids.MIN_HIGH then
	        asteroids.generate_asteroid(pos)
	end
end)
print("ASTEROIDS LOADED")
