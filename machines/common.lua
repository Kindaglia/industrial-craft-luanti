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

local machine={}
local simpleElectricItemProcessor={}

industrialtest.internal.simpleElectricItemProcessors={}

industrialtest.internal.mclAfterDigNode=function(pos,oldmeta,lists)
	-- Taken from https://git.minetest.land/MineClone2/MineClone2/src/branch/master/mods/ITEMS/mcl_furnaces/init.lua#L538
	local meta=minetest.get_meta(pos)
	local meta2=meta
	meta:from_table(oldmeta)
	local inv=meta:get_inventory()
	for _,listname in ipairs(lists) do
		local stack=inv:get_stack(listname,1)
		if not stack:is_empty() then
			local p = {x=pos.x+math.random(0, 10)/10-0.5, y=pos.y, z=pos.z+math.random(0, 10)/10-0.5}
			minetest.add_item(p, stack)
		end
	end
	meta:from_table(meta2:to_table())
end

industrialtest.internal.allowMoveToUpgradeSlot=function(pos,toIndex,stack)
	local def=minetest.registered_items[stack:get_name()]
	if not def or not def.groups or not def.groups._industrialtest_machineUpgrade then
		return 0
	end
	local meta=minetest.get_meta(pos)
	local inv=meta:get_inventory()
	local targetSlot=inv:get_stack("upgrades",toIndex)
	if not targetSlot:is_empty() then
		return 0
	end
	return stack:get_count()
end

industrialtest.internal.chargeFromPowerStorageItem=function(meta,inv)
	local shouldRerunTimer=false
	local shouldUpdateFormspec=false
	local powerStorageSlot=inv:get_stack("powerStorage",1)
	if not powerStorageSlot:is_empty() then
		local stackMeta=powerStorageSlot:get_meta()
		if industrialtest.api.transferPower(stackMeta,meta,stackMeta:get_int("industrialtest.powerFlow"))>0 then
			shouldUpdateFormspec=true
			shouldRerunTimer=stackMeta:get_int("industrialtest.powerAmount")>0 and not industrialtest.api.isFullyCharged(meta)
			industrialtest.api.updateItemPowerText(powerStorageSlot)
			inv:set_stack("powerStorage",1,powerStorageSlot)
		end
	end
	return shouldRerunTimer,shouldUpdateFormspec
end

machine.getFormspec=function(pos,config)
	local formspec
	if industrialtest.mtgAvailable then
		formspec={
			"formspec_version[4]",
			"size[10.8,12]",
			"label[0.5,0.5;"..config.displayName.."]",
			"list[current_player;main;0.5,6.25;8,1]",
			"list[current_player;main;0.5,7.5;8,3;8]",
			"listring[current_player;main]",
			(config.getFormspec and config.getFormspec(pos) or "")
		}
	elseif industrialtest.mclAvailable then
		formspec={
			"size[10.04,12]",
			"label[0.25,0.25;"..config.displayName.."]",
			"list[current_player;main;0.5,7;9,3;9]",
			mcl_formspec.get_itemslot_bg(0.5,7,9,3),
			"list[current_player;main;0.5,10.24;9,1]",
			mcl_formspec.get_itemslot_bg(0.5,10.24,9,1),
			"listring[current_player;main]",
			(config.getFormspec and config.getFormspec(pos) or "")
		}
	end
	return table.concat(formspec,"")
end

machine.onConstruct=function(pos,config)
	local meta=minetest.get_meta(pos)
	local inv=meta:get_inventory()

	industrialtest.api.addPowerStorage(meta,config.capacity,config.flow,config.ioConfig)

	if config.groups then
		if config.groups._industrialtest_hasPowerInput then
			local connections=industrialtest.api.getConnections(pos)
			for _,conn in ipairs(connections) do
				local connectionMeta=minetest.get_meta(conn)
				if industrialtest.api.isNetworkMaster(connectionMeta) then
					industrialtest.api.createNetworkMapForNode(conn)
					minetest.get_node_timer(conn):start(industrialtest.updateDelay)
				else
					local def=minetest.registered_nodes[minetest.get_node(conn).name]
					if def.groups._industrialtest_cable then
						local networks=industrialtest.api.isAttachedToNetwork(connectionMeta)
						if networks then
							for _,network in ipairs(networks) do
								industrialtest.api.createNetworkMapForNode(network)
								minetest.get_node_timer(network):start(industrialtest.updateDelay)
							end
						end
					end
				end
			end
		end
		if config.groups._industrialtest_hasPowerOutput then
			meta:set_string("industrialtest.network",minetest.serialize(industrialtest.api.createNetworkMap(pos)))
		end
	end

	if config.onConstruct then
		config.onConstruct(pos,meta,inv)
	end

	if not config.withoutFormspec then
		meta:set_string("formspec",machine.getFormspec(pos,config))
	end

	minetest.get_node_timer(pos):start(industrialtest.updateDelay)
