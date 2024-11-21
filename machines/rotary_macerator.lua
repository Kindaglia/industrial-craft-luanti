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

local rotaryMacerator={}
rotaryMacerator.opPower=60
rotaryMacerator.maintainSpeedOpPower=10

rotaryMacerator.getFormspec=function(pos)
	local meta=minetest.get_meta(pos)
	local powerPercent=meta:get_int("industrialtest.powerAmount")/meta:get_int("industrialtest.powerCapacity")*100
	local maxSrcTime=meta:get_float("maxSrcTime")
	local srcPercent=maxSrcTime>0 and meta:get_float("srcTime")/maxSrcTime*100 or 0
	local rpm=meta:get_int("rpm")
	local buttonMaintainSpeedText=meta:get_int("maintainSpeed")==1 and S("Don't maintain speed") or S("Maintain speed")
	local formspec={
		"list[context;src;3.8,1.8;1,1]",
		industrialtest.internal.getItemSlotBg(3.8,1.8,1,1),
		"list[context;modifier;4.9,1.8;1,1]",
		industrialtest.internal.getItemSlotBg(4.9,1.8,1,1),
		(powerPercent>0 and "image[3.8,2.8;1,1;industrialtest_gui_electricity_bg.png^[lowpart:"..powerPercent..":industrialtest_gui_electricity_fg.png]"
		 or "image[3.8,2.8;1,1;industrialtest_gui_electricity_bg.png]"),
		"list[context;powerStorage;3.8,3.9;1,1]",
		industrialtest.internal.getItemSlotBg(3.8,3.9,1,1),
		(srcPercent>0 and "image[4.9,2.8;1,1;gui_furnace_arrow_bg.png^[lowpart:"..srcPercent..":gui_furnace_arrow_fg.png^[transformR270]"
		 or "image[4.9,2.8;1,1;gui_furnace_arrow_bg.png^[transformR270]"),
		"list[context;dst;6,2.8;1,1;]",
		industrialtest.internal.getItemSlotBg(6,2.8,1,1),
		"list[context;upgrades;9,0.9;1,4]",
		industrialtest.internal.getItemSlotBg(9,0.9,1,4),
		"label[0.5,2.8;"..minetest.formspec_escape(S("Speed: @1",rpm)).."]",
		"button[0.5,3.4;3,0.8;maintainSpeed;"..minetest.formspec_escape(buttonMaintainSpeedText).."]",
		"listring[context;src]",
		"listring[context;dst]"
	}
	return table.concat(formspec,"")
end

rotaryMacerator.onConstruct=function(pos,meta,inv)
	inv:set_size("src",1)
	inv:set_size("modifier",1)
	inv:set_size("powerStorage",1)
	inv:set_size("dst",1)
	inv:set_size("upgrades",4)
	meta:set_int("rpm",0)
	meta:set_float("srcTime",0)
	meta:set_float("maxSrcTime",0)
	meta:set_int("maintainSpeed",0)
end

rotaryMacerator.onTimer=function(pos,elapsed,meta,inv)
	local shouldRerunTimer=false
	local shouldUpdateFormspec=false
	local srcSlot=inv:get_stack("src",1)
	local modifierSlot=inv:get_stack("modifier",1)
	local dstSlot=inv:get_stack("dst",1)
	local rpm=meta:get_int("rpm")
	local maintainSpeed=meta:get_int("maintainSpeed")

	shouldRerunTimer,shouldUpdateFormspec=industrialtest.internal.chargeFromPowerStorageItem(meta,inv)
	local powerAmount=meta:get_int("industrialtest.powerAmount")

	if maintainSpeed==1 and powerAmount>=rotaryMacerator.maintainSpeedOpPower then
		local newRpm=math.max(rpm+10*elapsed,0)
		if newRpm>rpm then
			meta:set_int("rpm",newRpm)
			shouldUpdateFormspec=true
		end
		industrialtest.api.addPower(meta,-rotaryMacerator.maintainSpeedOpPower)
		shouldRerunTimer=true
	elseif rpm>0 then
		meta:set_int("rpm",math.max(rpm-1000*elapsed,0))
		shouldRerunTimer=shouldRerunTimer or rpm>0
		shouldUpdateFormspec=true
	end

	if powerAmount>=rotaryMacerator.opPower and not srcSlot:is_empty() then
		local result=industrialtest.api.getMaceratorRecipeResult(srcSlot:get_name())
		if result then
			meta:set_float("srcTime",0)
			meta:set_float("maxSrcTime",result.time)
			minetest.swap_node(pos,{
				name="industrialtest:rotary_macerator_active",
				param2=minetest.get_node(pos).param2
			})
			minetest.get_node_timer(pos):start(industrialtest.updateDelay)
			return false,shouldUpdateFormspec
		end
	end
	
	return shouldRerunTimer,shouldUpdateFormspec
end

rotaryMacerator.allowMetadataInventoryMove=function(pos,fromList,fromIndex,toList,count)
	if toList=="dst" then
		return 0
	end
	return count
end

rotaryMacerator.allowMetadataInventoryPut=function(pos,listname,index,stack)
	if listname=="dst" then
		return 0
	end
	return stack:get_count()
end

rotaryMacerator.onMetadataInventoryMove=function(pos)
	minetest.get_node_timer(pos):start(industrialtest.updateDelay)
end

