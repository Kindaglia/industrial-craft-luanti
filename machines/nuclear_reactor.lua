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
local reactor={}
local reactorChamber={}

reactor.getFormspec=function(pos)
	local meta=minetest.get_meta(pos)
	local charged=meta:get_int("industrialtest.powerAmount")/meta:get_int("industrialtest.powerCapacity")
	local size=math.floor(meta:get_int("size")/3)
	local switchText=(meta:get_int("enabled")==0 and S("Start") or S("Stop"))
	local formspec={
		"list[context;fuel;1,1;"..size..","..size.."]",
		industrialtest.internal.getItemSlotBg(1,1,size,size),
		"list[context;charged;7,2.8;1,1]",
		industrialtest.internal.getItemSlotBg(7.7,2.8,1,1),
		"button[7.7,1;1,0.8;toggle;"..minetest.formspec_escape(switchText).."]",
		"box[9,1;0.3,4.8;#202020]",
		(charged>0 and "box[9,"..(1+4.8-(charged*4.8))..";0.3,"..(charged*4.8)..";#FF1010]" or ""),
		"listring[context;fuel]"
	}
	return table.concat(formspec,"")
end

reactor.onConstruct=function(pos,meta,inv)
	inv:set_size("fuel",4)
	inv:set_size("charged",1)
	meta:set_int("heat",0)
	meta:set_int("size",6)
	meta:set_int("enabled",0)
	meta:set_int("stateChanged",0)
end

reactor.onDestruct=function(pos)
	local meta=minetest.get_meta(pos)
	local chambers=minetest.deserialize(meta:get_string("chambers")) or {}
	for _,chamber in ipairs(chambers) do
		minetest.remove_node(chamber)
		minetest.add_item(chamber,"industrialtest:nuclear_reactor_chamber")
	end
end

local function hasFuel(fuelList)
	for _,stack in ipairs(fuelList) do
		if stack:get_name()=="industrialtest:uranium_cell" then
			return true
		end
	end
	return false
end

local function findMaxFuelCluster(size,fuelList)
	local maxCluster={}
	for y=1,size do
		for x=1,size do
			local iy=y-1
			local stack=fuelList[iy*size+x]
			local def=minetest.registered_tools[stack:get_name()]
			if def and def.groups._industrialtest_nuclearReactorFuel then
				local cluster={
					[1]={
						x=x,
						y=iy
					}
				}
				if x>1 and fuelList[iy*size+x-1]:get_name()==stack:get_name() then
					table.insert(cluster,{
						x=x-1,
						y=iy
					})
				end
				if x<size and fuelList[iy*size+x+1]:get_name()==stack:get_name() then
					table.insert(cluster,{
						x=x+1,
						y=iy
					})
				end
				if y>1 and fuelList[(iy-1)*size+x]:get_name()==stack:get_name() then
					table.insert(cluster,{
						x=x,
						y=iy-1
					})
				end
				if y<size and fuelList[(iy+1)*size+x]:get_name()==stack:get_name() then
					table.insert(cluster,{
						x=x,
						y=iy+1
					})
				end
				if x>1 and y>1 and fuelList[(iy-1)*size+x-1]:get_name()==stack:get_name() then
					table.insert(cluster,{
						x=x-1,
						y=iy-1
					})
				end
				if x<size and y>1 and fuelList[(iy-1)*size+x+1]:get_name()==stack:get_name() then
					table.insert(cluster,{
						x=x+1,
						y=iy-1
					})
				end
				if x>1 and y<size and fuelList[(iy+1)*size+x-1]:get_name()==stack:get_name() then
					table.insert(cluster,{
						x=x-1,
						y=iy+1
					})
				end
				if x<size and y<size and fuelList[(iy+1)*size+x+1]:get_name()==stack:get_name() then
					table.insert(cluster,{
						x=x+1,
						y=iy+1
					})
				end
				if #cluster==9 then
					return cluster
				end
				if #cluster>#maxCluster then
					maxCluster=cluster
				end
			end
		end
	end
	return maxCluster
end

local function findCoolant(fuelList)
	for i=1,#fuelList do
		local stack=fuelList[i]
		local def=minetest.registered_tools[stack:get_name()]
		if def and def.groups._industrialtest_nuclearReactorCoolant then
			return i
		end
	end
	return 0
end

local function useFuel(stack,use)
	local used=math.min(65535-stack:get_wear(),use)
	if used<use then
		stack:replace("industrialtest:empty_cell")
	else
		stack:set_wear(stack:get_wear()+used)
	end
	return stack,used
end