end

machine.onDestruct=function(pos,config)
	local meta=minetest.get_meta(pos)
	if industrialtest.api.isNetworkMaster(meta) then
		local network=industrialtest.api.createNetworkMap(pos,true)
		for _,endpoint in ipairs(network) do
			local endpointMeta=minetest.get_meta(endpoint.position)
			local networks=industrialtest.api.isAttachedToNetwork(endpointMeta)
			for key,value in ipairs(networks) do
				if value.x==pos.x and value.y==pos.y and value.z==pos.z then
					table.remove(networks,key)
					break
				end
			end
			endpointMeta:set_string("industrialtest.networks",minetest.serialize(networks))
		end
	end
	local networks=industrialtest.api.isAttachedToNetwork(meta)
	if networks then
		for _,network in ipairs(networks) do
			industrialtest.api.removeNodeFromNetwork(network,pos)
		end
	end
	if config.onDestruct then
		config.onDestruct(pos)
	end
end

machine.onTimer=function(pos,elapsed,config)
	local meta=minetest.get_meta(pos)
	local inv=meta:get_inventory()
	local shouldRerunTimer=false
	local shouldUpdateFormspec=false

	if config.onTimer then
		shouldRerunTimer,shouldUpdateFormspec=config.onTimer(pos,elapsed,meta,inv)
	end

	local def=minetest.registered_nodes[minetest.get_node(pos).name]
	if def.groups and def.groups._industrialtest_hasPowerInput and not industrialtest.api.isFullyCharged(meta) then
		local networks=industrialtest.api.isAttachedToNetwork(meta)
		if networks then
			for _,network in ipairs(networks) do
				minetest.get_node_timer(network):start(industrialtest.updateDelay)
			end
		end
	end

	if shouldUpdateFormspec then
		machine.updateFormspec(pos,config)
	end

	return shouldRerunTimer
end

machine.allowMetadataInventoryMove=function(pos,fromList,fromIndex,toList,toIndex,count,config)
	local meta=minetest.get_meta(pos)
	local inv=meta:get_inventory()
	local movedItemStack=inv:get_stack(fromList,1)

	if toList=="upgrades" then
		return industrialtest.internal.allowMoveToUpgradeSlot(pos,toIndex,movedItemStack)
	end

	local found=false
	if config.powerSlots then
		for _,value in ipairs(config.powerSlots) do
			if value==toList then
				found=true
				break
			end
		end
	end
	if found and not industrialtest.api.hasPowerStorage(movedItemStack:get_meta()) then
		return 0
	end

	if config.allowMetadataInventoryMove then
		return config.allowMetadataInventoryMove(pos,fromList,fromIndex,toList,toIndex,count)
	end

	return count
end

machine.allowMetadataInventoryPut=function(pos,listname,index,stack,player,config)
	if listname=="upgrades" then
		return industrialtest.internal.allowMoveToUpgradeSlot(pos,index,stack)
	end

	local found=false
	if config.powerSlots then
		for _,value in ipairs(config.powerSlots) do
			if value==listname then
				found=true
				break
			end
		end
	end
	if found and not industrialtest.api.hasPowerStorage(stack:get_meta()) then
		return 0
	end

	if config.allowMetadataInventoryPut then
		return config.allowMetadataInventoryPut(pos,listname,index,stack,player)
	end

	return stack:get_count()
end

machine.allowMetadataInventoryTake=function(pos,listname,index,stack,player,config)
	if config.allowMetadataInventoryTake then
		return config.allowMetadataInventoryTake(pos,listname,index,stack,player)
	end
	return stack:get_count()
end

