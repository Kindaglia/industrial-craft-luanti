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

local inductionFurnace={}
inductionFurnace.opPower=60
inductionFurnace.efficiency=0.5

local function calculateMaxSrcTime(pos)
	local meta=minetest.get_meta(pos)
	local inv=meta:get_inventory()
	local srcList=inv:get_list("src")

	local maxSrcTime=0
	for _,slot in ipairs(srcList) do
		local result,_=minetest.get_craft_result({
			method="cooking",
			width=1,
			items={slot}
		})
		maxSrcTime=math.max(maxSrcTime,result.time*inductionFurnace.efficiency)
	end
	meta:set_float("maxSrcTime",maxSrcTime)
end

inductionFurnace.getFormspec=function(pos)
	local meta=minetest.get_meta(pos)
	local powerPercent=meta:get_int("industrialtest.powerAmount")/meta:get_int("industrialtest.powerCapacity")*100
	local maxSrcTime=meta:get_float("maxSrcTime")
	local srcPercent=maxSrcTime>0 and meta:get_float("srcTime")/maxSrcTime*100 or 0
	local heat=meta:get_int("heat")
	local formspec={
		"list[context;src;3.7,1.8;2,1]",
		industrialtest.internal.getItemSlotBg(3.7,1.8,2,1),
		(powerPercent>0 and "image[3.7,2.8;1,1;industrialtest_gui_electricity_bg.png^[lowpart:"..powerPercent..":industrialtest_gui_electricity_fg.png]"
		 or "image[3.7,2.8;1,1;industrialtest_gui_electricity_bg.png]"),
		"list[context;powerStorage;3.7,3.9;1,1]",
		industrialtest.internal.getItemSlotBg(3.7,3.9,1,1),
		(srcPercent>0 and "image[4.9,2.8;1,1;gui_furnace_arrow_bg.png^[lowpart:"..srcPercent..":gui_furnace_arrow_fg.png^[transformR270]"
		 or "image[4.9,2.8;1,1;gui_furnace_arrow_bg.png^[transformR270]"),
		"list[context;dst;6,2.8;2,1;]",
		industrialtest.internal.getItemSlotBg(6,2.8,2,1),
		"list[context;upgrades;9,0.9;1,4]",
		industrialtest.internal.getItemSlotBg(9,0.9,1,4),
		"label[0.5,2.8;"..minetest.formspec_escape(S("Heat: @1 %",heat)).."]",
		"listring[context;src]",
		"listring[context;dst]"
    }
	return table.concat(formspec,"")
end

inductionFurnace.onConstruct=function(pos,meta,inv)
	inv:set_size("src",2)
	inv:set_size("dst",2)
	inv:set_size("powerStorage",1)
	inv:set_size("upgrades",4)
	meta:set_int("heat",0)
	meta:set_float("srcTime",0)
end

inductionFurnace.onTimer=function(pos,elapsed,meta,inv)
	local shouldRerunTimer=false
	local shouldUpdateFormspec=false
	local srcList=inv:get_list("src")
	local heat=meta:get_int("heat")

	shouldRerunTimer,shouldUpdateFormspec=industrialtest.internal.chargeFromPowerStorageItem(meta,inv)

	if heat>0 then
		meta:set_int("heat",math.max(heat-math.max(2*elapsed,1),0))
		shouldRerunTimer=shouldRerunTimer or heat>0
		shouldUpdateFormspec=true
	end

	for _,slot in ipairs(srcList) do
		if not slot:is_empty() then
			local result,after=minetest.get_craft_result({
				method="cooking",
				width=1,
				items={slot}
			})
			if result.time>0 and inv:room_for_item("dst",result.item) then
				minetest.swap_node(pos,{
					name="industrialtest:induction_furnace_active",
					param2=minetest.get_node(pos).param2
				})
				minetest.get_node_timer(pos):start(industrialtest.updateDelay)
				return false,shouldUpdateFormspec
			end
		end
	end

	return shouldRerunTimer,shouldUpdateFormspec
end

inductionFurnace.allowMetadataInventoryMove=function(pos,fromList,fromIndex,toList,toIndex,count)
	if toList=="dst" then
		return 0
	end
	return count
end

inductionFurnace.allowMetadataInventoryPut=function(pos,listname,index,stack)
	if listname=="dst" then
		return 0
	end
	return stack:get_count()
end

inductionFurnace.onMetadataInventoryPut=function(pos,listname)
	if listname=="src" then
		calculateMaxSrcTime(pos)
	end
	minetest.get_node_timer(pos):start(industrialtest.updateDelay)