reactor.onTimer=function(pos,elapsed,meta,inv)
	local powerFlow=meta:get_int("industrialtest.powerFlow")
	local chargedSlot=inv:get_stack("charged",1)
	local fuelList=inv:get_list("fuel")
	local afterFlow,flowTransferred=industrialtest.api.powerFlow(pos)
	local shouldRerunTimer=meta:get_int("enabled")>0
	local shouldUpdateFormspec=false

	if chargedSlot:get_count()>0 and not industrialtest.api.isFullyCharged(chargedSlot:get_meta()) and meta:get_int("industrialtest.powerAmount")>0 then
		industrialtest.api.transferPowerToItem(meta,chargedSlot,powerFlow)
		inv:set_stack("charged",1,chargedSlot)
		shouldUpdateFormspec=true
		shouldRerunTimer=true
	end

	if meta:get_int("stateChanged")>0 then
		shouldUpdateFormspec=true
		meta:set_int("stateChanged",0)
	end

	if meta:get_int("enabled")>0 and hasFuel(fuelList) then
		minetest.swap_node(pos,{
			name="industrialtest:nuclear_reactor_active",
			param2=minetest.get_node(pos).param2
		})
		minetest.get_node_timer(pos):start(industrialtest.updateDelay)
		shouldRerunTimer=false
	end

	reactor.synchronizeChambers(pos)

	return shouldRerunTimer,shouldUpdateFormspec
end