machine.onMetadataInventoryMove=function(pos,fromList,fromIndex,toList,toIndex,count)
	if toList=="upgrades" then
		local meta=minetest.get_meta(pos)
		local inv=meta:get_inventory()
		local stack=inv:get_stack(fromList,fromIndex)
		industrialtest.internal.applyUpgrade(pos,meta,stack)
	elseif fromList=="upgrades" then
		local meta=minetest.get_meta(pos)
		local inv=meta:get_inventory()
		local stack=inv:get_stack(fromList,fromIndex)
		industrialtest.internal.removeUpgrade(pos,meta,stack)
	end
end

machine.onMetadataInventoryPut=function(pos,listname,index,stack)
	if listname=="upgrades" then
		local meta=minetest.get_meta(pos)
		industrialtest.internal.applyUpgrade(pos,meta,stack)
	end
end

machine.onMetadataInventoryTake=function(pos,listname,index,stack)
	if listname=="upgrades" then
		local meta=minetest.get_meta(pos)
		industrialtest.internal.removeUpgrade(pos,meta,stack)
	end
end

machine.updateFormspec=function(pos,config)
	if config.withoutFormspec then
		return
	end
	local meta=minetest.get_meta(pos)
	meta:set_string("formspec",machine.getFormspec(pos,config))
end

function industrialtest.internal.registerMachine(config)
	local definition={
		description=config.displayName,
		on_construct=function(pos)
			machine.onConstruct(pos,config)
		end,
		on_destruct=function(pos)
			machine.onDestruct(pos,config)
		end,
		on_timer=function(pos,elapsed)
			local shouldRerunTimer,_=machine.onTimer(pos,elapsed,config)
			return shouldRerunTimer
		end,
		allow_metadata_inventory_move=function(pos,fromList,fromIndex,toList,toIndex,count)
			return machine.allowMetadataInventoryMove(pos,fromList,fromIndex,toList,toIndex,count,config)
		end,
		allow_metadata_inventory_put=function(pos,listname,index,stack,player)
			return machine.allowMetadataInventoryPut(pos,listname,index,stack,player,config)
		end,
		allow_metadata_inventory_take=function(pos,listname,index,stack,player)
			return machine.allowMetadataInventoryTake(pos,listname,index,stack,player,config)
		end,
		on_metadata_inventory_put=function(pos,listname,index,stack,player)
			machine.onMetadataInventoryPut(pos,listname,index,stack)
			if config.onMetadataInventoryPut then
				config.onMetadataInventoryPut(pos,listname,index,stack,player)
			end
		end,
		on_metadata_inventory_move=function(pos,fromList,fromIndex,toList,toIndex,count)
			machine.onMetadataInventoryMove(pos,fromList,fromIndex,toList,toIndex)
			if config.onMetadataInventoryPut then
				config.onMetadataInventoryMove(pos,fromList,fromIndex,toList,toIndex,count)
			end
		end,
		on_metadata_inventory_take=function(pos,listname,index,stack,player)
			machine.onMetadataInventoryTake(pos,listname,index,stack)
			if config.onMetadataInventoryTake then
				config.onMetadataInventoryTake(pos,listname,index,stack,player)
			end
		end,
		_industrialtest_updateFormspec=function(pos)
			machine.updateFormspec(pos,config)
		end,
		_industrialtest_getFormspec=function(pos)
			if config.withoutFormspec then
				return ""
			end
			return machine.getFormspec(pos,config)
		end
	}
	if industrialtest.mtgAvailable then
		definition.groups={cracky=2}
		if config.sounds=="metal" then
			definition.sounds=default.node_sound_metal_defaults()
		end
		definition.can_dig=function(pos)
			local meta=minetest.get_meta(pos)
			local inv=meta:get_inventory()
			for _,value in ipairs(config.storageSlots) do
				if inv:get_stack(value,1):get_count()>0 then
					return false
				end
			end
			return true
		end
	elseif industrialtest.mclAvailable then
		definition.after_dig_node=function(pos,oldnode,oldmeta)
			industrialtest.internal.mclAfterDigNode(pos,oldmeta,config.storageSlots)
		end
		if config.sounds=="metal" then
			definition.sounds=mcl_sounds.node_sound_metal_defaults()
		end
		definition.groups={
			pickaxey=1,
			container=2
		}
		definition._mcl_blast_resistance=3.5
		definition._mcl_hardness=3.9
		definition._mcl_hoppers_on_try_pull=function(pos, hop_pos, hop_inv, hop_list)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			local stack = inv:get_stack("dst", 1)
			if not stack:is_empty() and hop_inv:room_for_item(hop_list, stack) then
				return inv, "dst", 1
			end
			return nil, nil, nil
		end
		definition._mcl_hoppers_on_try_push=function(pos, hop_pos, hop_inv, hop_list)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			return inv, "src", mcl_util.select_stack(hop_inv, hop_list, inv, "src")
		end
		definition._mcl_hoppers_on_after_push=function(pos)
			minetest.get_node_timer(pos):start(industrialtest.updateDelay)
		end
	end
	definition.groups._industrialtest_wrenchUnmountable=1
	if config.requiresWrench then
		definition.drop="industrialtest:machine_block"
	end
	if config.customKeys then
		for key,value in pairs(config.customKeys) do
			definition[key]=value
		end
	end
	if config.groups then
		for key,value in pairs(config.groups) do
			definition.groups[key]=value
		end
	end
	minetest.register_node("industrialtest:"..config.name,definition)
	if config.registerActiveVariant then
		definition=table.copy(definition)
		definition.description=nil
		definition.on_timer=function(pos,elapsed)
			local meta=minetest.get_meta(pos)
			local inv=meta:get_inventory()
			local shouldRerunTimer=false
			local shouldUpdateFormspec=false

			if config.activeOnTimer then
				shouldRerunTimer,shouldUpdateFormspec=config.activeOnTimer(pos,elapsed,meta,inv)
			end

			local def=minetest.registered_nodes[minetest.get_node(pos).name]
			if def.groups and def.groups._industrialtest_hasPowerInput and not industrialtest.api.isFullyCharged(meta) then
				local networks=industrialtest.api.isAttachedToNetwork(meta)
				if networks then
					for _,network in ipairs(networks) do
						minetest.get_node_timer(network):start(industrialtest.updateDelay)
					end
				end
			end

			if shouldUpdateFormspec then
				machine.updateFormspec(pos,config)
			end

			return shouldRerunTimer
		end
		if not definition.drop then
			definition.drop="industrialtest:"..config.name
		end
		if config.activeCustomKeys then
			for key,value in pairs(config.activeCustomKeys) do
				definition[key]=value
			end
		end
		if industrialtest.mclAvailable then
			definition.groups.not_in_creative_inventory=1
			definition._doc_items_create_entry=false
		end
		minetest.register_node("industrialtest:"..config.name.."_active",definition)
	end
