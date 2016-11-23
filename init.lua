asteroids = {}
asteroids.DEFAULT_NODENAME = "asteroids:stone_replacement"
asteroids.MIN_HIGH = 2000
asteroids.gene_try = 0

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
	is_ground_content = false,
})


minetest.register_node( "asteroids:star_material1", {
	description = "Star Material",
	tiles = { "star_material1.png"},
	is_ground_content = true,
	groups = {cracky=3},
	light_source = LIGHT_MAX,
	sounds = default.node_sound_stone_defaults(),
	drop = "default:gold_ingot",
	is_ground_content = false,
}) 

minetest.register_node( "asteroids:star_material2", {
	description = "Star Material",
	tiles = { "star_material2.png"},
	is_ground_content = true,
	groups = {cracky=3},
	light_source = LIGHT_MAX,
	sounds = default.node_sound_stone_defaults(),
	drop = "default:gold_ingot",
	is_ground_content = false,
}) 

minetest.register_node("asteroids:air", {
	description = "Air",
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	drawtype = "glasslike",
	post_effect_color = {a = 20, r = 220, g = 200, b = 200},
	tiles = {"asteroid_air.png^[colorize:#D0D0F055"},
	alpha = 50,
	groups = {msa=1,not_in_creative_inventory=0},
	paramtype = "light",
	sunlight_propagates =true,
	is_ground_content = false,
})

minetest.register_node("asteroids:brown_gas", {
	description = "Air",
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	drawtype = "glasslike",
	post_effect_color = {a = 20, r = 220, g = 200, b = 200},
	tiles = {"asteroid_air.png^[colorize:#E0D00066"},
	alpha = 50,
	groups = {msa=1,not_in_creative_inventory=0},
	paramtype = "light",
	sunlight_propagates =true,
	is_ground_content = false,
})

minetest.register_node("asteroids:grass", {
	description = "Grass",
	tiles = {"asteroid_grass.png"},
	groups = {crumbly = 3, soil = 1},
	sounds = default.node_sound_dirt_defaults(),
	drop = "default:dirt",
	is_ground_content = false,
})

minetest.register_node("asteroids:dirt", {
	description = "Grass",
	tiles = {"default_dirt.png"},
	groups = {crumbly = 3, soil = 1},
	sounds = default.node_sound_dirt_defaults(),
	drop = "default:dirt",
	is_ground_content = false,
})

minetest.register_node("asteroids:water_source", {
	description = "Grass",
	tiles = {"default_dirt.png"},
	groups = {crumbly = 3, soil = 1},
	sounds = default.node_sound_dirt_defaults(),
	drop = "default:dirt",
	is_ground_content = false,
})


----------------------------------------------------------------------------------------------------------
--WATER
----------------------------------------------------------------------------------------------------------
minetest.register_node("asteroids:water_source", {
	description = "Air",
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	drawtype = "glasslike",
	post_effect_color = {a = 20, r = 220, g = 200, b = 200},
	tiles = {"asteroid_water.png"},
	alpha = 50,
	paramtype = "light",
	sunlight_propagates =true,
	is_ground_content = false,
	liquid_viscosity = 1,
	post_effect_color = {a = 103, r = 30, g = 60, b = 90},
	groups = {water = 3, liquid = 3, puts_out_fire = 1},
})

if bucket then 
	bucket.liquids["asteroids:water_source"] = {
		source = "asteroids:water_source",
		flowing = "air",
		itemname = "bucket:bucket_water",
	}
end
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
----------------------------------------------------------------------------------------------------------
-- PLANETREGISTRATION
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

