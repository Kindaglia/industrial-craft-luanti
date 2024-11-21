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
local toolWorkshop={}

toolWorkshop.getFormspec=function(pos)
	local meta=minetest.get_meta(pos)
	local powerPercent=meta:get_int("industrialtest.powerAmount")/meta:get_int("industrialtest.powerCapacity")*100
	local formspec={
		"list[context;powerStorage;3.7,3.7;1,1;0]",
		industrialtest.internal.getItemSlotBg(3.7,3.7,1,1),
		(powerPercent>0 and "image[3.7,2.5;1,1;industrialtest_gui_electricity_bg.png^[lowpart:"..powerPercent..":industrialtest_gui_electricity_fg.png]"
		 or "image[3.7,2.5;1,1;industrialtest_gui_electricity_bg.png]"),
		"list[context;src;5.9,3.2;1,1;0]",
		industrialtest.internal.getItemSlotBg(5.9,3.2,1,1),
		"list[context;upgrades;9,0.9;1,4]",
		industrialtest.internal.getItemSlotBg(9,0.9,1,4),
		"listring[context;src]"
	}
	return table.concat(formspec,"")
end

toolWorkshop.onConstruct=function(pos,meta,inv)
	inv:set_size("powerStorage",1)
	inv:set_size("src",1)
	inv:set_size("upgrades",4)
end

toolWorkshop.onTimer=function(pos,elapsed,meta,inv)
	local powerStorageSlot=inv:get_stack("powerStorage",1)
	local toolSlot=inv:get_stack("src",1)
	local requiredPower=industrialtest.api.getMachineSpeed(meta)*10000
	local shouldRerunTimer=false
	local shouldUpdateFormspec=false

	if powerStorageSlot:get_count()>0 then
		local stackMeta=powerStorageSlot:get_meta()
		if industrialtest.api.transferPower(stackMeta,meta,stackMeta:get_int("industrialtest.powerFlow"))>0 then
			shouldUpdateFormspec=true
			shouldRerunTimer=true
			industrialtest.api.updateItemPowerText(powerStorageSlot)
			inv:set_stack("powerStorage",1,powerStorageSlot)
		end
	end

	if toolSlot:get_count()>0 and toolSlot:get_wear()>0 and meta:get_int("industrialtest.powerAmount")>=requiredPower then
		minetest.swap_node(pos,{
			name="industrialtest:tool_workshop_active",
			param2=minetest.get_node(pos).param2
		})
		minetest.get_node_timer(pos):start(industrialtest.updateDelay)
	end

	return shouldRerunTimer,shouldUpdateFormspec
end

toolWorkshop.activeOnTimer=function(pos,elapsed,meta,inv)
	local powerStorageSlot=inv:get_stack("powerStorage",1)
	local toolSlot=inv:get_stack("src",1)
	local speed=industrialtest.api.getMachineSpeed(meta)
	local requiredPower=speed*10000
	local shouldRerunTimer=false
	local shouldUpdateFormspec=false

	if powerStorageSlot:get_count()>0 then
		local stackMeta=powerStorageSlot:get_meta()
		if industrialtest.api.transferPower(stackMeta,meta,stackMeta:get_int("industrialtest.powerFlow"))>0 then
			shouldUpdateFormspec=true
			shouldRerunTimer=true
			industrialtest.api.updateItemPowerText(powerStorageSlot)
			inv:set_stack("powerStorage",1,powerStorageSlot)
		end
	end

	if toolSlot:get_count()>0 and toolSlot:get_wear()>0 and meta:get_int("industrialtest.powerAmount")>=requiredPower then
		local removed=math.min(toolSlot:get_wear(),speed*200)
		toolSlot:set_wear(toolSlot:get_wear()-removed)
		inv:set_stack("src",1,toolSlot)
		industrialtest.api.addPower(meta,-requiredPower)
		shouldRerunTimer=true
		shouldUpdateFormspec=true
	else
		minetest.swap_node(pos,{
			name="industrialtest:tool_workshop",
			param2=minetest.get_node(pos).param2
		})
	end

	return shouldRerunTimer,shouldUpdateFormspec
end

local function isTool(stack)
	local def=minetest.registered_tools[stack:get_name()]
	if not def or industrialtest.api.hasPowerStorage(stack:get_meta())then
		return false
	end
	return def.groups and (def.groups.pickaxe or def.groups.sword or def.groups.hoe or def.groups.tool or def.groups.weapon or def.groups.shovel or def.groups.axe)
end

toolWorkshop.allowMetadataInventoryMove=function(pos,fromList,fromIndex,toList,toIndex,count)
	if toList=="src" then
		local meta=minetest.get_meta(pos)
		local inv=meta:get_inventory()
		local movedItemStack=inv:get_stack(fromList,fromIndex)
		if not isTool(movedItemStack) then
			return 0
		end
	end
	return count
end

toolWorkshop.allowMetadataInventoryPut=function(pos,listname,index,stack)
	if listname=="tool" and not isTool(stack) then
		return 0
	end
	return stack:get_count()
end

toolWorkshop.metadataChange=function(pos)
	minetest.get_node_timer(pos):start(industrialtest.updateDelay)
end

industrialtest.internal.registerMachine({
	name="tool_workshop",
	displayName=S("Tool Workshop"),
	getFormspec=toolWorkshop.getFormspec,
	capacity=20000,
	flow=industrialtest.api.hvPowerFlow,
	ioConfig="iiiiii",
	requiresWrench=true,
	registerActiveVariant=true,
	powerSlots={"powerStorage"},
	storageSlots={"src"},
	sounds="metal",
	groups={
		_industrialtest_hasPowerInput=1
	},
	customKeys={
		tiles={
			"industrialtest_advanced_machine_block.png",
			"industrialtest_advanced_machine_block.png",
			"industrialtest_advanced_machine_block.png",
			"industrialtest_advanced_machine_block.png",
			"industrialtest_advanced_machine_block.png",
			"industrialtest_advanced_machine_block.png^industrialtest_tool_workshop_front.png",
			"industrialtest_advanced_machine_block.png"
		},
		paramtype2="facedir",
		legacy_facedir_simple=true
	},
	activeCustomKeys={
		tiles={
			"industrialtest_advanced_machine_block.png",
			"industrialtest_advanced_machine_block.png",
			"industrialtest_advanced_machine_block.png",
			"industrialtest_advanced_machine_block.png",
			"industrialtest_advanced_machine_block.png",
			"industrialtest_advanced_machine_block.png^industrialtest_tool_workshop_front_active.png",
			"industrialtest_advanced_machine_block.png"
		},
	},
	onConstruct=toolWorkshop.onConstruct,
	onTimer=toolWorkshop.onTimer,
	activeOnTimer=toolWorkshop.activeOnTimer,
	allowMetadataInventoryMove=toolWorkshop.allowMetadataInventoryMove,
	allowMetadataInventoryPut=toolWorkshop.allowMetadataInventoryPut,
	onMetadataInventoryPut=toolWorkshop.metadataChange,
	onMetadataInventoryMove=toolWorkshop.metadataChange
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:tool_workshop",
	recipe={
		{industrialtest.elementKeys.copperIngot,industrialtest.elementKeys.ironPickaxe,industrialtest.elementKeys.copperIngot},
		{"","industrialtest:advanced_machine_block",""},
		{industrialtest.elementKeys.ironIngot,industrialtest.elementKeys.ironIngot,industrialtest.elementKeys.ironIngot}
	}
})