reactor.activeOnTimer=function(pos,elapsed,meta,inv)
	local powerFlow=meta:get_int("industrialtest.powerFlow")
	local size=math.floor(meta:get_int("size")/3)
	local chargedSlot=inv:get_stack("charged",1)
	local fuelList=inv:get_list("fuel")
	local afterFlow,flowTransferred=industrialtest.api.powerFlow(pos)
	local shouldRerunTimer=meta:get_int("enabled")>0
	local shouldUpdateFormspec=false

	if chargedSlot:get_count()>0 and not industrialtest.api.isFullyCharged(chargedSlot:get_meta()) and meta:get_int("industrialtest.powerAmount")>0 then
		industrialtest.api.transferPowerToItem(meta,chargedSlot,powerFlow)
		inv:set_stack("charged",1,chargedSlot)
		shouldUpdateFormspec=true
		shouldRerunTimer=true
	end

	if meta:get_int("stateChanged")>0 then
		shouldUpdateFormspec=true
		meta:set_int("stateChanged",0)
	end

	if meta:get_int("enabled")==0 or not hasFuel(fuelList) then
		minetest.swap_node(pos,{
			name="industrialtest:nuclear_reactor",
			param2=minetest.get_node(pos).param2
		})
		meta:set_int("enabled",0)
		reactor.synchronizeChambers(pos)
		minetest.get_node_timer(pos):start(industrialtest.updateDelay)
		return false,shouldUpdateFormspec
	end

	local maxCluster=findMaxFuelCluster(size,fuelList)
	for _,stack in ipairs(maxCluster) do
		local index=stack.y*size+stack.x
		local usedStack,_=useFuel(fuelList[index],5)
		inv:set_stack("fuel",index,usedStack)
	end
	local generatedPowerAmount=math.pow(3,#maxCluster)
	if industrialtest.api.addPower(meta,generatedPowerAmount)>0 then
		shouldUpdateFormspec=true
	end

	local heat=meta:get_int("heat")+#maxCluster
	local coolant=findCoolant(fuelList)
	if coolant>0 then
		local coolantStack,used=useFuel(fuelList[coolant],#maxCluster*50)
		heat=math.max(0,heat-used)
		inv:set_stack("fuel",coolant,coolantStack)
	end
	if heat>200 then
		minetest.remove_node(pos)
		industrialtest.internal.explode(pos,#maxCluster*4)
		return false,false
	end
	meta:set_int("heat",heat)

	reactor.synchronizeChambers(pos)

	return shouldRerunTimer,shouldUpdateFormspec
end

reactor.allowMetadataInventoryMove=function(pos,fromList,fromIndex,toList,toIndex,count)
	local meta=minetest.get_meta(pos)
	local inv=meta:get_inventory()
	local movedItemStack=inv:get_stack(fromList,fromIndex)
	local def=minetest.registered_tools[movedItemStack:get_name()]
	if toList=="fuel" and (not def or not def.groups._industrialtest_placedInNuclearReactor) then
		return 0
	end
	return count
end

reactor.allowMetadataInventoryPut=function(pos,listname,index,stack)
	local def=minetest.registered_tools[stack:get_name()]
	if listname=="fuel" and (not def or not def.groups._industrialtest_placedInNuclearReactor) then
		return 0
	end
	return stack:get_count()
end

reactor.metadataChange=function(pos)
	minetest.get_node_timer(pos):start(industrialtest.updateDelay)
	reactor.synchronizeChambers(pos)
end

reactor.handleFormspecFields=function(pos,formname,fields)
	if not fields.toggle then
		return
	end
	local meta=minetest.get_meta(pos)
	local inv=meta:get_inventory()
	local fuelList=inv:get_list("fuel")
	if not hasFuel(fuelList) and meta:get_int("enabled")==0 then
		return
	end
	if meta:get_int("enabled")==0 then
		meta:set_int("enabled",1)
	else
		meta:set_int("enabled",0)
	end
	meta:set_int("stateChanged",1)
	reactor.metadataChange(pos)
end

reactor.synchronizeToChamber=function(pos)
	local meta=minetest.get_meta(pos)
	local inv=meta:get_inventory()
	local fuelList=inv:get_list("fuel")
	local chargedList=inv:get_list("charged")

	local reactorPos=minetest.deserialize(meta:get_string("reactor"))
	local reactorMeta=minetest.get_meta(reactorPos)
	local reactorInv=reactorMeta:get_inventory()
	reactorInv:set_list("fuel",fuelList)
	reactorInv:set_list("charged",chargedList)

	reactor.synchronizeChambers(reactorPos)
end

reactor.synchronizeChambers=function(pos)
	local meta=minetest.get_meta(pos)
	local chambers=meta:contains("chambers") and minetest.deserialize(meta:get_string("chambers")) or {}
	for _,chamber in ipairs(chambers) do
		reactorChamber.synchronize(chamber,pos)
	end
end

reactor.changeSize=function(pos,diff)
	local meta=minetest.get_meta(pos)
	local inv=meta:get_inventory()
	local size=meta:get_int("size")+diff
	local actualSize=math.floor(size/3)
	meta:set_int("size",size)
	inv:set_size("fuel",actualSize*actualSize)

	local def=minetest.registered_nodes[minetest.get_node(pos).name]
	def._industrialtest_updateFormspec(pos)
end

reactorChamber.synchronize=function(pos,reactor)
	local meta=minetest.get_meta(pos)
	local inv=meta:get_inventory()
	local reactorDef=minetest.registered_nodes[minetest.get_node(reactor).name]
	meta:set_string("formspec",reactorDef._industrialtest_getFormspec(reactor))

	local reactorMeta=minetest.get_meta(reactor)
	local reactorInv=reactorMeta:get_inventory()
	local fuelList=reactorInv:get_list("fuel")
	local chargedList=reactorInv:get_list("charged")
	inv:set_size("fuel",#fuelList)
	inv:set_size("charged",#chargedList)
	inv:set_list("fuel",fuelList)
	inv:set_list("charged",chargedList)
end

reactorChamber.afterPlaceNode=function(pos)
	local neighbours={
		vector.offset(pos,-1,0,0),
		vector.offset(pos,1,0,0),
		vector.offset(pos,0,-1,0),
		vector.offset(pos,0,1,0),
		vector.offset(pos,0,0,-1),
		vector.offset(pos,0,0,1)
	}
	local reactorPos=nil
	for _,neighbour in ipairs(neighbours) do
		local node=minetest.get_node(neighbour)
		if node.name=="industrialtest:nuclear_reactor" or node.name=="industrialtest:nuclear_reactor_active" then
			reactorPos=neighbour
		end
	end
	if not reactorPos then
		minetest.remove_node(pos)
		return true
	end

	local meta=minetest.get_meta(pos)
	meta:set_string("reactor",minetest.serialize(reactorPos))

	reactor.changeSize(reactorPos,1)
	reactor.synchronizeChambers(reactorPos)

	local reactorMeta=minetest.get_meta(reactorPos)
	local chambers=reactorMeta:contains("chambers") and minetest.deserialize(reactorMeta:get_string("chambers")) or {}
	table.insert(chambers,pos)
	reactorMeta:set_string("chambers",minetest.serialize(chambers))

	industrialtest.api.createNetworkMapForNode(reactorPos)

	reactorChamber.synchronize(pos,reactorPos)
end

reactorChamber.onDestruct=function(pos)
	local meta=minetest.get_meta(pos)
	if not meta:contains("reactor") then
		return
	end
	local reactorPos=minetest.deserialize(meta:get_string("reactor"))
	local reactorMeta=minetest.get_meta(reactorPos)
	if not reactorMeta or not reactorMeta:contains("chambers") then
		return
	end
	local chambers=minetest.deserialize(reactorMeta:get_string("chambers"))
	for i,chamber in ipairs(chambers) do
		if chamber.x==pos.x and chamber.y==pos.y and chamber.z==pos.z then
			table.remove(chambers,i)
			break
		end
	end
	reactorMeta:set_string("chambers",minetest.serialize(chambers))
	reactor.changeSize(reactorPos,-1)
	reactor.synchronizeChambers(reactorPos)
end

reactorChamber.handleFormspecFields=function(pos,formname,fields)
	local meta=minetest.get_meta(pos)
	local reactorPos=minetest.deserialize(meta:get_string("reactor"))
	reactor.handleFormspecFields(reactorPos,formname,fields)
end

industrialtest.internal.registerMachine({
	name="nuclear_reactor",
	displayName=S("Nuclear Reactor"),
	getFormspec=reactor.getFormspec,
	capacity=industrialtest.api.evPowerFlow,
	flow=industrialtest.api.evPowerFlow,
	ioConfig="oooooo",
	requiresWrench=true,
	registerActiveVariant=true,
	powerSlots={"charged"},
	storageSlots={"charged","fuel"},
	sounds="metal",
	groups={
		_industrialtest_hasPowerOutput=1
	},
	customKeys={
		tiles={
			"industrialtest_machine_block.png^industrialtest_nuclear_reactor_top.png",
			"industrialtest_machine_block.png",
			"industrialtest_machine_block.png",
			"industrialtest_machine_block.png",
			"industrialtest_machine_block.png",
			"industrialtest_machine_block.png^industrialtest_nuclear_reactor_front.png",
			"industrialtest_machine_block.png"
		},
		paramtype2="facedir",
		legacy_facedir_simple=true,
		on_receive_fields=reactor.handleFormspecFields,
		_industrialtest_synchronizeToChamber=reactor.synchronizeToChamber
	},
	activeCustomKeys={
		tiles={
			"industrialtest_machine_block.png^industrialtest_nuclear_reactor_top.png",
			"industrialtest_machine_block.png",
			"industrialtest_machine_block.png",
			"industrialtest_machine_block.png",
			"industrialtest_machine_block.png",
			"industrialtest_machine_block.png^industrialtest_nuclear_reactor_front_active.png",
			"industrialtest_machine_block.png"
		},
		light_source=2,
		on_receive_fields=reactor.handleFormspecFields
	},
	onConstruct=reactor.onConstruct,
	onDestruct=reactor.onDestruct,
	onTimer=reactor.onTimer,
	activeOnTimer=reactor.activeOnTimer,
	allowMetadataInventoryMove=reactor.allowMetadataInventoryMove,
	allowMetadataInventoryPut=reactor.allowMetadataInventoryPut,
	onMetadataInventoryMove=reactor.metadataChange,
	onMetadataInventoryPut=reactor.metadataChange,
	onMetadataInventoryTake=reactor.metadataChange
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:nuclear_reactor",
	recipe={
		{"","industrialtest:advanced_electronic_circuit",""},
		{"industrialtest:nuclear_reactor_chamber","industrialtest:nuclear_reactor_chamber","industrialtest:nuclear_reactor_chamber"},
		{"","industrialtest:generator",""}
	}
})

local definition={
	description=S("Nuclear Reactor Chamber"),
	tiles={"industrialtest_machine_block.png^industrialtest_nuclear_reactor_top.png"},
	drop="industrialtest:machine_block",
	groups={
		_industrialtest_wrenchUnmountable=1,
		_industrialtest_cable=1
	},
	on_destruct=reactorChamber.onDestruct,
	after_place_node=reactorChamber.afterPlaceNode,
	can_dig=minetest.registered_nodes["industrialtest:nuclear_reactor"].can_dig,
	on_receive_fields=reactorChamber.handleFormspecFields,
	allow_metadata_inventory_move=minetest.registered_nodes["industrialtest:nuclear_reactor"].allow_metadata_inventory_move,
	allow_metadata_inventory_put=minetest.registered_nodes["industrialtest:nuclear_reactor"].allow_metadata_inventory_put,
	on_metadata_inventory_move=reactor.synchronizeToChamber,
	on_metadata_inventory_put=reactor.synchronizeToChamber,
	on_metadata_inventory_take=reactor.synchronizeToChamber,
	_industrialtest_cableFlow=industrialtest.api.evPowerFlow
}
if industrialtest.mtgAvailable then
	definition.sounds=default.node_sound_metal_defaults()
	definition.groups.cracky=1
	definition.groups.level=2
elseif industrialtest.mclAvailable then
	definition.sounds=mcl_sounds.node_sound_metal_defaults()
	definition._mcl_blast_resistance=6
	definition._mcl_hardness=5
end
minetest.register_node("industrialtest:nuclear_reactor_chamber",definition)
minetest.register_craft({
	type="shaped",
	output="industrialtest:nuclear_reactor_chamber",
	recipe={
		{"","industrialtest:lead_plate",""},
		{"industrialtest:lead_plate","industrialtest:machine_block","industrialtest:lead_plate"},
		{"","industrialtest:lead_plate",""}
	}
})