end

local function craftResultProxy(method,item)
	if method=="cooking" then
		local output,after=minetest.get_craft_result({
			method=method,
			width=1,
			items={item}
		})
		return {
			item=output.item,
			time=output.time,
			src=after.items[1]
		}
	elseif method=="industrialtest.macerating" then
		local output=industrialtest.api.getMaceratorRecipeResult(item:get_name())
		if not output then
			return {
				item=ItemStack(),
				time=0,
				src=item
			}
		end
		local srcAfter=ItemStack(item:get_name())
		srcAfter:set_count(item:get_count()-1)
		return {
			item=ItemStack(output.output),
			time=output.time,
			src=srcAfter
		}
	elseif method=="industrialtest.compressing" then
		local output=industrialtest.api.getCompressorRecipeResult(item:get_name())
		if not output or item:get_count()<output.count then
			return {
				item=ItemStack(),
				time=0,
				src=item
			}
		end
		local srcAfter=ItemStack(item:get_name())
		srcAfter:set_count(item:get_count()-output.count)
		return {
			item=ItemStack(output.output),
			time=output.time,
			src=srcAfter
		}
	elseif method=="industrialtest.extracting" then
		local output=industrialtest.api.getExtractorRecipeResult(item:get_name())
		if not output then
			return {
				item=ItemStack(),
				time=0,
				src=item
			}
		end
		local srcAfter=ItemStack(item:get_name())
		srcAfter:set_count(item:get_count()-1)
		return {
			item=ItemStack(output.output),
			time=output.time,
			src=srcAfter
		}
	elseif method=="industrialtest.recycling" then
		local srcAfter=ItemStack(item:get_name())
		srcAfter:set_count(item:get_count()-1)
		return {
			item=ItemStack(industrialtest.random:next(1,8)==1 and "industrialtest:scrap" or ""),
			time=2,
			src=srcAfter
		}
	elseif method=="industrialtest.cable_forming" then
		local output=industrialtest.api.getCableFormerRecipeResult(item:get_name())
		if not output then
			return {
				item=ItemStack(),
				time=0,
				src=item
			}
		end
		local srcAfter=ItemStack(item:get_name())
		srcAfter:set_count(item:get_count()-1)
		return {
			item=ItemStack(output.output),
			time=output.time,
			src=srcAfter
		}
	elseif method=="industrialtest.mass_fabricating" then
		if item:get_count()<34 then
			return {
				item=ItemStack(),
				time=0,
				src=item
			}
		end
		local srcAfter=ItemStack(item:get_name())
		srcAfter:set_count(item:get_count()-34)
		return {
			item=ItemStack("industrialtest:uu_matter"),
			time=15,
			src=srcAfter
		}
	end
	error("Unknown craft method passed to craftResultProxy")
