-- IndustrialTest
-- Copyright (C) 2024 mrkubax10

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

local electricHoe={}

electricHoe.afterUse=function(itemstack,config)
	local meta=itemstack:get_meta()
	industrialtest.api.addPowerToItem(itemstack,-20)
	if meta:get_int("industrialtest.powerAmount")<20 then
		itemstack:set_name("industrialtest:"..config.name)
	end
	return itemstack
end

local function registerElectricHoe(config)
	local definition={
		description=config.displayName,
		inventory_image="industrialtest_"..config.name..".png",
		_industrialtest_powerStorage=true,
		_industrialtest_powerCapacity=10000,
		_industrialtest_powerFlow=industrialtest.api.lvPowerFlow,
		_industrialtest_inactiveName="industrialtest:"..config.name
	}
	if industrialtest.mtgAvailable then
		-- Taken and adapted from farming mod from Minetest Game
		local function onUse(user,pointed)
			local pt = pointed
			-- check if pointing at a node
			if not pt then
				return false
			end
			if pt.type ~= "node" then
				return false
			end

			local under = minetest.get_node(pt.under)
			local p = {x=pt.under.x, y=pt.under.y+1, z=pt.under.z}
			local above = minetest.get_node(p)

			-- return if any of the nodes is not registered
			if not minetest.registered_nodes[under.name] then
				return false
			end
			if not minetest.registered_nodes[above.name] then
				return false
			end

			-- check if the node above the pointed thing is air
			if above.name ~= "air" then
				return false
			end

			-- check if pointing at soil
			if minetest.get_item_group(under.name, "soil") ~= 1 then
				return false
			end

			-- check if (wet) soil defined
			local regN = minetest.registered_nodes
			if regN[under.name].soil == nil or regN[under.name].soil.wet == nil or regN[under.name].soil.dry == nil then
				return false
			end

			local player_name = user and user:get_player_name() or ""

			if minetest.is_protected(pt.under, player_name) then
				minetest.record_protection_violation(pt.under, player_name)
				return false
			end
			if minetest.is_protected(pt.above, player_name) then
				minetest.record_protection_violation(pt.above, player_name)
				return false
			end

			-- turn the node into soil and play sound
			minetest.set_node(pt.under, {name = regN[under.name].soil.dry})
			minetest.sound_play("default_dig_crumbly", {
				pos = pt.under,
				gain = 0.3,
			}, true)

			return true
		end
		definition.groups={
			hoe=1
		}
		definition.on_use=function(itemstack,user,pointed)
			local meta=itemstack:get_meta()
			if meta:get_int("industrialtest.powerAmount")>=20 and onUse(user,pointed) then
				industrialtest.api.addPowerToItem(itemstack,-20)
				return itemstack
			end
			return nil
		end
	elseif industrialtest.mclAvailable then
		-- Taken from https://git.minetest.land/MineClone2/MineClone2/src/branch/master/mods/ITEMS/mcl_farming/hoes.lua#L3
		local function createSoil(pos)
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
		definition.tool_capabilities={
			full_punch_interval=0.5
		}
		definition.groups={
			tool=1
		}
		definition.on_place=function(itemstack,user,pointed)
			local node=minetest.get_node(pointed.under)
			if user and not user:get_player_control().sneak then
				if minetest.registered_nodes[node.name] and minetest.registered_nodes[node.name].on_rightclick then
					return minetest.registered_nodes[node.name].on_rightclick(pointed.under,node,user,itemstack) or itemstack
				end
			end
			if minetest.is_protected(pointed.under, user:get_player_name()) then
				minetest.record_protection_violation(pointed.under,user:get_player_name())
				return nil
			end
			local meta=itemstack:get_meta()
			if meta:get_int("industrialtest.powerAmount")>=20 and createSoil(pointed.under) then
				industrialtest.api.addPowerToItem(itemstack,-20)
				return itemstack
			end
			return nil
		end
		definition.after_use=function(itemstack)
			-- Hack to make sure that chainsaw won't be destroyed when has 0 EU in MCL
			return nil
		end
		definition._mcl_toollike_wield=true
		definition._mcl_diggroups={
			hoey={
				speed=config.inactiveDigSpeed,
				level=config.digLevel,
				uses=-1
			}
		}
	end
	minetest.register_tool("industrialtest:"..config.name,definition)
	if industrialtest.mclAvailable then
		definition=table.copy(definition)
		definition._mcl_diggroups.hoey.speed=config.activeDigSpeed
		definition.groups.not_in_creative_inventory=1
		definition.after_use=function(itemstack)
			return electricHoe.afterUse(itemstack,config)
		end
		minetest.register_tool("industrialtest:"..config.name.."_active",definition)
		industrialtest.internal.registeredElectricHoes["industrialtest:"..config.name.."_active"]=true
	end
	industrialtest.internal.registeredElectricHoes["industrialtest:"..config.name]=true
end
local definition={
	name="electric_hoe",
	displayName=S("Electric Hoe")
}
if industrialtest.mclAvailable then
	definition.inactiveDigSpeed=1
	definition.digLevel=2
	definition.activeDigSpeed=7
end
registerElectricHoe(definition)
minetest.register_craft({
	type="shaped",
	output="industrialtest:electric_hoe",
	recipe={
		{"industrialtest:refined_iron_ingot","industrialtest:refined_iron_ingot"},
		{"","industrialtest:electronic_circuit"},
		{"","industrialtest:re_battery"}
	}
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:electric_hoe",
	recipe={
		{"industrialtest:refined_iron_ingot","industrialtest:refined_iron_ingot"},
		{"industrialtest:electronic_circuit",""},
		{"industrialtest:re_battery",""}
	}
})
if industrialtest.mclAvailable then
	registerElectricHoe({
		name="diamond_electric_hoe",
		displayName=S("Diamond Electric Hoe"),
		inactiveDigSpeed=1,
		digLevel=5,
		activeDigSpeed=9
	})
	minetest.register_craft({
		type="shapeless",
		output="industrialtest:diamond_electric_hoe",
		recipe={
			"industrialtest:electric_hoe",
			industrialtest.elementKeys.diamond,
			industrialtest.elementKeys.diamond
		}
	})
end