print("ASTEROIDS PLANET REGISTRATION:")
function asteroids.register_planet(planet_name, chance, spheres, on_construct)
        local planet = {}
	planet.on_construct = on_construct
	planet.name = planet_name
	print("REGISTER PLANET:", planet.name)
	planet.chance = chance *20
	planet.spheres = {}
	for i=1,#spheres do
	        planet.spheres[i] = {}
		planet.spheres[i].radius = spheres[i][1]
		planet.spheres[i].ores = {}
		local sum_chances = 0
		for j=1,#spheres[i][2] do
		        local chance = spheres[i][2][j][2]
			local name = spheres[i][2][j][1]
			
		        local chance_start = sum_chances+1
		        sum_chances = sum_chances+chance
			local chance_end = sum_chances
			planet.spheres[i].ores[j] = {name=name,
			        c1 = chance_start,
				c2 = chance_end}
			if spheres[i][2][j][3] then
			       planet.spheres[i].construct = name
			end
		end
		planet.spheres[i].sum_chances = sum_chances
	end
	table.insert(asteroids.registered_planets, 1, planet)
	end
	
--[[nodename_change:
{here_can_be_key_for_name={oldname=newname, oldname2=newname2}, {oldname=newname2}}
it have to be like this: {{[0]="default:stone"}} that one planet is generated!
]]--
	
function asteroids.register_planet_group(planet_name, chance, spheres, on_construct, radius_offsets, nodename_changes)
        print(dump(radius_offsets))
	for _, radius_offset in pairs(radius_offsets) do
	        for key, nodename_change in pairs(nodename_changes) do
			local planet = {}
			planet.on_construct = on_construct
        	        planet.name = planet_name..";rad:"..radius_offset..";change:"..key
			print("REGISTER PLANET GROUP ELEMENT:", planet.name)
		        planet.chance = chance*20
		        planet.spheres = {}
		        for i=1,#spheres do
				if (radius_offset + spheres[i][1]) > 0 then
				        planet.spheres[i] = {}
			                planet.spheres[i].radius = spheres[i][1]+radius_offset
					planet.spheres[i].ores = {}
			        	local sum_chances = 0
			        	for j=1,#spheres[i][2] do
		        	 	        local chance = spheres[i][2][j][2]
				        	local name = spheres[i][2][j][1]
						for change_name, newname in pairs(nodename_change) do
						        if name == change_name then name = newname end
			                        end
		        	        	local chance_start = sum_chances+1
		        	        	sum_chances = sum_chances+chance
				        	local chance_end = sum_chances
				        	planet.spheres[i].ores[j] = {name=name,
				                	c1 = chance_start,
				        		c2 = chance_end}
						if spheres[i][2][j][3] then
						        planet.spheres[i].construct = name
						end
			        	end
			        	planet.spheres[i].sum_chances = sum_chances
				end
		        end
		        table.insert(asteroids.registered_planets, 1, planet)
	        end
	end
end
	
function random_ore(sphere)
        local rnd = math.random(1, sphere.sum_chances)
	for _, node in pairs(sphere.ores) do
	        if (node.c1 <= rnd) and (rnd <= node.c2) then
		        return minetest.get_content_id(node.name)
		end
	end
	return minetest.get_content_id(asteroids.DEFAULT_NODENAME)
end

--ASTEROIDS:

--[[
on_construct = function(pos) 
		local nodes = minetest.find_nodes_in_area(
		        {x=-2+pos.x, y=-2+pos.y, z=-2+pos.z}, 
			{x=2+pos.x, y=2+pos.y, z=2+pos.z}, 
			"asteroids:grass")
		local water = minetest.find_nodes_in_area(
		        {x=-2+pos.x, y=-2+pos.y, z=-2+pos.z}, 
			{x=2+pos.x, y=2+pos.y, z=2+pos.z}, 
			"asteroids:water_source")
		if not (#water <= 1) then return end
	        for _, foundpos in pairs(nodes) do
			if foundpos and minetest.get_node(foundpos).name == "asteroids:grass" then
			        print(pos.x, pos.y, pos.z)
			        minetest.after(10, minetest.set_node, foundpos, {name="asteroids:water_source"})
			end
		end
        end,
]]--
	
asteroids.register_planet("earth", 1, {
	{60, {
	        {"asteroids:air", 1}, 
		}
	},
	{59, {
	        {"air", 1}, 
		}
	},
	{40, {
	        {"asteroids:grass", 30}, 
		{"asteroids:water_source", 1, 1}, 
		{"default:sapling", 1},
		}
	},
	{39, {
	        {"asteroids:dirt", 1}, 
		}
	},
	},
	function(pos, planet) 
	        print("EARTH GENERATED", pos.x, pos.y, pos.z) 
		local nodes = minetest.find_nodes_in_area(
		        {x=-43+pos.x, y=-43+pos.y, z=-43+pos.z}, 
			{x=43+pos.x, y=43+pos.y, z=43+pos.z}, 
			"asteroids:water_source")
		for _, wpos in pairs(nodes) do
		        local grass = minetest.find_nodes_in_area(
		                {x=-2+wpos.x, y=-2+wpos.y, z=-2+wpos.z}, 
			        {x=2+wpos.x, y=2+wpos.y, z=2+wpos.z}, 
			        "asteroids:grass")
			for _, grass_pos in pairs(grass) do
			        minetest.set_node(grass_pos, {name="asteroids:water_source"})
			end
		end
		        
	end,
	--group
	{10, 20}, 
	{
	           {["default:dirt"]="default:dirt"}, 
	           {["default:dirt"]="default:stone"}
	}
)
	
print(dump(asteroids.registered_planets))
	
asteroids.register_planet_group("all ores", 100, {
        {60, {
	        {"m1", 30}, 
		{"m2", 10},
		}
	},
	{55, {
	        {"default:water_source", 9}, 
		{"default:gravel", 1}
		}
	},
	{50, {
	        {asteroids.DEFAULT_NODENAME, 100}, 
		{"default:stone_with_iron", 5}
		}
	},
	{45, {
	        {asteroids.DEFAULT_NODENAME, 100}, 
		{"default:stone_with_copper", 3}
		}
	},
	{40, {
	        {asteroids.DEFAULT_NODENAME, 100}, 
		{"default:stone_with_gold", 2}
		}
	},
	{36, {
		{"default:lava_source", 1}
		}
	},
	{35, {
	        {"default:lava_source", 100}, 
		{"default:stone_with_mese", 1}
		}
	},
	{30, {
	        {"default:lava_source", 100}, 
		{"default:stone_with_diamond", 1},
		{"default:stone_with_mese", 1}
		}
	},
	},
	nil,
	{-20, 0, 20},
	{
	        ["dirt"]    = {["m1"]="default:dirt", ["m2"]="default:sand"}, 
	        ["moon"]= {["m1"]="default:gravel", ["m2"]="default:stone"},
		["ice"]    = {["m1"]="default:ice", ["m2"]="default:snowblock"},
		["sand"] = {["m1"]="default:sandstone", ["m2"]="default:dirt"},
	}
	)


print("ASTEROIDS PLANET REGISTRATION [ ok ]")
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
	        asteroids.gene_try = asteroids.gene_try +1
		print(asteroids.gene_try)
		local rnd = math.random(1, planet.chance)
	        if rnd == 1 then
		        print(rnd, planet.chance)
		        table.insert(choosen_planets, 1, index)
			planet_nr = planet_nr + 1
		end
	end
	if planet_nr == 0 then return end
	
	local index = choosen_planets[math.random(1, planet_nr)]
        local planet = asteroids.registered_planets[index]
	minetest.chat_send_all(minetest.pos_to_string(pos)..planet.name)
	
        for i,sphere in pairs(planet.spheres) do
                asteroids.sphere(pos, sphere)
		minetest.chat_send_all(minetest.pos_to_string(pos)..planet.name.."sphere"..i)
	end
	if planet.on_construct then planet.on_construct(pos, planet) end
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