end

simpleElectricItemProcessor.getFormspec=function(pos)
	local meta=minetest.get_meta(pos)
	local powerPercent=meta:get_int("industrialtest.powerAmount")/meta:get_int("industrialtest.powerCapacity")*100
	local srcPercent=meta:get_float("srcTime")/meta:get_float("maxSrcTime")*100
	local formspec={
		"list[context;src;3.4,1.8;1,1]",
		industrialtest.internal.getItemSlotBg(3.4,1.8,1,1),
		(powerPercent>0 and "image[3.4,2.8;1,1;industrialtest_gui_electricity_bg.png^[lowpart:"..powerPercent..":industrialtest_gui_electricity_fg.png]"
		 or "image[3.4,2.8;1,1;industrialtest_gui_electricity_bg.png]"),
		"list[context;powerStorage;3.4,3.9;1,1]",
		industrialtest.internal.getItemSlotBg(3.4,3.9,1,1),
		(srcPercent>0 and "image[4.9,2.8;1,1;gui_furnace_arrow_bg.png^[lowpart:"..srcPercent..":gui_furnace_arrow_fg.png^[transformR270]"
		 or "image[4.9,2.8;1,1;gui_furnace_arrow_bg.png^[transformR270]"),
		"list[context;dst;6.4,2.8;1,1]",
		industrialtest.internal.getItemSlotBg(6.4,2.8,1,1),
		"list[context;upgrades;9,0.9;1,4]",
		industrialtest.internal.getItemSlotBg(9,0.9,1,4),
		"listring[context;src]",
		"listring[context;dst]"
	}
	return table.concat(formspec,"")
end

simpleElectricItemProcessor.onPowerFlow=function(pos)
	-- FIXME: this probably will require refactor so node timer won't be started
	-- just to test if machine can process item
	minetest.get_node_timer(pos):start(industrialtest.updateDelay)
end

simpleElectricItemProcessor.onConstruct=function(pos,meta,inv)
	inv:set_size("src",1)
	inv:set_size("dst",1)
	inv:set_size("powerStorage",1)
	inv:set_size("upgrades",4)
	meta:set_float("srcTime",-1)
	meta:set_float("maxSrcTime",0)
end

simpleElectricItemProcessor.onTimer=function(pos,elapsed,meta,inv,config)
	local srcSlot=inv:get_stack("src",1)
	local powerStorageSlot=inv:get_stack("powerStorage",1)
	local shouldUpdateFormspec=false
	local shouldRerunTimer=false
	local requiredPower=elapsed*config.opPower*industrialtest.api.getMachineSpeed(meta)

	shouldRerunTimer,shouldUpdateFormspec=industrialtest.internal.chargeFromPowerStorageItem(meta,inv)

	if srcSlot:get_count()>0 and meta:get_int("industrialtest.powerAmount")>=requiredPower then
		local output=craftResultProxy(config.method,srcSlot)
		if output.time>0 and inv:room_for_item("dst",output.item) then
			if meta:get_float("maxSrcTime")<=0 then
				meta:set_float("srcTime",0)
				meta:set_float("maxSrcTime",output.time*config.efficiency)
			end
			minetest.swap_node(pos,{
				name="industrialtest:"..config.name.."_active",
				param2=minetest.get_node(pos).param2
			})
			minetest.get_node_timer(pos):start(industrialtest.updateDelay)
		end
	end
	return shouldRerunTimer,shouldUpdateFormspec
end

