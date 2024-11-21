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

local requiredMtgModules={"default","bucket","tnt","stairs"}
industrialtest.mtgAvailable=true
for _,mod in ipairs(requiredMtgModules) do
	if not minetest.get_modpath(mod) then
		industrialtest.mtgAvailable=false
		break
	end
end
local requiredMclModules={"mcl_core","mcl_copper","mcl_armor","mcl_deepslate","mcl_nether","mcl_buckets","mcl_explosions","mcl_stairs"}
industrialtest.mclAvailable=true
for _,mod in ipairs(requiredMclModules) do
	if not minetest.get_modpath(mod) then
		industrialtest.mclAvailable=false
		break
	end
end

industrialtest.mods={}
if industrialtest.mtgAvailable then
	industrialtest.mods._3dArmor=minetest.get_modpath("3d_armor")
elseif industrialtest.mclAvailable then
	industrialtest.mods.mclRubber=minetest.get_modpath("mcl_rubber")
end
industrialtest.mods.pipeworks=minetest.get_modpath("pipeworks")
industrialtest.mods.mesecons=minetest.get_modpath("mesecons")

if industrialtest.mtgAvailable and not industrialtest.mods._3dArmor then
	error("IndustrialTest requires 3D Armor when used with Minetest Game")
end

industrialtest.elementKeys={}
industrialtest.internal={}

if industrialtest.mclAvailable then
	industrialtest.stackMax=64

	industrialtest.internal.mclMakeStrippedTrunk=function(itemstack,placer,pointedThing,electricTool)
		-- Taken from https://git.minetest.land/MineClone2/MineClone2/src/branch/master/mods/ITEMS/mcl_tools/init.lua#L360
		if pointedThing.type ~= "node" then return end

		local node = minetest.get_node(pointedThing.under)
		local noddef = minetest.registered_nodes[minetest.get_node(pointedThing.under).name]

		if not placer:get_player_control().sneak and noddef.on_rightclick then
			return minetest.item_place(itemstack, placer, pointedThing)
		end
		if minetest.is_protected(pointedThing.under, placer:get_player_name()) then
			minetest.record_protection_violation(pointedThing.under, placer:get_player_name())
			return itemstack
		end

		if noddef._mcl_stripped_variant == nil then
			return itemstack
		else
			minetest.swap_node(pointedThing.under, {name=noddef._mcl_stripped_variant, param2=node.param2})
			if not minetest.is_creative_enabled(placer:get_player_name()) or electricTool then
				-- Add wear (as if digging a axey node)
				local toolname = itemstack:get_name()
				local wear = mcl_autogroup.get_wear(toolname, "axey")
				itemstack:add_wear(wear)
			end
		end
		return itemstack
	end

	industrialtest.internal.explode=function(pos,radius,dropChance)
		mcl_explosions.explode(pos,radius,{drop_chance=dropChance})
	end

	industrialtest.internal.getItemSlotBg=mcl_formspec.get_itemslot_bg
elseif industrialtest.mtgAvailable then
	industrialtest.stackMax=99

	industrialtest.internal.explode=function(pos,radius)
		tnt.boom(pos,{radius=radius})
	end

	industrialtest.internal.getItemSlotBg=function()
		return ""
	end
end

