-- IndustrialTest
-- Copyright (C) 2023 mrkubax10

-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.

-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.

-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.

local S=minetest.get_translator("industrialtest")

local definition={
	description=S("Machine Block"),
	tiles={"industrialtest_machine_block.png"},
}
if industrialtest.mtgAvailable then
	definition.sounds=default.node_sound_metal_defaults()
	definition.groups={cracky=1,level=2}
elseif industrialtest.mclAvailable then
	definition.sounds=mcl_sounds.node_sound_metal_defaults()
	definition._mcl_blast_resistance=6
	definition._mcl_hardness=5
end
minetest.register_node("industrialtest:machine_block",definition)
minetest.register_craft({
	type="shaped",
	output="industrialtest:machine_block",
	recipe={
		{"industrialtest:refined_iron_ingot","industrialtest:refined_iron_ingot","industrialtest:refined_iron_ingot"},
		{"industrialtest:refined_iron_ingot","","industrialtest:refined_iron_ingot"},
		{"industrialtest:refined_iron_ingot","industrialtest:refined_iron_ingot","industrialtest:refined_iron_ingot"}
	}
})

definition={
	description=S("Advanced Machine Block"),
	tiles={"industrialtest_advanced_machine_block.png"},
	groups={
		_industrialtest_wrenchUnmountable=1
	}
}
if industrialtest.mtgAvailable then
	definition.sounds=default.node_sound_metal_defaults()
	definition.groups.cracky=2
	definition.groups.level=2
elseif industrialtest.mclAvailable then
	definition.sounds=mcl_sounds.node_sound_metal_defaults()
	definition._mcl_blast_resistance=7
	definition._mcl_hardness=5
end
minetest.register_node("industrialtest:advanced_machine_block",definition)
minetest.register_craft({
	type="shaped",
	output="industrialtest:advanced_machine_block",
	recipe={
		{"","industrialtest:advanced_alloy",""},
		{"industrialtest:carbon_plate","industrialtest:machine_block","industrialtest:carbon_plate"},
		{"","industrialtest:advanced_alloy",""}
	}
})