simpleElectricItemProcessor.allowMetadataInventoryMove=function(pos,fromList,fromIndex,toList,count)
	if toList=="dst" then
		return 0
	elseif toList=="upgrades" then
		-- TODO: Add support for upgrades when they will be added
		return 0
	end
	return count
end

simpleElectricItemProcessor.allowMetadataInventoryPut=function(pos,listname,index,stack)
	if listname=="dst" then
		return 0
	elseif listname=="src" then
		local meta=minetest.get_meta(pos)
		local inv=meta:get_inventory()
		local srcSlot=inv:get_stack("src",1)
		if srcSlot:get_name()~=stack:get_name() then
			meta:set_float("srcTime",-1)
			meta:set_float("maxSrcTime",0)
		end
	elseif listname=="upgrades" then
		--TODO: See allow_metadata_inventory_move
		return 0
	end
	return stack:get_count()
end

simpleElectricItemProcessor.onMetadataInventoryPut=function(pos)
	minetest.get_node_timer(pos):start(industrialtest.updateDelay)
end

simpleElectricItemProcessor.onMetadataInventoryMove=function(pos,fromList,fromIndex,toList,toIndex,count)
	local meta=minetest.get_meta(pos)
	local inv=meta:get_inventory()
	local srcSlot=inv:get_stack("src",1)
	local dstSlot=inv:get_stack("dst",1)
	if fromList=="src" and count==srcSlot:get_count() then
		meta:set_float("srcTime",-1)
		meta:set_float("maxSrcTime",0)
		if meta:get_int("industrialtest.powerAmount")>0 then
			meta:set_string("formspec",simpleElectricItemProcessor.getFormspec(pos))
		end
	elseif fromList=="dst" and dstSlot:get_free_space()>0 then
		minetest.get_node_timer(pos):start(industrialtest.updateDelay)
	end
end

simpleElectricItemProcessor.onMetadataInventoryTake=function(pos,listname,index,stack)
	local meta=minetest.get_meta(pos)
	local inv=meta:get_inventory()
	local srcSlot=inv:get_stack("src",1)
	local dstSlot=inv:get_stack("dst",1)
	if listname=="src" and stack:get_count()==srcSlot:get_count() then
		meta:set_float("srcTime",-1)
		meta:set_float("maxSrcTime",0)
		if meta:get_int("industrialtest.powerAmount")>0 then
			meta:set_string("formspec",simpleElectricItemProcessor.getFormspec(pos))
		end
	elseif listname=="dst" and dstSlot:get_free_space()>0 then
		minetest.get_node_timer(pos):start(industrialtest.updateDelay)
	end
end

simpleElectricItemProcessor.activeOnTimer=function(pos,elapsed,meta,inv,config)
	local srcSlot=inv:get_stack("src",1)
	local powerStorageSlot=inv:get_stack("powerStorage",1)
	local shouldUpdateFormspec=false
	local shouldRerunTimer=false
	local requiredPower=elapsed*config.opPower*industrialtest.api.getMachineSpeed(meta)

	shouldRerunTimer,shouldUpdateFormspec=industrialtest.internal.chargeFromPowerStorageItem(meta,inv)

	if srcSlot:get_count()>0 and meta:get_float("maxSrcTime")<=0 and meta:get_int("industrialtest.powerAmount")>=requiredPower then
		local output=craftResultProxy(config.method,srcSlot)
		if output.time>0 and inv:room_for_item("dst",output.item) then
			meta:set_float("srcTime",0)
			meta:set_float("maxSrcTime",output.time*config.efficiency)
		end
	end
	if srcSlot:get_count()==0 and meta:get_float("maxSrcTime")>0 then
		meta:set_float("srcTime",-1)
		meta:set_float("maxSrcTime",0)
		shouldUpdateFormspec=true
	end
	if meta:get_float("maxSrcTime")>0 then
		if meta:get_int("industrialtest.powerAmount")>=requiredPower then
			meta:set_int("industrialtest.powerAmount",meta:get_int("industrialtest.powerAmount")-requiredPower)
			meta:set_float("srcTime",meta:get_float("srcTime")+elapsed)
			shouldRerunTimer=true
		end
		shouldUpdateFormspec=true
	end
	if meta:get_float("maxSrcTime")<=0 or meta:get_int("industrialtest.powerAmount")<requiredPower then
		minetest.swap_node(pos,{
			name="industrialtest:"..config.name,
			param2=minetest.get_node(pos).param2
		})
		minetest.get_node_timer(pos):start(industrialtest.updateDelay)
	end
	if meta:get_float("srcTime")>=meta:get_float("maxSrcTime") then
		local output=craftResultProxy(config.method,srcSlot)
		local speed=industrialtest.api.getMachineSpeed(meta)
		local usedItems=srcSlot:get_count()-output.src:get_count()
		local multiplier=1
		if srcSlot:get_count()>=speed*usedItems then
			multiplier=speed
		end
		if output.item:get_count()>0 then
			output.item:set_count(output.item:get_count()*multiplier)
			inv:add_item("dst",output.item)
			meta:set_float("srcTime",-1)
			meta:set_float("maxSrcTime",0)
		end
		srcSlot:set_count(srcSlot:get_count()-multiplier*usedItems)
		inv:set_stack("src",1,srcSlot)
	end
	return shouldRerunTimer,shouldUpdateFormspec
