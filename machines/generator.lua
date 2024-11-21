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
local generator={}

generator.getFormspec=function(pos)
	local meta=minetest.get_meta(pos)
	local fuelPercent=meta:get_int("fuelTime")/meta:get_int("maxFuelTime")*100
	local charged=meta:get_int("industrialtest.powerAmount")/meta:get_int("industrialtest.powerCapacity")
	local formspec={
		"list[context;charged;4.7,1.8;1,1]",
		industrialtest.internal.getItemSlotBg(4.7,1.8,1,1),
		(fuelPercent>0 and "image[4.7,2.8;1,1;default_furnace_fire_bg.png^[lowpart:"..fuelPercent..":default_furnace_fire_fg.png]"
		 or "image[4.7,2.8;1,1;default_furnace_fire_bg.png]"),
		"list[context;src;4.7,3.9;1,1]",
		industrialtest.internal.getItemSlotBg(4.7,3.9,1,1),
		"box[9,1;0.3,4.8;#202020]",
		(charged>0 and "box[9,"..(1+4.8-(charged*4.8))..";0.3,"..(charged*4.8)..";#FF1010]" or ""),
		"listring[context;src]"
	}
	return table.concat(formspec,"")
end

generator.onConstruct=function(pos,meta,inv)
	inv:set_size("charged",1)
	inv:set_size("src",1)
	meta:set_int("fuelTime",0)
	meta:set_int("maxFuelTime",1)
end

generator.onTimer=function(pos,elapsed,meta,inv)
	local powerFlow=meta:get_int("industrialtest.powerFlow")
	local chargedSlot=inv:get_stack("charged",1)
	local fuelSlot=inv:get_stack("src",1)
	local afterFlow,flowTransferred=industrialtest.api.powerFlow(pos)
	local shouldUpdateFormspec=flowTransferred
	local shouldRerunTimer=(afterFlow and meta:get_int("industrialtest.powerAmount")>0)
	if chargedSlot:get_count()>0 and not industrialtest.api.isFullyCharged(chargedSlot:get_meta()) and meta:get_int("industrialtest.powerAmount")>0 then
		industrialtest.api.transferPowerToItem(meta,chargedSlot,powerFlow)
		inv:set_stack("charged",1,chargedSlot)
		shouldUpdateFormspec=true
		shouldRerunTimer=true
	end
	if fuelSlot:get_count()>0 and meta:get_int("fuelTime")<=0 and not industrialtest.api.isFullyCharged(meta) then
		local output,after=minetest.get_craft_result({
			method="fuel",
			width=1,
			items={fuelSlot}
		})
		if output.time>0 then
			meta:set_int("fuelTime",output.time)
			meta:set_int("maxFuelTime",output.time)
			inv:set_stack("src",1,after.items[1])
			minetest.swap_node(pos,{
				name="industrialtest:generator_active",
				param2=minetest.get_node(pos).param2
			})
			minetest.get_node_timer(pos):start(industrialtest.updateDelay)
		end
	end
	return shouldRerunTimer,shouldUpdateFormspec
end

generator.activeOnTimer=function(pos,elapsed,meta,inv)
	local chargedSlot=inv:get_stack("charged",1)
	local fuelSlot=inv:get_stack("src",1)
	local afterFlow,flowTransferred=industrialtest.api.powerFlow(pos)
	local shouldUpdateFormspec=flowTransferred
	local shouldRerunTimer=(afterFlow and meta:get_int("industrialtest.powerAmount")>0)
	if chargedSlot:get_count()>0 and not industrialtest.api.isFullyCharged(chargedSlot:get_meta()) and meta:get_int("industrialtest.powerAmount")>0 then
		industrialtest.api.transferPowerToItem(meta,chargedSlot,chargedSlot:get_meta():get_int("industrialtest.powerFlow"))
		inv:set_stack("charged",1,chargedSlot)
		shouldUpdateFormspec=true
		shouldRerunTimer=true
	end
	if fuelSlot:get_count()>0 and meta:get_int("fuelTime")<=0 and not industrialtest.api.isFullyCharged(meta) then
		local output,after=minetest.get_craft_result({
			method="fuel",
			width=1,
			items={fuelSlot}
		})
		if output.time>0 then
			meta:set_int("fuelTime",output.time)
			meta:set_int("maxFuelTime",output.time)
			inv:set_stack("src",1,after.items[1])
		end
	end
	if meta:get_int("fuelTime")>0 then
		meta:set_int("fuelTime",meta:get_int("fuelTime")-elapsed)
		industrialtest.api.addPower(meta,200)
		shouldUpdateFormspec=true
		shouldRerunTimer=true
	else
		minetest.swap_node(pos,{
			name="industrialtest:generator",
			param2=minetest.get_node(pos).param2
		})
	end
	return shouldRerunTimer,shouldUpdateFormspec
end

generator.metadataChange=function(pos)
	minetest.get_node_timer(pos):start(industrialtest.updateDelay)
end

industrialtest.internal.registerMachine({
	name="generator",
	displayName=S("Generator"),
	getFormspec=generator.getFormspec,
	capacity=7000,
	flow=industrialtest.api.lvPowerFlow,
	ioConfig="oooooo",
	registerActiveVariant=true,
	powerSlots={"charged"},
	storageSlots={"charged","src"},
	sounds="metal",
	groups={
		_industrialtest_hasPowerOutput=1
	},
	customKeys={
		tiles={
			"industrialtest_machine_block.png",
			"industrialtest_machine_block.png",
			"industrialtest_machine_block.png",
			"industrialtest_machine_block.png",
			"industrialtest_machine_block.png",
			"industrialtest_machine_block.png^industrialtest_iron_furnace_front.png",
			"industrialtest_machine_block.png"
		},
		paramtype2="facedir",
		legacy_facedir_simple=true
	},
	activeCustomKeys={
		tiles={
			"industrialtest_machine_block.png",
			"industrialtest_machine_block.png",
			"industrialtest_machine_block.png",
			"industrialtest_machine_block.png",
			"industrialtest_machine_block.png",
			"industrialtest_machine_block.png^industrialtest_iron_furnace_front_active.png",
			"industrialtest_machine_block.png"
		},
		light_source=8
	},
	onConstruct=generator.onConstruct,
	onTimer=generator.onTimer,
	activeOnTimer=generator.activeOnTimer,
	onMetadataInventoryPut=generator.metadataChange,
	onMetadataInventoryMove=generator.metadataChange
})

minetest.register_craft({
	type="shaped",
	output="industrialtest:generator",
	recipe={
		{"industrialtest:re_battery"},
		{"industrialtest:machine_block"},
		{industrialtest.elementKeys.furnace}
	}
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:generator",
	recipe={
		{"","industrialtest:re_battery",""},
		{"industrialtest:refined_iron_ingot","industrialtest:refined_iron_ingot","industrialtest:refined_iron_ingot"},
		{"","industrialtest:iron_furnace",""}
	}
})