if not industrialtest.mods.mclRubber then
	definition={
		description=S("Rubber Wood"),
		tiles={
			"industrialtest_rubber_wood_top.png",
			"industrialtest_rubber_wood_top.png",
			"industrialtest_rubber_wood_side.png"
		},
		paramtype2="4dir"
	}
	if industrialtest.mtgAvailable then
		definition.sounds=default.node_sound_wood_defaults()
		definition.groups={
			tree=1,
			choppy=2,
			oddly_breakable_by_hand=1,
			flammable=2
		}
	elseif industrialtest.mclAvailable then
		definition.sounds=mcl_sounds.node_sound_wood_defaults()
		definition.groups={
			handy=1,
			axey=1,
			tree=1,
			flammable=2,
			building_block=1,
			material_wood=1,
			fire_encouragement=5,
			fire_flammability=5
		}
		definition.after_destruct=mcl_core.update_leaves
		definition._mcl_blast_resistance=1.8
		definition._mcl_hardness=1.8
	end
	definition.groups._industrialtest_rubberWood=1
	minetest.register_node("industrialtest:rubber_wood",definition)
	definition=table.copy(definition)
	definition.description=nil
	definition.tiles={
		"industrialtest_rubber_wood_top.png",
		"industrialtest_rubber_wood_top.png",
		"industrialtest_rubber_wood_side.png",
		"industrialtest_rubber_wood_side.png",
		"industrialtest_rubber_wood_side_with_rubber.png",
		"industrialtest_rubber_wood_side.png"
	}
	definition.drop="industrialtest:rubber_wood"
	if industrialtest.mclAvailable then
		definition.groups.not_in_creative_inventory=1
		definition._doc_items_create_entry=false
	end
	minetest.register_node("industrialtest:rubber_wood_with_rubber",definition)
	minetest.register_abm({
			label="Rubber forming",
			nodenames={"industrialtest:rubber_wood"},
			interval=120,
			chance=2,
			action=function(pos)
				local neighbourPositions={
					vector.offset(pos,-1,0,0),
					vector.offset(pos,1,0,0),
					vector.offset(pos,0,-1,0),
					vector.offset(pos,0,1,0),
					vector.offset(pos,0,0,-1),
					vector.offset(pos,0,0,1)
				}
				for _,value in ipairs(neighbourPositions) do
					if minetest.get_node(value).name=="industrialtest:rubber_wood_with_rubber" then
						return
					end
				end
				minetest.set_node(pos,{
					name="industrialtest:rubber_wood_with_rubber",
					param2=industrialtest.random:next(0,3)
				})
			end
	})
	minetest.register_craft({
		type="shapeless",
		output=industrialtest.elementKeys.junglePlanks.." 3",
		recipe={"group:_industrialtest_rubberWood"}
	})
	definition={
		description=S("Rubber Leaves"),
		drawtype="allfaces_optional",
		tiles={"industrialtest_rubber_leaves.png"},
		special_tiles={"industrialtest_rubber_leaves_simple.png"},
		paramtype="light",
		sunlight_propagates=true,
		waving=1
	}
	if industrialtest.mtgAvailable then
		definition.sounds=default.node_sound_leaves_defaults()
		definition.groups={
			snappy=3,
			leafdecay=3,
			flammable=2,
			leaves=1
		}
		definition.drop={
			max_items=1,
			items={
				{
					items={"industrialtest:rubber_sapling"},
					rarity=20
				},
				{items={"industrialtest:rubber_leaves"}}
			}
		}
		definition.after_place_node=default.after_place_leaves
	elseif industrialtest.mclAvailable then
		local saplingChances={20,16,12,10}
		local stickChances={50,45,30,35,10}
		-- Taken and adapted from https://git.minetest.land/MineClone2/MineClone2/src/branch/master/mods/ITEMS/mcl_core/nodes_trees.lua#L157
		local function getDrops(fortuneLevel)
			local drop = {
				max_items=1,
				items = {
					{
						items = {"industrialtest:rubber_sapling"},
						rarity = saplingChances[fortuneLevel+1] or saplingChances[fortuneLevel]
					},
					{
						items = {"mcl_core:stick 1"},
						rarity = stickChances[fortuneLevel+1]
					},
					{
						items = {"mcl_core:stick 2"},
						rarity = stickChances[fortuneLevel+1]
					},
				}
			}
			return drop
		end
		definition.sounds=mcl_sounds.node_sound_leaves_defaults()
		definition.groups={
			handy=1,
			hoey=1,
			shearsy=1,
			swordy=1,
			dig_by_piston=1,
			flammable=2,
			fire_encouragement=30,
			fire_flammability=60,
			leaves=1,
			deco_block=1,
			compostability=30
		}
		definition.drop=getDrops(0)
		definition.after_place_node=mcl_core.make_player_leaves
		definition._mcl_shears_drop=true
		definition._mcl_blast_resistance=0.2
		definition._mcl_hardness=0.2
		definition._mcl_silk_touch_drop=true
		definition._mcl_fortune_drop={getDrops(1),getDrops(2),getDrops(3),getDrops(4)}
	end
	minetest.register_node("industrialtest:rubber_leaves",definition)
	if industrialtest.mtgAvailable then
		default.register_leafdecay({
			trunks={"industrialtest:rubber_wood"},
			leaves={"industrialtest:rubber_leaves"},
			radius=2
		})
	end
	if industrialtest.mclAvailable then
		definition=table.copy(definition)
		definition._doc_items_create_entry=false
		definition.groups.not_in_creative_inventory=1
		definition.groups.orphan_leaves=1
		definition._mcl_shears_drop={"industrialtest:rubber_leaves"}
		definition._mcl_silk_touch_drop={"industrialtest:rubber_leaves"}
		minetest.register_node("industrialtest:rubber_leaves_orphan",definition)
	end
	industrialtest.internal.makeRubberTree=function(pos)
		-- FIXME: Replace this with placing schematic
		-- Taken and adapted from https://github.com/minetest/minetest_game/blob/master/mods/default/trees.lua#L182
		local height=industrialtest.random:next(4,5)
		local tree=minetest.get_content_id("industrialtest:rubber_wood")
		local treeWithRubber=minetest.get_content_id("industrialtest:rubber_wood_with_rubber")
		local leaves=minetest.get_content_id("industrialtest:rubber_leaves")
		local air=minetest.get_content_id("air")
		local ignore=minetest.get_content_id("ignore")

		local manip=minetest.get_voxel_manip()
		local minp,maxp=manip:read_from_map(vector.new(pos.x-2,pos.y,pos.z),vector.new(pos.x+2,pos.y+height+1,pos.z+2))
		local area=VoxelArea:new({
			MinEdge=minp,
			MaxEdge=maxp
		})
		local data=manip:get_data()

		-- Trunk
		data[area:index(pos.x,pos.y,pos.z)]=tree
		for y=pos.y+1,pos.y+height-1 do
			local index=area:index(pos.x,y,pos.z)
			local id=data[index]
			if id==air or id==ignore or id==leaves then
				data[index]=(industrialtest.random:next(0,5)==1 and treeWithRubber or tree)
			end
		end
		-- Force leaves near the trunk
		for dz=-1,1 do
			for dy=-2,1 do
				local index=area:index(pos.x-1,pos.y+height+dy,pos.z+dz)
				for dx=-1,1 do
					if data[index]==air or data[index]==ignore then
						data[index]=leaves
					end
					index=index+1
				end
			end
		end
		-- Randomly add leaves in 2x2x2 clusters.
		for i=1,8 do
			local x=pos.x+industrialtest.random:next(-2,1)
			local y=pos.y+height+industrialtest.random:next(-2,0)
			local z=pos.z+industrialtest.random:next(-2,1)
			for dx=0,1 do
				for dy=0,1 do
					for dz=0,1 do
						local index=area:index(x+dx,y+dy,z+dz)
						if data[index]==air or data[index]==ignore then
							data[index]=leaves
						end
					end
				end
			end
		end

		manip:set_data(data)
		manip:write_to_map()
		manip:update_map()
	end
	definition={
		description=S("Rubber Sapling"),
		inventory_image="industrialtest_rubber_sapling.png",
		wield_image="industrialtest_rubber_sapling.png",
		drawtype="plantlike",
		tiles={"industrialtest_rubber_sapling.png"},
		paramtype="light",
		sunlight_propagates=true,
		walkable=false,
		waving=1
	}
	if industrialtest.mtgAvailable then
		definition.sounds=default.node_sound_leaves_defaults()
		definition.groups={
			snappy=2,
			flammable=2
		}
		definition.on_construct=function(pos)
			minetest.get_node_timer(pos):start(industrialtest.random:next(300,1500))
		end
		definition.on_timer=function(pos)
			if not default.can_grow(pos) then
				minetest.get_node_timer(pos):start(300)
				return false
			end

			industrialtest.internal.makeRubberTree(pos)

			return false
		end
	elseif industrialtest.mclAvailable then
		definition.sounds=mcl_sounds.node_sound_leaves_defaults()
		definition.groups={
			plant=1,
			non_mycelium_plant=1,
			deco_block=1,
			dig_by_water=1,
			dig_by_piston=1,
			destroy_by_lava_flow=1,
			compostability=40
		}
		definition.on_construct=function(pos)
			local meta=minetest.get_meta(pos)
			meta:set_int("stage",0)
		end
		definition.on_place=mcl_util.generate_on_place_plant_function(function(pos,node)
			local nodeBelow = minetest.get_node_or_nil(vector.new(pos.x,pos.y-1,pos.z))
			if not nodeBelow then
				return false
			end
			local name = nodeBelow.name
			return minetest.get_item_group(name,"grass_block")==1 or
					name=="mcl_core:podzol" or name=="mcl_core:podzol_snow" or
					name=="mcl_core:dirt" or name=="mcl_core:mycelium" or name=="mcl_core:coarse_dirt"
		end)
		minetest.register_abm({
			label="Rubber sapling growing",
			nodenames={"industrialtest:rubber_sapling"},
			interval=120,
			chance=1,
			catch_up=false,
			action=function(pos)
				local under=minetest.get_node_or_nil(vector.offset(pos,0,-1,0))
				if not under or minetest.get_item_group(under.name,"soil")==0 then
					return
				end
				local lightLevel=minetest.get_node_light(pos)
				if not lightLevel or lightLevel<13 then
					return
				end
				local meta=minetest.get_meta(pos)
				local stage=meta:get_int("stage") or 0
				stage=stage+1
				if stage>=3 then
					industrialtest.internal.makeRubberTree(pos)
				else
					meta:set_int("stage",stage)
				end
			end
		})
		mcl_dye.register_on_bone_meal_apply(function(pointed)
			local node=minetest.get_node(pointed.under)
			if node.name~="industrialtest:rubber_sapling" then
				return
			end
			if industrialtest.random:next(1,100)>45 then
				return
			end
			local meta=minetest.get_meta(pointed.under)
			local stage=meta:get_int("stage") or 0
			stage=stage+1
			if stage>=3 then
					industrialtest.internal.makeRubberTree(pointed.under)
			else
				meta:set_int("stage",stage)
			end
		end)
	end
	definition.groups.attached_node=1
	definition.groups.dig_immediate=3
	definition.groups.sapling=1
	minetest.register_node("industrialtest:rubber_sapling",definition)
	if industrialtest.mtgAvailable then
		minetest.register_lbm({
			name="industrialtest:rubber_sapling_lbm",
			nodenames={"industrialtest:rubber_sapling"},
			action=function(pos)
				minetest.get_node_timer(pos):start(industrialtest.random:next(300,1500))
			end
		})
	end
