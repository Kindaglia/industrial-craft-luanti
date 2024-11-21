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
local powerStorage={}

powerStorage.getFormspec=function(pos)
	local meta=minetest.get_meta(pos)
	local charged=meta:get_int("industrialtest.powerAmount")/meta:get_int("industrialtest.powerCapacity")
	local formspec={
		"list[context;charged;1,2.5;1,1]",
		industrialtest.internal.getItemSlotBg(1,2.5,1,1),
		"label[0.9,3.9;"..S("Charge").."]",
		"list[context;discharged;3,2.5;1,1]",
		industrialtest.internal.getItemSlotBg(3,2.5,1,1),
		"label[2.7,3.9;"..S("Discharge").."]",
		"box[9,1;0.3,4.8;#202020]",
		(charged>0 and "box[9,"..(1+4.8-(charged*4.8))..";0.3,"..(charged*4.8)..";#FF1010]" or ""),
		"listring[context;charged]",
		"listring[context;discharged]"
	}
	return table.concat(formspec,"")
end

powerStorage.onConstruct=function(pos,meta,inv)
	inv:set_size("charged",1)
	inv:set_size("discharged",1)
end

powerStorage.onTimer=function(pos,elapsed,meta,inv,config)
	local chargedSlot=inv:get_stack("charged",1)
	local dischargedSlot=inv:get_stack("discharged",1)
	local afterFlow,flowTransferred=industrialtest.api.powerFlow(pos)
	local shouldUpdateFormspec=flowTransferred
	local shouldRerunTimer=(afterFlow and meta:get_int("industrialtest.powerAmount")>0)

	if chargedSlot:get_count()>0 and meta:get_int("industrialtest.powerAmount")>0 and industrialtest.api.transferPowerToItem(meta,chargedSlot,config.flow)>0 then
		inv:set_stack("charged",1,chargedSlot)
		shouldRerunTimer=true
		shouldUpdateFormspec=true
	end
	if dischargedSlot:get_count()>0 and not industrialtest.api.isFullyCharged(meta) and industrialtest.api.transferPowerFromItem(dischargedSlot,meta,config.flow)>0 then
		inv:set_stack("discharged",1,dischargedSlot)
		shouldRerunTimer=true
		shouldUpdateFormspec=true
	end

	return shouldRerunTimer,shouldUpdateFormspec
end

powerStorage.onMetadataInventoryPut=function(pos)
	minetest.get_node_timer(pos):start(industrialtest.updateDelay)
end

powerStorage.onMetadataInventoryMove=function(pos)
	minetest.get_node_timer(pos):start(industrialtest.updateDelay)
end

local function registerPowerStorageNode(config)
	industrialtest.internal.registerMachine({
		name=config.name,
		displayName=config.displayName,
		capacity=config.capacity,
		flow=config.flow,
		ioConfig="iiiioi",
		sounds=config.sounds,
		powerSlots={"charged","discharged"},
		storageSlots={"charged","discharged"},
		registerActiveVariant=false,
		groups={
			_industrialtest_hasPowerOutput=1,
			_industrialtest_hasPowerInput=1
		},
		customKeys={
			tiles={
				config.machineBlockTexture,
				config.machineBlockTexture,
				config.machineBlockTexture,
				config.machineBlockTexture,
				config.machineBlockTexture,
				config.machineBlockTexture.."^industrialtest_"..config.name.."_front.png"
			},
			paramtype2="facedir",
			legacy_facedir_simple=true
		},
		requiresWrench=config.requiresWrench,
		getFormspec=powerStorage.getFormspec,
		onConstruct=powerStorage.onConstruct,
		onTimer=function(pos,elapsed,meta,inv)
			return powerStorage.onTimer(pos,elapsed,meta,inv,config)
		end,
		onMetadataInventoryPut=powerStorage.onMetadataInventoryPut,
		onMetadataInventoryMove=powerStorage.onMetadataInventoryMove
	})
end

registerPowerStorageNode({
	name="batbox",
	displayName=S("BatBox"),
	capacity=25000,
	flow=industrialtest.api.lvPowerFlow,
	sounds="wood",
	machineBlockTexture="industrialtest_wood_machine_block.png",
	requiresWrench=false
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:batbox",
	recipe={
		{"group:wood","industrialtest:insulated_tin_cable","group:wood"},
		{"industrialtest:re_battery","industrialtest:re_battery","industrialtest:re_battery"},
		{"group:wood","group:wood","group:wood"}
	}
})

registerPowerStorageNode({
	name="cesu",
	displayName=S("CESU"),
	capacity=400000,
	flow=industrialtest.api.mvPowerFlow,
	sounds="metal",
	machineBlockTexture="industrialtest_bronze_machine_block.png",
	requiresWrench=false
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:cesu",
	recipe={
		{"industrialtest:bronze_plate","industrialtest:insulated_copper_cable","industrialtest:bronze_plate"},
		{"industrialtest:advanced_re_battery","industrialtest:advanced_re_battery","industrialtest:advanced_re_battery"},
		{"industrialtest:bronze_plate","industrialtest:bronze_plate","industrialtest:bronze_plate"}
	}
})

registerPowerStorageNode({
	name="mfe",
	displayName=S("MFE"),
	capacity=3000000,
	flow=industrialtest.api.hvPowerFlow,
	sounds="metal",
	machineBlockTexture="industrialtest_machine_block.png",
	requiresWrench=true
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:mfe",
	recipe={
		{"industrialtest:insulated_gold_cable","industrialtest:energy_crystal","industrialtest:insulated_gold_cable"},
		{"industrialtest:energy_crystal","industrialtest:machine_block","industrialtest:energy_crystal"},
		{"industrialtest:insulated_gold_cable","industrialtest:energy_crystal","industrialtest:insulated_gold_cable"}
	}
})

registerPowerStorageNode({
	name="mfsu",
	displayName=S("MFSU"),
	capacity=30000000,
	flow=industrialtest.api.evPowerFlow,
	sounds="metal",
	machineBlockTexture="industrialtest_advanced_machine_block.png",
	requiresWrench=false
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:mfsu",
	recipe={
		{"industrialtest:lapotron_crystal","industrialtest:advanced_electronic_circuit","industrialtest:lapotron_crystal"},
		{"industrialtest:lapotron_crystal","industrialtest:mfe","industrialtest:lapotron_crystal"},
		{"industrialtest:lapotron_crystal","industrialtest:advanced_machine_block","industrialtest:lapotron_crystal"}
	}
})