-- compatibilty that adds not existing elements
if industrialtest.mclAvailable then
	industrialtest.internal.registerMetal=function(name,displayName,oreBlastResistance,oreHardness,rawBlockBlastResistance,rawBlockHardness,blockBlastResistance,blockHardness)
		minetest.register_craftitem("industrialtest:raw_"..name,{
			description=S("Raw "..displayName),
			inventory_image="industrialtest_mcl_raw_"..name..".png"
		})
		minetest.register_craftitem("industrialtest:"..name.."_ingot",{
			description=S(displayName.." Ingot"),
			inventory_image="industrialtest_mcl_"..name.."_ingot.png"
		})
		minetest.register_node("industrialtest:stone_with_"..name,{
			description=S(displayName.." Ore"),
			tiles={"default_stone.png^industrialtest_mcl_stone_with_"..name..".png"},
			sounds=mcl_sounds.node_sound_stone_defaults(),
			drop="industrialtest:raw_"..name,
			is_ground_content=true,
			groups={pickaxey=3,building_block=1,material_stone=1,blast_furnace_smeltable=1},
			_mcl_blast_resistance = oreBlastResistance,
			_mcl_hardness = oreHardness,
			_mcl_silk_touch_drop = true,
			_mcl_fortune_drop = mcl_core.fortune_drop_ore,
		})
		minetest.register_node("industrialtest:deepslate_with_"..name,{
			description=S("Deepslate with "..displayName),
			tiles={"mcl_deepslate_top.png^industrialtest_mcl_stone_with_"..name..".png","mcl_deepslate_top.png^industrialtest_mcl_stone_with_"..name..".png","mcl_deepslate.png^industrialtest_mcl_stone_with_"..name..".png"},
			sounds=mcl_sounds.node_sound_stone_defaults(),
			drop="industrialtest:raw_"..name,
			paramtype2="facedir",
			is_ground_content=true,
			on_place=mcl_util.rotate_axis,
			groups={pickaxey=3,building_block=1,material_stone=1,blast_furnace_smeltable=1},
			_mcl_blast_resistance = oreBlastResistance,
			_mcl_hardness = oreHardness,
			_mcl_silk_touch_drop = true,
			_mcl_fortune_drop = mcl_core.fortune_drop_ore,
		})
		minetest.register_node("industrialtest:raw_"..name.."_block",{
			description=S("Raw "..displayName.." Block"),
			tiles={"industrialtest_mcl_raw_"..name.."_block.png"},
			groups={pickaxey=2,building_block=1,blast_furnace_smeltable=1},
			sounds=mcl_sounds.node_sound_metal_defaults(),
			_mcl_blast_resistance=rawBlockBlastResistance,
			_mcl_hardness=rawBlockHardness,
		})
		minetest.register_node("industrialtest:"..name.."_block",{
			description=S("Block of "..displayName),
			tiles={"industrialtest_"..name.."_block.png"},
			groups={pickaxey=2,building_block=1},
			sounds=mcl_sounds.node_sound_metal_defaults(),
			_mcl_blast_resistance=blockBlastResistance,
			_mcl_hardness=blockHardness,
		})
		minetest.register_craft({
			type="cooking",
			output="industrialtest:"..name.."_ingot",
			recipe="industrialtest:raw_"..name
		})
		minetest.register_craft({
			type="shaped",
			output="industrialtest:raw_"..name.."_block",
			recipe={
				{"industrialtest:raw"..name,"industrialtest:raw"..name,"industrialtest:raw"..name},
				{"industrialtest:raw"..name,"industrialtest:raw"..name,"industrialtest:raw"..name},
				{"industrialtest:raw"..name,"industrialtest:raw"..name,"industrialtest:raw"..name}
			}
		})
		minetest.register_craft({
			type="shaped",
			output="industrialtest:"..name.."_block",
			recipe={
				{"industrialtest:"..name.."_ingot","industrialtest:"..name.."_ingot","industrialtest:"..name.."_ingot"},
				{"industrialtest:"..name.."_ingot","industrialtest:"..name.."_ingot","industrialtest:"..name.."_ingot"},
				{"industrialtest:"..name.."_ingot","industrialtest:"..name.."_ingot","industrialtest:"..name.."_ingot"}
			}
		})
		minetest.register_craft({
			type="shaped",
			output="industrialtest:raw_"..name.."_block",
			recipe={
				{"industrialtest:raw_"..name,"industrialtest:raw_"..name,"industrialtest:raw_"..name},
				{"industrialtest:raw_"..name,"industrialtest:raw_"..name,"industrialtest:raw_"..name},
				{"industrialtest:raw_"..name,"industrialtest:raw_"..name,"industrialtest:raw_"..name}
			}
		})
		minetest.register_craft({
			type="shapeless",
			output="industrialtest:"..name.."_ingot 9",
			recipe={
				"industrialtest:"..name.."_block"
			}
		})
		minetest.register_craft({
			type="shapeless",
			output="industrialtest:raw_"..name.." 9",
			recipe={
				"industrialtest:raw_"..name.."_block"
			}
		})
	end
	industrialtest.registerToolset=function(material,materialItem,materialDisplayName,config)
		minetest.register_tool("industrialtest:"..material.."_pickaxe",{
			description=S(materialDisplayName.." Pickaxe"),
			inventory_image="industrialtest_mcl_"..material.."_pickaxe.png",
			groups={tool=1,pickaxe=1,dig_speed_class=config.digSpeedClass,enchantability=config.enchantability},
			tool_capabilities={
				full_punch_interval=1,
				max_drop_level=config.dropLevel,
				damage_groups={fleshy=config.damage},
			},
			sound={breaks="default_tool_breaks"},
			_repair_material="industrialtest:"..material,
			_mcl_toollike_wield=true,
			_mcl_diggroups={
				pickaxey={speed=config.speed,level=config.level,uses=config.uses}
			}
		})
		minetest.register_tool("industrialtest:"..material.."_shovel",{
			description=S(materialDisplayName.." Shovel"),
			inventory_image="industrialtest_mcl_"..material.."_shovel.png",
			groups={tool=1,shovel=1,dig_speed_class=config.digSpeedClass,enchantability=config.enchantability},
			tool_capabilities={
				full_punch_interval=1,
				max_drop_level=config.dropLevel,
				damage_groups={fleshy=config.damage}
			},
			on_place=function(itemstack,placer,pointedThing)
				-- Taken from https://git.minetest.land/MineClone2/MineClone2/src/branch/master/mods/ITEMS/mcl_tools/init.lua#L159
				-- Use pointed node's on_rightclick function first, if present
				local node = minetest.get_node(pointedThing.under)
				if placer and not placer:get_player_control().sneak then
					if minetest.registered_nodes[node.name] and minetest.registered_nodes[node.name].on_rightclick then
						return minetest.registered_nodes[node.name].on_rightclick(pointedThing.under, node, placer, itemstack) or itemstack
					end
				end

				-- Only make grass path if tool used on side or top of target node
				if pointedThing.above.y < pointedThing.under.y then
					return itemstack
				end

				if (minetest.get_item_group(node.name, "path_creation_possible") == 1) then
					local above = table.copy(pointedThing.under)
					above.y = above.y + 1
					if minetest.get_node(above).name == "air" then
						if minetest.is_protected(pointedThing.under, placer:get_player_name()) then
							minetest.record_protection_violation(pointedThing.under, placer:get_player_name())
							return itemstack
						end

						if not minetest.is_creative_enabled(placer:get_player_name()) then
							-- Add wear (as if digging a shovely node)
							local toolname = itemstack:get_name()
							local wear = mcl_autogroup.get_wear(toolname, "shovely")
							itemstack:add_wear(wear)
						end
						minetest.sound_play({name="default_grass_footstep", gain=1}, {pos = above}, true)
						minetest.swap_node(pointedThing.under, {name="mcl_core:grass_path"})
					end
				end
				return itemstack
			end,
			sound={breaks="default_tool_breaks"},
			_repair_material="industrialtest:"..materialItem,
			_mcl_toollike_wield=true,
			_mcl_diggroups={
				shovely={speed=config.speed,level=config.level,uses=config.uses}
			}
		})
		minetest.register_tool("industrialtest:"..material.."_axe",{
			description=S(materialDisplayName.." Axe"),
			inventory_image="industrialtest_mcl_"..material.."_axe.png",
			groups={tool=1,axe=1,dig_speed_class=config.digSpeedClass,enchantability=config.enchantability},
			tool_capabilities={
				full_punch_interval=1,
				max_level_drop=config.levelDrop,
				damage_groups={fleshy=config.damage+3},
			},
			on_place=industrialtest.internal.mclMakeStrippedTrunk,
			sound={breaks="default_tool_breaks"},
			_repair_material="industrialtest:"..materialItem,
			_mcl_toollike_wield=true,
			_mcl_diggroups={
				axey={speed=config.speed,level=config.level,uses=config.uses}
			}
		})
		minetest.register_tool("industrialtest:"..material.."_sword",{
			description=S(materialDisplayName.." Sword"),
			inventory_image="industrialtest_mcl_"..material.."_sword.png",
			groups={weapon=1,sword=1,dig_speed_class=config.digSpeedClass,enchantability=config.enchantability},
			tool_capabilities={
				full_punch_interval=0.625,
				max_drop_level=config.maxDropLevel,
				damage_groups={fleshy=config.damage+2},
			},
			sound={breaks="default_tool_breaks"},
			_repair_material="industrialtest:"..materialItem,
			_mcl_toollike_wield=true,
			_mcl_diggroups={
				swordy={speed=config.speed,level=config.level,uses=config.uses},
				swordy_cobweb={speed=config.speed,level=config.level,uses=config.uses}
			}
		})
		minetest.register_tool("industrialtest:"..material.."_hoe",{
			description=S(materialDisplayName.." Hoe"),
			inventory_image="industrialtest_mcl_"..material.."_hoe.png",
			groups={tool=1,hoe=1,enchantability=config.enchantability},
			tool_capabilities={
				full_punch_interval=1,
				damage_groups={fleshy=1}
			},
			on_place=function(itemstack,user,pointedThing)
				-- Taken from https://git.minetest.land/MineClone2/MineClone2/src/branch/master/mods/ITEMS/mcl_farming/hoes.lua#L3
				local function create_soil(pos, inv)
					if pos == nil then
						return false
					end
					local node = minetest.get_node(pos)
					local name = node.name
					local above = minetest.get_node({x=pos.x, y=pos.y+1, z=pos.z})
					if minetest.get_item_group(name, "cultivatable") == 2 then
						if above.name == "air" then
							node.name = "mcl_farming:soil"
							minetest.set_node(pos, node)
							minetest.sound_play("default_dig_crumbly", { pos = pos, gain = 0.5 }, true)
							return true
						end
					elseif minetest.get_item_group(name, "cultivatable") == 1 then
						if above.name == "air" then
							node.name = "mcl_core:dirt"
							minetest.set_node(pos, node)
							minetest.sound_play("default_dig_crumbly", { pos = pos, gain = 0.6 }, true)
							return true
						end
					end
					return false
				end

				-- Taken from https://git.minetest.land/MineClone2/MineClone2/src/branch/master/mods/ITEMS/mcl_farming/hoes.lua#L29
				-- Call on_rightclick if the pointed node defines it
				local node = minetest.get_node(pointedThing.under)
				if user and not user:get_player_control().sneak then
					if minetest.registered_nodes[node.name] and minetest.registered_nodes[node.name].on_rightclick then
						return minetest.registered_nodes[node.name].on_rightclick(pointedThing.under, node, user, itemstack) or itemstack
					end
				end

				if minetest.is_protected(pointedThing.under, user:get_player_name()) then
					minetest.record_protection_violation(pointedThing.under, user:get_player_name())
					return itemstack
				end

				if create_soil(pointedThing.under, user:get_inventory()) then
					if not minetest.is_creative_enabled(user:get_player_name()) then
						itemstack:add_wear(65535/config.uses)
					end
					return itemstack
				end
			end,
			_repair_material="industrialtest:"..materialItem,
			_mcl_toollike_wield=true,
			_mcl_diggroups={
				hoey={speed=config.speed,level=config.level,uses=config.uses}
			}
		})
		mcl_armor.register_set({
			name=material,
			description=materialDisplayName,
			durability=config.uses,
			points=config.armorPoints,
			craft_material="industrialtest:"..materialItem,
			cook_material=config.armorCookMaterial,
			sound_equip=config.armorEquipSound,
			sound_unequip=config.armorUnequipSound,
			enchantability=config.enchantability,
			textures={
				head="industrialtest_mcl_"..material.."_helmet.png",
				torso="industrialtest_mcl_"..material.."_chestplate.png",
				legs="industrialtest_mcl_"..material.."_leggings.png",
				feet="industrialtest_mcl_"..material.."_boots.png"
			}
		})
		minetest.register_craft({
			type="shaped",
			output="industrialtest:"..material.."_pickaxe",
			recipe={
				{"industrialtest:"..materialItem,"industrialtest:"..materialItem,"industrialtest:"..materialItem},
				{"","mcl_core:stick",""},
				{"","mcl_core:stick",""}
			}
		})
		minetest.register_craft({
			type="shaped",
			output="industrialtest:"..material.."_shovel",
			recipe={
				{"industrialtest:"..materialItem},
				{"mcl_core:stick"},
				{"mcl_core:stick"}
			}
		})
		minetest.register_craft({
			type="shaped",
			output="industrialtest:"..material.."_axe",
			recipe={
				{"industrialtest:"..materialItem,"industrialtest:"..materialItem},
				{"industrialtest:"..materialItem,"mcl_core:stick"},
				{"","mcl_core:stick"}
			}
		})
		minetest.register_craft({
			type="shaped",
			output="industrialtest:"..material.."_axe",
			recipe={
				{"industrialtest:"..materialItem,"industrialtest:"..materialItem},
				{"mcl_core:stick","industrialtest:"..materialItem},
				{"mcl_core:stick",""}
			}
		})
		minetest.register_craft({
			type="shaped",
			output="industrialtest:"..material.."_sword",
			recipe={
				{"industrialtest:"..materialItem},
				{"industrialtest:"..materialItem},
				{"mcl_core:stick"}
			}
		})
		minetest.register_craft({
			type="shaped",
			output="industrialtest:"..material.."_hoe",
			recipe={
				{"industrialtest:"..materialItem,"industrialtest:"..materialItem},
				{"","mcl_core:stick"},
				{"","mcl_core:stick"}
			}
		})
		minetest.register_craft({
			type="shaped",
			output="industrialtest:"..material.."_hoe",
			recipe={
				{"industrialtest:"..materialItem,"industrialtest:"..materialItem},
				{"mcl_core:stick",""},
				{"mcl_core:stick",""}
			}
		})
	end
	industrialtest.gameTexturePrefix="mcl"
	-- assign element keys for elements that are required later
	industrialtest.elementKeys.stick="mcl_core:stick"
	industrialtest.elementKeys.flint="mcl_core:flint"
	industrialtest.elementKeys.snowball="mcl_throwing:snowball"
	industrialtest.elementKeys.string="mcl_mobitems:string"
	industrialtest.elementKeys.junglePlanks="mcl_core:junglewood"
	industrialtest.elementKeys.wood="mcl_core:tree"
	industrialtest.elementKeys.ironIngot="mcl_core:iron_ingot"
	industrialtest.elementKeys.ironLump="mcl_raw_ores:raw_iron"
	industrialtest.elementKeys.goldIngot="mcl_core:gold_ingot"
	industrialtest.elementKeys.goldLump="mcl_raw_ores:raw_gold"
	industrialtest.elementKeys.copperIngot="mcl_copper:copper_ingot"
	industrialtest.elementKeys.copperLump="mcl_copper:raw_copper"
	industrialtest.elementKeys.uraniumLump="industrialtest:raw_uranium"
	industrialtest.elementKeys.coal="mcl_core:coal_lump"
	industrialtest.elementKeys.clay="mcl_core:clay_lump"
	industrialtest.elementKeys.diamond="mcl_core:diamond"
	industrialtest.elementKeys.blueDye="mcl_core:lapis"
	industrialtest.elementKeys.yellowDust="mcl_nether:glowstone_dust"
	industrialtest.elementKeys.bucket="mcl_buckets:bucket_empty"
	industrialtest.elementKeys.bucketWithLava="mcl_buckets:bucket_lava"
	industrialtest.elementKeys.bucketWithWater="mcl_buckets:bucket_water"
	industrialtest.elementKeys.glass="mcl_core:glass"
	industrialtest.elementKeys.powerCarrier="mesecons:mesecon"
	industrialtest.elementKeys.furnace="mcl_furnaces:furnace"
	industrialtest.elementKeys.stone="mcl_core:stone"
	industrialtest.elementKeys.stoneSlab="mcl_stairs:slab_stone"
	industrialtest.elementKeys.cobble="mcl_core:cobble"
	industrialtest.elementKeys.mossCobble="mcl_core:mossycobble"
	industrialtest.elementKeys.sand="mcl_core:sand"
	industrialtest.elementKeys.gravel="mcl_core:gravel"
	industrialtest.elementKeys.ice="mcl_core:ice"
	industrialtest.elementKeys.sandstone="mcl_core:sandstone"
	industrialtest.elementKeys.dirt="mcl_core:dirt"
	industrialtest.elementKeys.grassBlock="mcl_core:dirt_with_grass"
	industrialtest.elementKeys.obsidian="mcl_core:obsidian"
	industrialtest.elementKeys.whiteWool="mcl_wool:white"
	industrialtest.elementKeys.coalBlock="mcl_core:coalblock"
	industrialtest.elementKeys.stoneWithCoal="mcl_core:stone_with_coal"
	industrialtest.elementKeys.clayBlock="mcl_core:clay"
	industrialtest.elementKeys.diamondBlock="mcl_core:diamondblock"
	industrialtest.elementKeys.stoneWithDiamond="mcl_core:stone_with_diamond"
	industrialtest.elementKeys.ironBlock="mcl_core:ironblock"
	industrialtest.elementKeys.stoneWithIron="mcl_core:stone_with_iron"
	industrialtest.elementKeys.goldBlock="mcl_core:goldblock"
	industrialtest.elementKeys.stoneWithGold="mcl_core:stone_with_gold"
	industrialtest.elementKeys.copperBlock="mcl_copper:block"
	industrialtest.elementKeys.stoneWithCopper="mcl_copper:stone_with_copper"
	industrialtest.elementKeys.leadLump="industrialtest:raw_lead"
	industrialtest.elementKeys.ironPickaxe="mcl_tools:pick_iron"
	industrialtest.elementKeys.ironHelmet="mcl_tools:helmet_iron"
	industrialtest.elementKeys.ironBoots="mcl_armor:boots_iron"
	industrialtest.elementKeys.lavaSource="mcl_core:lava_source"
	industrialtest.elementKeys.waterSource="mcl_core:water_source"
	industrialtest.elementKeys.sugarCane="mcl_core:reeds"
	industrialtest.elementKeys.wheat="mcl_farming:wheat_item"
	industrialtest.elementKeys.dryShrub="mcl_core:deadbush"
	industrialtest.elementKeys.cactus="mcl_core:cactus"
	industrialtest.elementKeys.gunpowder="mcl_mobitems:gunpowder"
	industrialtest.elementKeys.groupSapling="group:sapling"
	industrialtest.elementKeys.groupLeaves="group:leaves"
	industrialtest.elementKeys.stickyResin=(industrialtest.mods.mclRubber and "mcl_rubber:rubber_raw" or "industrialtest:sticky_resin")
	industrialtest.elementKeys.rubber=(industrialtest.mods.mclRubber and "mcl_rubber:rubber" or "industrialtest:rubber")
	industrialtest.elementKeys.rubberWood=(industrialtest.mods.mclRubber and "mcl_rubber:rubbertree" or "industrialtest:rubber_wood")
	industrialtest.elementKeys.rubberSapling=(industrialtest.mods.mclRubber and "mcl_rubber:rubbersapling" or "industrialtest:rubber_sapling")
	industrialtest.elementKeys.treetap=(industrialtest.mods.mclRubber and "mcl_rubber:treetap" or "industrialtest:treetap")
	
	-- register required minerals that are not available in MCL
	industrialtest.internal.registerMetal("tin","Tin",3,3)
	industrialtest.elementKeys.tinIngot="industrialtest:tin_ingot"
	industrialtest.elementKeys.tinBlock="industrialtest:tin_block"
	industrialtest.elementKeys.stoneWithTin="industrialtest:stone_with_tin"
	industrialtest.elementKeys.tinLump="industrialtest:raw_tin"

	--register other items that are not available in MCL
	minetest.register_craftitem("industrialtest:bronze_ingot",{
		description=S("Bronze Ingot"),
		inventory_image="industrialtest_mcl_bronze_ingot.png"
	})
	minetest.register_craftitem("industrialtest:bronze_nugget",{
		description=S("Bronze Nugget"),
		inventory_image="industrialtest_mcl_bronze_nugget.png"
	})
	minetest.register_craft({
		type="shaped",
		output="industrialtest:bronze_ingot 9",
		recipe={
			{"mcl_copper:copper_ingot","mcl_copper:copper_ingot","mcl_copper:copper_ingot"},
			{"mcl_copper:copper_ingot","industrialtest:tin_ingot","mcl_copper:copper_ingot"},
			{"mcl_copper:copper_ingot","mcl_copper:copper_ingot","mcl_copper:copper_ingot"}
		}
	})
	minetest.register_craft({
		type="shapeless",
		output="industrialtest:bronze_ingot 9",
		recipe={
			"industrialtest:bronze_block"
		}
	})
	minetest.register_craft({
		type="shaped",
		output="industrialtest:bronze_ingot",
		recipe={
			{"industrialtest:bronze_nugget","industrialtest:bronze_nugget","industrialtest:bronze_nugget"},
			{"industrialtest:bronze_nugget","industrialtest:bronze_nugget","industrialtest:bronze_nugget"},
			{"industrialtest:bronze_nugget","industrialtest:bronze_nugget","industrialtest:bronze_nugget"},
		}
	})
	minetest.register_craft({
		type="shapeless",
		output="industrialtest:bronze_nugget 9",
		recipe={
			"industrialtest:bronze_ingot"
		}
	})
	industrialtest.elementKeys.bronzeIngot="industrialtest:bronze_ingot"
	industrialtest.registerToolset("bronze","bronze_ingot","Bronze",{
		digSpeedClass=4,
		dropLevel=4,
		speed=6,
		level=4,
		uses=200,
		damage=4,
		armorPoints={
			head=2,
			torso=6,
			legs=5,
			feet=2
		},
		armorCookMaterial="industrialtest:bronze_nugget",
		armorEquipSound="mcl_armor_equip_iron",
		armorUnequipSound="mcl_armor_unequip_iron",
		enchantability=15,
	})

	--register other blocks that are not availabe in MCL
	minetest.register_node("industrialtest:bronze_block",{
		description=S("Block of Bronze"),
		tiles={"industrialtest_mcl_bronze_block.png"},
		groups={pickaxey=2,building_block=1},
		sounds=mcl_sounds.node_sound_metal_defaults(),
		_mcl_blast_resistance=3,
		_mcl_hardness=3,
	})
	industrialtest.elementKeys.bronzeBlock="industrialtest:bronze_block"
	minetest.register_craft({
		type="shaped",
		output="industrialtest:bronze_block",
		recipe={
			{"industrialtest:bronze_ingot","industrialtest:bronze_ingot","industrialtest:bronze_ingot"},
			{"industrialtest:bronze_ingot","industrialtest:bronze_ingot","industrialtest:bronze_ingot"},
			{"industrialtest:bronze_ingot","industrialtest:bronze_ingot","industrialtest:bronze_ingot"}
		}
	})

	minetest.register_ore({
		ore_type="scatter",
		ore="industrialtest:stone_with_tin",
		wherein={"mcl_core:stone","mcl_core:diorite","mcl_core:andesite","mcl_core:granite"},
		clust_scarcity=10*10*10,
		clust_num_ores=5,
		clust_size=3,
		y_max=mcl_worlds.layer_to_y(39),
		y_min=mcl_vars.mg_overworld_min
	})
	minetest.register_ore({
		ore_type="scatter",
		ore="industrialtest:deepslate_with_tin",
		wherein={"mcl_deepslate:deepslate","mcl_deepslate:tuff"},
		clust_scarcity=10*10*10,
		clust_num_ores=5,
		clust_size=3,
		y_max=mcl_worlds.layer_to_y(16),
		y_min=mcl_vars.mg_overworld_min
	})
