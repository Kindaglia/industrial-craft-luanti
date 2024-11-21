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

if industrialtest.mods.mclRubber then
	return
end

local S=minetest.get_translator("industrialtest")

local function onTreetapUse(user,pointed)
	local node=minetest.get_node_or_nil(pointed.under)
	if not node then
		return false
	end
	-- Note: if more nodes from which treetap can extract will be added then they shouldn't be added here
	-- Instead they should have additional entry in definition which will denote that treetap can be used on them
	if node.name=="industrialtest:rubber_wood_with_rubber" then
		local inv=user:get_inventory()
		inv:add_item("main",ItemStack("industrialtest:sticky_resin"))
		minetest.set_node(pointed.under,{name="industrialtest:rubber_wood"})
		return true
	end
	return false
end

local definition={	
	description=S("Treetap"),
	inventory_image="industrialtest_treetap.png",
	tool_capabilities={
		full_punch_interval=1,
		uses=50
	},
	on_place=function(itemstack,user,pointed)
		if pointed.type=="node" and user and user:is_player() and onTreetapUse(user,pointed) then
			industrialtest.api.afterToolUse(itemstack)
			return itemstack
		end
		return nil
	end,
	_industrialtest_tool=true
}
if industrialtest.mtgAvailable then
	definition.groups={
		flammable=2
	}
elseif industrialtest.mclAvailable then
	definition.groups={
		tool=1
	}
	definition._repair_material="group:wood"
	definition._mcl_toollike_wield=true
end
minetest.register_tool("industrialtest:treetap",definition)
minetest.register_craft({
	type="shaped",
	output="industrialtest:treetap",
	recipe={
		{"","group:wood",""},
		{"group:wood","group:wood","group:wood"},
		{"group:wood","",""}
	}
})

definition={
	description=S("Electric Treetap"),
	inventory_image="industrialtest_electric_treetap.png",
	on_place=function(itemstack,user,pointed)
		local meta=itemstack:get_meta()
		if meta:get_int("industrialtest.powerAmount")>=50 and user and user:is_player() and onTreetapUse(user,pointed) then
			industrialtest.api.addPowerToItem(itemstack,-50)
			return itemstack
		end
		return nil
	end,
	_industrialtest_powerStorage=true,
	_industrialtest_powerCapacity=10000,
	_industrialtest_powerFlow=industrialtest.api.lvPowerFlow
}
if industrialtest.mclAvailable then
	definition.groups={
		tool=1
	}
	definition._mcl_toollike_wield=true
end
minetest.register_tool("industrialtest:electric_treetap",definition)
minetest.register_craft({
	type="shapeless",
	output="industrialtest:electric_treetap",
	recipe={
		"industrialtest:treetap",
		"industrialtest:electronic_circuit",
		"industrialtest:re_battery"
	}
})