end

definition={
	description=S("Reinforced Stone"),
	tiles={"industrialtest_reinforced_stone.png"}
}
if industrialtest.mtgAvailable then
	definition.groups={cracky=3}
	definition.sounds=default.node_sound_stone_defaults()
	definition.on_blast=function(pos,intensity)
		if intensity>20 then
			minetest.remove_node(pos)
			minetest.add_item(pos,ItemStack("industrialtest:reinforced_stone"))
		end
	end
elseif industrialtest.mclAvailable then
	definition.groups={
		pickaxey=1,
		stone=1,
		building_block=1,
		material_stone=1
	}
	definition.sounds=mcl_sounds.node_sound_stone_defaults()
	definition._mcl_blast_resistance=1200
	definition._mcl_hardness=5
end
minetest.register_node("industrialtest:reinforced_stone",definition)
minetest.register_craft({
	type="shaped",
	output="industrialtest:reinforced_stone 8",
	recipe={
		{industrialtest.elementKeys.stone,industrialtest.elementKeys.stone,industrialtest.elementKeys.stone},
		{industrialtest.elementKeys.stone,"industrialtest:advanced_alloy",industrialtest.elementKeys.stone},
		{industrialtest.elementKeys.stone,industrialtest.elementKeys.stone,industrialtest.elementKeys.stone}
	}
})