rotaryMacerator.onMetadataInventoryPut=function(pos)
	minetest.get_node_timer(pos):start(industrialtest.updateDelay)
end

rotaryMacerator.onMetadataInventoryTake=function(pos,listname)
	if listname=="dst" then
		minetest.get_node_timer(pos):start(industrialtest.updateDelay)
	end
end

rotaryMacerator.activeOnTimer=function(pos,elapsed,meta,inv)
	local srcSlot=inv:get_stack("src",1)
	local modifierSlot=inv:get_stack("modifier",1)
	local dstSlot=inv:get_stack("dst",1)
	local powerAmount=meta:get_int("industrialtest.powerAmount")
	local rpm=meta:get_int("rpm")
	local speed=industrialtest.api.getMachineSpeed(meta)
	local requiredPower=elapsed*rotaryMacerator.opPower*speed

	industrialtest.internal.chargeFromPowerStorageItem(meta,inv)

	if srcSlot:is_empty() or powerAmount<requiredPower then
		meta:set_float("srcTime",0)
		meta:set_float("maxSrcTime",0)
		minetest.swap_node(pos,{
			name="industrialtest:rotary_macerator",
			param2=minetest.get_node(pos).param2
		})
		minetest.get_node_timer(pos):start(industrialtest.updateDelay)
		return false,true
	end

	local result
	local modified=false
	if not modifierSlot:is_empty() then
		result=industrialtest.api.getRotaryMaceratorModifier(srcSlot:get_name(),modifierSlot:get_name())
	end
	if result then
		modified=true
	else
		result=industrialtest.api.getMaceratorRecipeResult(srcSlot:get_name())
	end
	local resultStack=ItemStack(result.output)
	if not dstSlot:item_fits(resultStack) then
		meta:set_float("srcTime",0)
		meta:set_float("maxSrcTime",0)
		minetest.swap_node(pos,{
			name="industrialtest:rotary_macerator",
			param2=minetest.get_node(pos).param2
		})
		minetest.get_node_timer(pos):start(industrialtest.updateDelay)
		return false,true
	end
	meta:set_float("maxSrcTime",result.time)

	local srcTime=meta:get_float("srcTime")+elapsed*(1+rpm/7500)
	if srcTime>=meta:get_float("maxSrcTime") then
		local multiplier=math.min(srcSlot:get_count(),speed)
		local prevCount=resultStack:get_count()
		resultStack:set_count(resultStack:get_count()*multiplier)
		local leftover=inv:add_item("dst",resultStack)
		meta:set_float("srcTime",0)
		meta:set_float("maxSrcTime",0)
		srcSlot:take_item(multiplier-leftover:get_count()/prevCount)
		inv:set_stack("src",1,srcSlot)
		meta:set_int("rpm",math.min(rpm+750*elapsed,7500))
		if modified then
			local modifierMeta=modifierSlot:get_meta()
			local uses=result.uses
			if modifierMeta:contains("uses") then
				uses=modifierMeta:get_int("uses")
			end
			uses=math.max(uses-1,0)
			if uses==0 then
				if result.modifierLeftover then
					modifierSlot:set_name(result.modifierLeftover)
				else
					modifierSlot:take_item(1)
				end
				uses=result.uses
			end
			if not modifierSlot:is_empty() and not result.modifierLeftover then
				modifierMeta:set_int("uses",uses)
			end
			inv:set_stack("modifier",1,modifierSlot)
		end
	else
		meta:set_float("srcTime",srcTime)
	end

	industrialtest.api.addPower(meta,-requiredPower)

	return true,true
end

industrialtest.internal.registerMachine({
	name="rotary_macerator",
	displayName=S("Rotary Macerator"),
	capacity=industrialtest.api.lvPowerFlow*2,
	getFormspec=rotaryMacerator.getFormspec,
	flow=industrialtest.api.lvPowerFlow,
	ioConfig="iiiiii",
	requiresWrench=true,
	registerActiveVariant=true,
	sounds="metal",
	powerSlots={"powerStorage"},
	storageSlots={"src","modifier","powerStorage","dst","upgrades"},
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
			"industrialtest_advanced_machine_block.png^industrialtest_macerator_front.png"
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
			"industrialtest_advanced_machine_block.png^industrialtest_macerator_front_active.png"
		}
	},
	onConstruct=rotaryMacerator.onConstruct,
	onTimer=rotaryMacerator.onTimer,
	allowMetadataInventoryMove=rotaryMacerator.allowMetadataInventoryMove,
	allowMetadataInventoryPut=rotaryMacerator.allowMetadataInventoryPut,
	onMetadataInventoryPut=rotaryMacerator.onMetadataInventoryPut,
	onMetadataInventoryMove=rotaryMacerator.onMetadataInventoryMove,
	onMetadataInventoryTake=rotaryMacerator.onMetadataInventoryTake,
	activeOnTimer=rotaryMacerator.activeOnTimer
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:rotary_macerator",
	recipe={
		{"industrialtest:refined_iron_ingot","industrialtest:refined_iron_ingot","industrialtest:refined_iron_ingot"},
		{"industrialtest:refined_iron_ingot","industrialtest:macerator","industrialtest:refined_iron_ingot"},
		{"industrialtest:refined_iron_ingot","industrialtest:advanced_machine_block","industrialtest:refined_iron_ingot"}
	}
})
