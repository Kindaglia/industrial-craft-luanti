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
local canningMachine={}

canningMachine.opPower=200
canningMachine.canningTime=5

canningMachine.getFormspec=function(pos)
	local meta=minetest.get_meta(pos)
	local powerPercent=meta:get_int("industrialtest.powerAmount")/meta:get_int("industrialtest.powerCapacity")*100
	local srcPercent=meta:get_float("srcTime")/canningMachine.canningTime*100
	local formspec={
		"list[context;src;3.4,1.8;1,1]",
		industrialtest.internal.getItemSlotBg(3.4,1.8,1,1),
		(powerPercent>0 and "image[3.4,2.8;1,1;industrialtest_gui_electricity_bg.png^[lowpart:"..powerPercent..":industrialtest_gui_electricity_fg.png]"
		 or "image[3.4,2.8;1,1;industrialtest_gui_electricity_bg.png]"),
		"list[context;powerStorage;3.4,3.9;1,1]",
		industrialtest.internal.getItemSlotBg(3.4,3.9,1,1),
		(srcPercent>0 and "image[4.9,1.8;1,1;gui_furnace_arrow_bg.png^[lowpart:"..srcPercent..":gui_furnace_arrow_fg.png^[transformR270]"
		 or "image[4.9,1.8;1,1;gui_furnace_arrow_bg.png^[transformR270]"),
		"list[context;dst;6.4,1.8;1,1]",
		industrialtest.internal.getItemSlotBg(6.4,1.8,1,1),
		"list[context;leftover;6.4,2.8;1,1]",
		industrialtest.internal.getItemSlotBg(6.4,2.8,1,1),
		"list[context;upgrades;9,0.9;1,4]",
		industrialtest.internal.getItemSlotBg(9,0.9,1,4),
		"listring[context;src]",
		"listring[context;dst]"
	}
	return table.concat(formspec,"")
end

canningMachine.onConstruct=function(pos,meta,inv)
	inv:set_size("src",1)
	inv:set_size("dst",1)
	inv:set_size("leftover",1)
	inv:set_size("powerStorage",1)
	inv:set_size("upgrades",4)
	meta:set_float("srcTime",0)
end

canningMachine.onTimer=function(pos,elapsed,meta,inv)
	local shouldRerunTimer=false
	local shouldUpdateFormspec=false
	local fuelSlot=inv:get_stack("src",1)
	local targetSlot=inv:get_stack("dst",1)
	local leftoverSlot=inv:get_stack("leftover",1)
	local powerStorageSlot=inv:get_stack("powerStorage",1)
	local targetMeta=targetSlot:get_meta()

	shouldRerunTimer,shouldUpdateFormspec=industrialtest.internal.chargeFromPowerStorageItem(meta,inv)

	local def=fuelSlot:get_definition()
	if not fuelSlot:is_empty() and not targetSlot:is_empty() and meta:get_int("industrialtest.powerAmount")>=canningMachine.opPower and (not def._industrialtest_emptyVariant or leftoverSlot:item_fits(ItemStack(def._industrialtest_emptyVariant))) and
		(not industrialtest.api.itemHasFluidStorage(fuelSlot) or fuelSlot:get_meta():get_int("industrialtest.fluidAmount")>0) and targetMeta:get_int("industrialtest.fluidAmount")<targetMeta:get_int("industrialtest.fluidCapacity") then
		minetest.swap_node(pos,{
			name="industrialtest:canning_machine_active",
			param2=minetest.get_node(pos).param2
		})
		minetest.get_node_timer(pos):start(industrialtest.updateDelay)
		return false,shouldUpdateFormspec
	end
	
	return shouldRerunTimer,true
end

canningMachine.allowMetadataInventoryMove=function(pos,fromList,fromIndex,toList,count)
	if toList=="src" then
		local inv=minetest.get_meta(pos):get_inventory()
		local itemstack=inv:get_stack(fromList,fromIndex)
		local def=itemstack:get_definition()
		return (def.groups and def.groups._industrialtest_fuel) and count or 0
	end
	if toList=="dst" then
		local inv=minetest.get_meta(pos):get_inventory()
		local itemstack=inv:get_stack(fromList,fromIndex)
		local def=itemstack:get_definition()
		return (def.groups and def.groups._industrialtest_fueled) and count or 0
	end
	return count
end

canningMachine.allowMetadataInventoryPut=function(pos,listname,index,stack)
	if listname=="src" then
		local def=stack:get_definition()
		return (def.groups and def.groups._industrialtest_fuel) and stack:get_count() or 0
	end
	if listname=="dst" then
		local def=stack:get_definition()
		return (def.groups and def.groups._industrialtest_fueled) and stack:get_count() or 0
	end
	return stack:get_count()
end

canningMachine.allowMetadataInventoryTake=function(pos,listname,index,stack)
	local meta=minetest.get_meta(pos)
	local inv=meta:get_inventory()
	local fuelSlot=inv:get_stack("src",1)
	local targetSlot=inv:get_stack("dst",1)
	if ((listname=="src" and stack:get_count()==fuelSlot:get_count()) or (listname=="dst" and stack:get_count()==targetSlot:get_count())) and meta:get_float("srcTime")>0 then
		meta:set_float("srcTime",0)
		minetest.get_node_timer(pos):start(industrialtest.updateDelay)
	end
	return stack:get_count()
end

canningMachine.onMetadataInventoryPut=function(pos)
	minetest.get_node_timer(pos):start(industrialtest.updateDelay)
end