elseif industrialtest.mtgAvailable then
	industrialtest.internal.registerMetal=function(name,displayName,hardness)
		minetest.register_craftitem("industrialtest:"..name.."_lump",{
			description=S(displayName.." Lump"),
			inventory_image="industrialtest_mtg_"..name.."_lump.png"
		})
		minetest.register_craftitem("industrialtest:"..name.."_ingot",{
			description=S(displayName.." Ingot"),
			inventory_image="industrialtest_mtg_"..name.."_ingot.png"
		})
		minetest.register_node("industrialtest:stone_with_"..name,{
			description=S(displayName.." Ore"),
			tiles={"default_stone.png^industrialtest_mtg_stone_with_"..name..".png"},
			sounds=default.node_sound_stone_defaults(),
			drop="industrialtest:"..name.."_lump",
			groups={cracky=hardness},
		})
		minetest.register_node("industrialtest:"..name.."_block",{
			description=S("Block of "..displayName),
			tiles={"industrialtest_"..name.."_block.png"},
			groups={cracky=hardness,level=2},
			sounds=default.node_sound_metal_defaults(),
		})
		minetest.register_craft({
			type="cooking",
			output="industrialtest:"..name.."_ingot",
			recipe="industrialtest:"..name.."_lump"
		})
		minetest.register_craft({
			type="shaped",
			output="industrialtest:"..name.."_block",
			recipe={
				{"industrialtest:"..name.."_ingot","industrialtest:"..name.."_ingot","industrialtest:"..name.."_ingot"},
				{"industrialtest:"..name.."_ingot","industrialtest:"..name.."_ingot","industrialtest:"..name.."_ingot"},
				{"industrialtest:"..name.."_ingot","industrialtest:"..name.."_ingot","industrialtest:"..name.."_ingot"}
			}
		})
		minetest.register_craft({
			type="shapeless",
			output="industrialtest:"..name.."_ingot 9",
			recipe={
				"industrialtest:"..name.."_block"
			}
		})
		minetest.register_craft({
			type="shapeless",
			output="industrialtest:raw_"..name.." 9",
			recipe={
				"industrialtest:raw_"..name.."_block"
			}
		})
	end
	industrialtest.gameTexturePrefix="mtg"
	industrialtest.elementKeys.tinIngot="default:tin_ingot"
	industrialtest.elementKeys.tinLump="default:tin_lump"
	industrialtest.elementKeys.bronzeIngot="default:bronze_ingot"
	industrialtest.elementKeys.ironIngot="default:steel_ingot"
	industrialtest.elementKeys.ironLump="default:iron_lump"
	industrialtest.elementKeys.goldIngot="default:gold_ingot"
	industrialtest.elementKeys.goldLump="default:gold_lump"
	industrialtest.elementKeys.copperIngot="default:copper_ingot"
	industrialtest.elementKeys.copperLump="default:copper_lump"
	industrialtest.elementKeys.uraniumLump="industrialtest:uranium_lump"
	industrialtest.elementKeys.coal="default:coal_lump"
	industrialtest.elementKeys.clay="default:clay_lump"
	industrialtest.elementKeys.diamond="default:diamond"
	industrialtest.elementKeys.stick="default:stick"
	industrialtest.elementKeys.flint="default:flint"
	industrialtest.elementKeys.snowball="default:snow"
	industrialtest.elementKeys.blueDye="dye:blue"
	industrialtest.elementKeys.yellowDust="dye:yellow"
	industrialtest.elementKeys.bucket="bucket:bucket_empty"
	industrialtest.elementKeys.bucketWithLava="bucket:bucket_lava"
	industrialtest.elementKeys.bucketWithWater="bucket:bucket_water"
	industrialtest.elementKeys.string="farming:string"
	industrialtest.elementKeys.junglePlanks="default:junglewood"
	industrialtest.elementKeys.wood="default:tree"
	industrialtest.elementKeys.glass="default:glass"
	industrialtest.elementKeys.powerCarrier="default:mese_crystal_fragment"
	industrialtest.elementKeys.furnace="default:furnace"
	industrialtest.elementKeys.stone="default:stone"
	industrialtest.elementKeys.stoneSlab="stairs:slab_stone"
	industrialtest.elementKeys.cobble="default:cobble"
	industrialtest.elementKeys.mossCobble="default:mossycobble"
	industrialtest.elementKeys.sand="default:sand"
	industrialtest.elementKeys.gravel="default:gravel"
	industrialtest.elementKeys.ice="default:ice"
	industrialtest.elementKeys.sandstone="default:sandstone"
	industrialtest.elementKeys.dirt="default:dirt"
	industrialtest.elementKeys.grassBlock="default:dirt_with_grass"
	industrialtest.elementKeys.obsidian="default:obsidian"
	industrialtest.elementKeys.whiteWool="wool:white"
	industrialtest.elementKeys.coalBlock="default:coalblock"
	industrialtest.elementKeys.stoneWithCoal="default:stone_with_coal"
	industrialtest.elementKeys.clayBlock="default:clay"
	industrialtest.elementKeys.diamondBlock="default:diamondblock"
	industrialtest.elementKeys.stoneWithDiamond="default:stone_with_diamond"
	industrialtest.elementKeys.ironBlock="default:steelblock"
	industrialtest.elementKeys.stoneWithIron="default:stone_with_iron"
	industrialtest.elementKeys.goldBlock="default:goldblock"
	industrialtest.elementKeys.stoneWithGold="default:stone_with_gold"
	industrialtest.elementKeys.copperBlock="default:copperblock"
	industrialtest.elementKeys.stoneWithCopper="default:stone_with_copper"
	industrialtest.elementKeys.tinBlock="default:tinblock"
	industrialtest.elementKeys.stoneWithTin="default:stone_with_tin"
	industrialtest.elementKeys.bronzeBlock="default:bronzeblock"
	industrialtest.elementKeys.leadLump="industrialtest:lead_lump"
	industrialtest.elementKeys.ironPickaxe="default:pick_steel"
	industrialtest.elementKeys.ironHelmet="3d_armor:helmet_steel"
	industrialtest.elementKeys.ironBoots="3d_armor:boots_steel"
	industrialtest.elementKeys.lavaSource="default:lava_source"
	industrialtest.elementKeys.waterSource="default:water_source"
	industrialtest.elementKeys.sugarCane="default:papyrus"
	industrialtest.elementKeys.wheat="farming:wheat"
	industrialtest.elementKeys.dryShrub="default:dry_shrub"
	industrialtest.elementKeys.cactus="default:cactus"
	industrialtest.elementKeys.gunpowder="tnt:gunpowder"
	industrialtest.elementKeys.groupSapling="group:sapling"
	industrialtest.elementKeys.groupLeaves="group:leaves"
	industrialtest.elementKeys.stickyResin="industrialtest:sticky_resin"
	industrialtest.elementKeys.rubber="industrialtest:rubber"
	industrialtest.elementKeys.rubberWood="industrialtest:rubber_wood"
	industrialtest.elementKeys.rubberSapling="industrialtest:rubber_sapling"
	industrialtest.elementKeys.treetap="industrialtest:treetap"
else
	error("No compatible games found!")
end