end

inductionFurnace.onMetadataInventoryMove=function(pos,fromList,fromIndex,toList)
	if fromList=="src" or toList=="src" then
		calculateMaxSrcTime(pos)
	end
	minetest.get_node_timer(pos):start(industrialtest.updateDelay)
end

inductionFurnace.onMetadataInventoryTake=function(pos,listname)
	if listname=="src" then
		calculateMaxSrcTime(pos)
	end
	if listname=="dst" then
		minetest.get_node_timer(pos):start(industrialtest.updateDelay)
	end
end

inductionFurnace.activeOnTimer=function(pos,elapsed,meta,inv)
	local srcList=inv:get_list("src")
	local powerAmount=meta:get_int("industrialtest.powerAmount")
	local srcTime=meta:get_float("srcTime")
	local maxSrcTime=meta:get_float("maxSrcTime")
	local heat=meta:get_int("heat")
	local speed=industrialtest.api.getMachineSpeed(meta)
	local requiredPower=elapsed*inductionFurnace.opPower*speed

	industrialtest.internal.chargeFromPowerStorageItem(meta,inv)

	local shouldContinue=false
	local results={}
	for _,slot in ipairs(srcList) do
		if slot:is_empty() then
			table.insert(results,false)
		else
			local result,after=minetest.get_craft_result({
				method="cooking",
				width=1,
				items={slot}
			})
			if result.time>0 and inv:room_for_item("dst",result.item) then
				table.insert(results,result.item)
				shouldContinue=true
			else
				table.insert(results,false)
			end
		end
	end
	if not shouldContinue or powerAmount<requiredPower then
		meta:set_float("srcTime",0)
		minetest.swap_node(pos,{
			name="industrialtest:induction_furnace",
			param2=minetest.get_node(pos).param2
		})
		minetest.get_node_timer(pos):start(industrialtest.updateDelay)
		return false,true
	end

	srcTime=srcTime+elapsed*(1+heat/100)
	if srcTime>=maxSrcTime then
		for i,result in ipairs(results) do
			if result then
				local multiplier=math.min(srcList[i]:get_count(),speed)
				local prevCount=result:get_count()
				result:set_count(result:get_count()*multiplier)
				local leftover=inv:add_item("dst",result)
				srcList[i]:take_item(multiplier-leftover:get_count()/prevCount)
				inv:set_stack("src",i,srcList[i])
			end
		end
		srcTime=0
	end
	meta:set_float("srcTime",srcTime)

	if heat<100 then
		meta:set_int("heat",math.min(100,heat+speed))
	end

	industrialtest.api.addPower(meta,-requiredPower)

	return true,true
end

industrialtest.internal.registerMachine({
	name="induction_furnace",
	displayName=S("Induction Furnace"),
	capacity=industrialtest.api.mvPowerFlow*2,
	getFormspec=inductionFurnace.getFormspec,
	flow=industrialtest.api.mvPowerFlow,
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
			"industrialtest_advanced_machine_block.png",
			"industrialtest_advanced_machine_block.png",
			"industrialtest_advanced_machine_block.png",
			"industrialtest_advanced_machine_block.png",
			"industrialtest_advanced_machine_block.png",
			"industrialtest_advanced_machine_block.png^industrialtest_electric_furnace_front.png"
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
			"industrialtest_advanced_machine_block.png^industrialtest_electric_furnace_front_active.png"
		}
	},
	onConstruct=inductionFurnace.onConstruct,
	onTimer=inductionFurnace.onTimer,
	allowMetadataInventoryMove=inductionFurnace.allowMetadataInventoryMove,
	allowMetadataInventoryPut=inductionFurnace.allowMetadataInventoryPut,
	onMetadataInventoryPut=inductionFurnace.onMetadataInventoryPut,
	onMetadataInventoryMove=inductionFurnace.onMetadataInventoryMove,
	onMetadataInventoryTake=inductionFurnace.onMetadataInventoryTake,
	activeOnTimer=inductionFurnace.activeOnTimer
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:induction_furnace",
	recipe={
		{industrialtest.elementKeys.copperIngot,industrialtest.elementKeys.copperIngot,industrialtest.elementKeys.copperIngot},
		{industrialtest.elementKeys.copperIngot,"industrialtest:electric_furnace",industrialtest.elementKeys.copperIngot},
		{industrialtest.elementKeys.copperIngot,"industrialtest:advanced_machine_block",industrialtest.elementKeys.copperIngot}
	}
})