end

function industrialtest.internal.registerSimpleElectricItemProcessor(config)
	local machineBlockTexture=config.machineBlockTexture or "industrialtest_machine_block.png"
	industrialtest.internal.registerMachine({
		name=config.name,
		displayName=config.displayName,
		capacity=config.capacity,
		getFormspec=simpleElectricItemProcessor.getFormspec,
		flow=config.flow,
		ioConfig="iiiiii",
		requiresWrench=config.requiresWrench,
		registerActiveVariant=true,
		sounds="metal",
		powerSlots={"powerStorage"},
		storageSlots={"src","dst","powerStorage","upgrades"},
		groups={
			_industrialtest_hasPowerInput=1
		},
		customKeys={
			tiles={
				machineBlockTexture..(config.customTopTexture and "^industrialtest_"..config.name.."_top.png" or ""),
				machineBlockTexture..(config.customBottomTexture and "^industrialtest_"..config.name.."_bottom.png" or ""),
				machineBlockTexture..(config.customRightTexture and "^industrialtest_"..config.name.."_right.png" or ""),
				machineBlockTexture..(config.customLeftTexture and "^industrialtest_"..config.name.."_left.png" or ""),
				machineBlockTexture..(config.customBackTexture and "^industrialtest_"..config.name.."_back.png" or ""),
				machineBlockTexture..(config.customFrontTexture and "^industrialtest_"..config.name.."_front.png" or "")
			},
			paramtype2="facedir",
			legacy_facedir_simple=true,
			_industrialtest_onPowerFlow=simpleElectricItemProcessor.onPowerFlow
		},
		activeCustomKeys={
			tiles={
				machineBlockTexture..(config.customTopTexture and "^industrialtest_"..config.name.."_top_active.png" or ""),
				machineBlockTexture..(config.customBottomTexture and "^industrialtest_"..config.name.."_bottom_active.png" or ""),
				machineBlockTexture..(config.customRightTexture and "^industrialtest_"..config.name.."_right_active.png" or ""),
				machineBlockTexture..(config.customLeftTexture and "^industrialtest_"..config.name.."_left_active.png" or ""),
				machineBlockTexture..(config.customBackTexture and "^industrialtest_"..config.name.."_back_active.png" or ""),
				machineBlockTexture..(config.customFrontTexture and "^industrialtest_"..config.name.."_front_active.png" or "")
			}
		},
		onConstruct=simpleElectricItemProcessor.onConstruct,
		onTimer=function(pos,elapsed,meta,inv)
			return simpleElectricItemProcessor.onTimer(pos,elapsed,meta,inv,config)
		end,
		allowMetadataInventoryMove=simpleElectricItemProcessor.allowMetadataInventoryMove,
		allowMetadataInventoryPut=simpleElectricItemProcessor.allowMetadataInventoryPut,
		onMetadataInventoryPut=simpleElectricItemProcessor.onMetadataInventoryPut,
		onMetadataInventoryMove=simpleElectricItemProcessor.onMetadataInventoryMove,
		onMetadataInventoryTake=simpleElectricItemProcessor.onMetadataInventoryTake,
		activeOnTimer=function(pos,elapsed,meta,inv)
			return simpleElectricItemProcessor.activeOnTimer(pos,elapsed,meta,inv,config)
		end
	})
	table.insert(industrialtest.internal.simpleElectricItemProcessors,"industrialtest:"..config.name)
end
