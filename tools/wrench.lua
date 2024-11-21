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

local S=minetest.get_translator("industrialtest")

local function onWrenchUse(user,pointed)
	local node=minetest.get_node_or_nil(pointed.under)
	if not node then
		return false
	end
	local def=minetest.registered_nodes[node.name]
	if not def or not def.groups or not def.groups._industrialtest_wrenchUnmountable or (def.can_dig and not def.can_dig(pointed.under)) then
		return false
	end
	local inv=user:get_inventory()
	if def.after_dig_node then
		def.after_dig_node(pointed.under,node,minetest.get_meta(pointed.under):to_table())
	end
	minetest.remove_node(pointed.under)
	local name=node.name
	if string.sub(name,-7)=="_active" then
		name=string.sub(name,1,-8)
	end
	inv:add_item("main",ItemStack(name))
	return true
end

local definition={
	description=S("Wrench"),
	inventory_image="industrialtest_wrench.png",
	tool_capabilities={
		full_punch_interval=1,
		uses=200
	},
	on_use=function(itemstack,user,pointed)
		if pointed.type=="node" and user and user:is_player() and onWrenchUse(user,pointed) then
			industrialtest.api.afterToolUse(itemstack)
			return itemstack
		end
		return nil
	end,
	_industrialtest_tool=true
}
if industrialtest.mclAvailable then
	definition.groups={
		tool=1
	}
	definition._mcl_toollike_wield=true
end
minetest.register_tool("industrialtest:wrench",definition)
minetest.register_craft({
	type="shaped",
	output="industrialtest:wrench",
	recipe={
		{industrialtest.elementKeys.bronzeIngot,"",industrialtest.elementKeys.bronzeIngot},
		{industrialtest.elementKeys.bronzeIngot,industrialtest.elementKeys.bronzeIngot,industrialtest.elementKeys.bronzeIngot},
		{"",industrialtest.elementKeys.bronzeIngot,""}
	}
})

definition={
	description=S("Electric Wrench"),
	inventory_image="industrialtest_electric_wrench.png",
	on_use=function(itemstack,user,pointed)
		local meta=itemstack:get_meta()
		if meta:get_int("industrialtest.powerAmount")>=20 and user and user:is_player() and onWrenchUse(user,pointed) then
			industrialtest.api.addPowerToItem(itemstack,-20)
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
minetest.register_tool("industrialtest:electric_wrench",definition)
minetest.register_craft({
	type="shapeless",
	output="industrialtest:electric_wrench",
	recipe={
		"industrialtest:wrench",
		"industrialtest:electronic_circuit",
		"industrialtest:re_battery"
	}
})