canningMachine.onMetadataInventoryMove=function(pos,fromList,fromIndex,toList,toIndex,count)
	local meta=minetest.get_meta(pos)
	local inv=meta:get_inventory()
	local fuelSlot=inv:get_stack("src",1)
	local targetSlot=inv:get_stack("dst",1)
	if ((fromList=="src" and count==fuelSlot:get_count()) or (fromList=="dst" and count==targetSlot:get_count())) and meta:get_float("srcTime")>0 then
		meta:set_float("srcTime",0)
		meta:set_string("formspec",canningMachine.getFormspec(pos))
	end
end

canningMachine.activeOnTimer=function(pos,elapsed,meta,inv)
	local shouldUpdateFormspec=false
	local fuelSlot=inv:get_stack("src",1)
	local targetSlot=inv:get_stack("dst",1)
	local powerStorageSlot=inv:get_stack("powerStorage",1)

	shouldRerunTimer,shouldUpdateFormspec=industrialtest.internal.chargeFromPowerStorageItem(meta,inv)

	if fuelSlot:is_empty() or targetSlot:is_empty() or meta:get_int("industrialtest.powerAmount")<canningMachine.opPower then
		if meta:get_int("industrialtest.powerAmount")>=canningMachine.opPower then
			meta:set_float("srcTime",0)
		end
		minetest.swap_node(pos,{
			name="industrialtest:canning_machine",
			param2=minetest.get_node(pos).param2
		})
		minetest.get_node_timer(pos):start(industrialtest.updateDelay)
		return false,true
	end

	local fuelMeta=fuelSlot:get_meta()
	local targetMeta=targetSlot:get_meta()
	if (industrialtest.api.itemHasFluidStorage(fuelSlot) and fuelMeta:get_int("industrialtest.fluidAmount")==0) or targetMeta:get_int("industrialtest.fluidAmount")==targetMeta:get_int("industrialtest.fluidCapacity") then
		meta:set_float("srcTime",0)
		minetest.swap_node(pos,{
			name="industrialtest:canning_machine",
			param2=minetest.get_node(pos).param2
		})
		minetest.get_node_timer(pos):start(industrialtest.updateDelay)
		return false,true
	end

	local srcTime=meta:get_float("srcTime")
	srcTime=srcTime+elapsed*industrialtest.api.getMachineSpeed(meta)
	if srcTime>=canningMachine.canningTime then
		if industrialtest.api.itemHasFluidStorage(fuelSlot) then
			industrialtest.api.transferFluidToItem(fuelSlot,targetSlot,fuelMeta:get_int("industrialtest.fluidAmount"))
			inv:set_stack("src",1,fuelSlot)
			inv:set_stack("dst",1,targetSlot)
		else
			local def=fuelSlot:get_definition()
			local leftoverSlot=inv:get_stack("leftover",1)
			if targetMeta:get_int("industrialtest.fluidCapacity")-targetMeta:get_int("industrialtest.fluidAmount")<def._industrialtest_fuelAmount or (def._industrialtest_emptyVariant and not leftoverSlot:item_fits(ItemStack(def._industrialtest_emptyVariant))) then
				minetest.swap_node(pos,{
					name="industrialtest:canning_machine",
					param2=minetest.get_node(pos).param2
				})
				minetest.get_node_timer(pos):start(industrialtest.updateDelay)
				return false,shouldUpdateFormspec
			end
			industrialtest.api.addFluidToItem(targetSlot,def._industrialtest_fuelAmount)
			inv:set_stack("dst",1,targetSlot)
			fuelSlot:take_item(1)
			inv:set_stack("src",1,fuelSlot)
			leftoverSlot:add_item(ItemStack(def._industrialtest_emptyVariant))
			inv:set_stack("leftover",1,leftoverSlot)
		end
		meta:set_float("srcTime",0)
	else
		meta:set_float("srcTime",srcTime)
	end
	industrialtest.api.addPower(meta,-canningMachine.opPower)

	return true,true
end

industrialtest.internal.registerMachine({
	name="canning_machine",
	displayName=S("Canning Machine"),
	capacity=industrialtest.api.lvPowerFlow*2,
	getFormspec=canningMachine.getFormspec,
	flow=industrialtest.api.lvPowerFlow,
	ioConfig="iiiiii",
	requiresWrench=true,
	registerActiveVariant=true,
	sounds="metal",
	powerSlots={"powerStorage"},
	storageSlots={"src","dst","powerStorage","upgrades"},
	groups={
		_industrialtest_hasPowerInput=1
	},
	customKeys={
		tiles={
			"industrialtest_machine_block.png",
			"industrialtest_machine_block.png",
			"industrialtest_machine_block.png",
			"industrialtest_machine_block.png",
			"industrialtest_machine_block.png",
			"industrialtest_machine_block.png^industrialtest_canning_machine_front.png"
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
			"industrialtest_machine_block.png^industrialtest_canning_machine_front_active.png"
		}
	},
	onConstruct=canningMachine.onConstruct,
	onTimer=canningMachine.onTimer,
	allowMetadataInventoryMove=canningMachine.allowMetadataInventoryMove,
	allowMetadataInventoryPut=canningMachine.allowMetadataInventoryPut,
	allowMetadataInventoryTake=canningMachine.allowMetadataInventoryTake,
	onMetadataInventoryPut=canningMachine.onMetadataInventoryPut,
	onMetadataInventoryMove=canningMachine.onMetadataInventoryMove,
	activeOnTimer=canningMachine.activeOnTimer
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:canning_machine",
	recipe={
		{industrialtest.elementKeys.tinIngot,"industrialtest:electronic_circuit",industrialtest.elementKeys.tinIngot},
		{industrialtest.elementKeys.tinIngot,"industrialtest:machine_block",industrialtest.elementKeys.tinIngot},
		{industrialtest.elementKeys.tinIngot,industrialtest.elementKeys.tinIngot,industrialtest.elementKeys.tinIngot}
	}
})