definition={
	description=S("Reinforced Glass"),
	drawtype="glasslike_framed_optional",
	tiles={"industrialtest_reinforced_glass.png"},
	use_texture_alpha="clip",
	paramtype="light",
	sunlight_propagates=true
}
if industrialtest.mtgAvailable then
	definition.groups={cracky=3}
	definition.sounds=default.node_sound_glass_defaults()
	definition.on_blast=function(pos,intensity)
		if intensity>10 then
			minetest.remove_node(pos)
			minetest.add_item(pos,ItemStack("industrialtest:reinforced_glass"))
		end
	end
elseif industrialtest.mclAvailable then
	definition.groups={
		glass=1,
		building_block=1,
		material_glass=1
	}
	definition.sounds=mcl_sounds.node_sound_glass_defaults()
	definition._mcl_blast_resistance=15
	definition._mcl_hardness=1.5
end
minetest.register_node("industrialtest:reinforced_glass",definition)
minetest.register_craft({
	type="shaped",
	output="industrialtest:reinforced_glass 7",
	recipe={
		{industrialtest.elementKeys.glass,industrialtest.elementKeys.glass,industrialtest.elementKeys.glass},
		{"industrialtest:advanced_alloy",industrialtest.elementKeys.glass,"industrialtest:advanced_alloy"},
		{industrialtest.elementKeys.glass,industrialtest.elementKeys.glass,industrialtest.elementKeys.glass}
	}
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:reinforced_glass 7",
	recipe={
		{industrialtest.elementKeys.glass,"industrialtest:advanced_alloy",industrialtest.elementKeys.glass},
		{industrialtest.elementKeys.glass,industrialtest.elementKeys.glass,industrialtest.elementKeys.glass},
		{industrialtest.elementKeys.glass,"industrialtest:advanced_alloy",industrialtest.elementKeys.glass}
	}
})
