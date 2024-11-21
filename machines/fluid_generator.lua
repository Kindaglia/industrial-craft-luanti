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
local fluidGenerator={}

fluidGenerator.getFormspec=function(pos,config)
	local meta=minetest.get_meta(pos)
	local fluidPercent=meta:get_float("fluidAmount")/100
	local powerPercent=meta:get_int("industrialtest.powerAmount")/meta:get_int("industrialtest.powerCapacity")
	local fluid=meta:get_string("fluid")
	local fuel=config.getFuel(fluid)
	local tile=(fuel and fuel.texture or "industrialtest_gui_fluid_bg.png")
	local formspec={
		"list[context;src;2,1.8;1,1]",
		industrialtest.internal.getItemSlotBg(2,1.8,1,1),
		(fluidPercent>0 and "image[2,3;1,1;industrialtest_gui_fluid_bg.png^[lowpart:"..fluidPercent..":"..tile.."]" or "image[2,3;1,1;industrialtest_gui_fluid_bg.png]"),
		"list[context;dst;2,4.2;1,1]",
		industrialtest.internal.getItemSlotBg(2,4.2,1,1),
		"list[context;charged;6,3;1,1]",
		industrialtest.internal.getItemSlotBg(6,3,1,1),
		"box[9,1;0.3,4.8;#202020]",
		(powerPercent>0 and "box[9,"..(1+4.8-(powerPercent*4.8))..";0.3,"..(powerPercent*4.8)..";#FF1010]" or ""),
		"listring[context;src]",
		"listring[context;dst]"
	}
	return table.concat(formspec,"")
end

fluidGenerator.onConstruct=function(pos,meta,inv)
	inv:set_size("charged",1)
	inv:set_size("src",1)
	inv:set_size("dst",1)
	meta:set_float("fluidAmount",0)
	meta:set_string("fluid","")
end

fluidGenerator.onTimer=function(pos,elapsed,meta,inv,config)
	local fluidSlot=inv:get_stack("src",1)
	local chargedSlot=inv:get_stack("charged",1)
	local afterFlow,flowTransferred=industrialtest.api.powerFlow(pos)
	local shouldUpdateFormspec=false
	local shouldRerunTimer=(afterFlow and meta:get_int("industrialtest.powerAmount")>0)
	if fluidSlot:get_count()>0 and meta:get_float("fluidAmount")<=9000 then
		local fuel=config.getFuelByItem(fluidSlot:get_name())
		if fuel and (fuel.name==meta:get_string("fluid") or meta:get_string("fluid")=="") then
			local leftover=false
			local leftoverAddingSucceeded=false
			for _,item in ipairs(fuel.storageItems) do
				if item.name==fluidSlot:get_name() and item.leftover then
					if inv:room_for_item("dst",ItemStack(item.leftover)) then
						inv:add_item("dst",ItemStack(item.leftover))
						leftoverAddingSucceeded=true
					end
					leftover=true
				end
			end
			if not leftover or leftoverAddingSucceeded then
				fluidSlot:take_item()
				inv:set_stack("src",1,fluidSlot)
				meta:set_string("fluid",fuel.name)
				meta:set_float("fluidAmount",meta:get_float("fluidAmount")+1000)
				shouldUpdateFormspec=true
				shouldRerunTimer=false
			end
		end
	end
	if meta:get_float("fluidAmount")>=50 and not industrialtest.api.isFullyCharged(meta) then
		meta:set_float("fluidAmount",meta:get_int("fluidAmount")-50*elapsed)
		local toAdd=math.ceil(config.getFuel(meta:get_string("fluid")).calorificValue*elapsed)
		industrialtest.api.addPower(meta,toAdd)
		shouldUpdateFormspec=true
		if config.registerActiveVariant then
			minetest.swap_node(pos,{
				name="industrialtest:"..config.name.."_active",
				param2=minetest.get_node(pos).param2
			})
			minetest.get_node_timer(pos):start(industrialtest.updateDelay)
		else
			shouldRerunTimer=true
		end
	end
	if chargedSlot:get_count()>0 and meta:get_int("industrialtest.powerAmount")>0 then
		if industrialtest.api.transferPowerToItem(meta,chargedSlot,industrialtest.api.lvPowerFlow)>0 then
			inv:set_stack("charged",1,chargedSlot)
			shouldUpdateFormspec=true
			shouldRerunTimer=true
		end
	end
	if flowTransferred then
		shouldUpdateFormspec=true
	end
	return shouldRerunTimer,shouldUpdateFormspec
end

fluidGenerator.metadataChange=function(pos)
	minetest.get_node_timer(pos):start(industrialtest.updateDelay)
end

fluidGenerator.activeOnTimer=function(pos,elapsed,meta,inv,config)
	local fluidSlot=inv:get_stack("src",1)
	local chargedSlot=inv:get_stack("charged",1)
	local afterFlow,flowTransferred=industrialtest.api.powerFlow(pos)
	local shouldUpdateFormspec=false
	local shouldRerunTimer=(afterFlow and meta:get_int("industrialtest.powerAmount")>0)

	if fluidSlot:get_count()>0 and meta:get_float("fluidAmount")<=9000 then
		local fuel=config.getFuelByItem(fluidSlot:get_name())
		if fuel and (fuel.name==meta:get_string("fluid") or meta:get_string("fluid")=="") then
			local leftover=false
			local leftoverAddingSucceeded=false
			for _,item in ipairs(fuel.storageItems) do
				if item.name==fluidSlot:get_name() and item.leftover then
					if inv:room_for_item("dst",ItemStack(item.leftover)) then
						inv:add_item("dst",ItemStack(item.leftover))
						leftoverAddingSucceeded=true
					end
					leftover=true
				end
			end
			if not leftover or leftoverAddingSucceeded then
				fluidSlot:take_item()
				inv:set_stack("src",1,fluidSlot)
				meta:set_string("fluid",fuel.name)
				meta:set_float("fluidAmount",meta:get_float("fluidAmount")+1000)
				shouldUpdateFormspec=true
				shouldRerunTimer=false
			end
		end
	end
	if meta:get_float("fluidAmount")>=50 and not industrialtest.api.isFullyCharged(meta) then
		meta:set_float("fluidAmount",meta:get_int("fluidAmount")-50*elapsed)
		local toAdd=math.ceil(industrialtest.api.getGeothermalGeneratorFuel(meta:get_string("fluid")).calorificValue*elapsed)
		industrialtest.api.addPower(meta,toAdd)
		shouldUpdateFormspec=true
		shouldRerunTimer=true
	else
		minetest.swap_node(pos,{
			name="industrialtest:"..config.name,
			param2=minetest.get_node(pos).param2
		})
		minetest.get_node_timer(pos):start(industrialtest.updateDelay)
	end
	if chargedSlot:get_count()>0 and meta:get_int("industrialtest.powerAmount")>0 then
		if industrialtest.api.transferPowerToItem(meta,chargedSlot,industrialtest.api.lvPowerFlow)>0 then
			inv:set_stack("charged",1,chargedSlot)
			shouldUpdateFormspec=true
			shouldRerunTimer=true
		end
	end
	if flowTransferred then
		shouldUpdateFormspec=true
	end
	return shouldRerunTimer,shouldUpdateFormspec
end

local function registerFluidGenerator(config)
	local definition={
		name=config.name,
		displayName=config.displayName,
		getFormspec=function(pos)
			return fluidGenerator.getFormspec(pos,config)
		end,
		capacity=7000,
		flow=industrialtest.api.lvPowerFlow,
		ioConfig="oooooo",
		requiresWrench=true,
		registerActiveVariant=config.registerActiveVariant,
		powerSlots={"charged"},
		storageSlots={"src","dst"},
		sounds="metal",
		groups={
			_industrialtest_hasPowerOutput=1
		},
		customKeys={
			tiles={
				"industrialtest_machine_block.png"..(config.customTopTexture and "^"..config.customTopTexture or ""),
				"industrialtest_machine_block.png"..(config.customBottomTexture and "^"..config.customBottomTexture or ""),
				"industrialtest_machine_block.png"..(config.customRightTexture and "^"..config.customRightTexture or ""),
				"industrialtest_machine_block.png"..(config.customLeftTexture and "^"..config.customLeftTexture or ""),
				"industrialtest_machine_block.png"..(config.customBackTexture and "^"..config.customBackTexture or ""),
				"industrialtest_machine_block.png"..(config.customFrontTexture and "^"..config.customFrontTexture or "")
			},
			paramtype2="facedir",
			legacy_facedir_simple=true
		},
		onConstruct=fluidGenerator.onConstruct,
		onTimer=function(pos,elapsed,meta,inv)
			return fluidGenerator.onTimer(pos,elapsed,meta,inv,config)
		end,
		onMetadataInventoryPut=fluidGenerator.metadataChange,			
		onMetadataInventoryMove=fluidGenerator.metadataChange
	}
	if config.registerActiveVariant then
		definition.activeCustomKeys={
			tiles={
				"industrialtest_machine_block.png"..(config.customTopTexture and "^"..config.customTopTextureActive or ""),
				"industrialtest_machine_block.png"..(config.customBottomTexture and "^"..config.customBottomTextureActive or ""),
				"industrialtest_machine_block.png"..(config.customRightTexture and "^"..config.customRightTextureActive or ""),
				"industrialtest_machine_block.png"..(config.customLeftTexture and "^"..config.customLeftTextureActive or ""),
				"industrialtest_machine_block.png"..(config.customBackTexture and "^"..config.customBackTextureActive or ""),
				"industrialtest_machine_block.png"..(config.customFrontTexture and "^"..config.customFrontTextureActive or "")
			},
			light_source=8
		}
		definition.activeOnTimer=function(pos,elapsed,meta,inv)
			return fluidGenerator.activeOnTimer(pos,elapsed,meta,inv,config)
		end
	end
	industrialtest.internal.registerMachine(definition)
end

registerFluidGenerator({
	name="geothermal_generator",
	displayName=S("Geothermal Generator"),
	customFrontTexture="industrialtest_geothermal_generator_front.png",
	customFrontTextureActive="industrialtest_geothermal_generator_front_active.png",
	getFuel=industrialtest.api.getGeothermalGeneratorFuel,
	getFuelByItem=industrialtest.api.getGeothermalGeneratorFuelByItem,
	registerActiveVariant=true,
	reactsToNeighbouringNodes=false
})

registerFluidGenerator({
	name="water_mill",
	displayName=S("Water Mill"),
	customLeftTexture="industrialtest_water_mill_side.png",
	customRightTexture="industrialtest_water_mill_side.png",
	customFrontTexture="industrialtest_water_mill_side.png",
	customBackTexture="industrialtest_water_mill_side.png",
	getFuel=industrialtest.api.getWaterMillFuel,
	getFuelByItem=industrialtest.api.getWaterMillFuelByItem,
	registerActiveVariant=false
})
local neighbors={}
for key,_ in pairs(industrialtest.api.waterMillFuels) do
	table.insert(neighbors,key)
end
minetest.register_abm({
	label="Water Mill generating",
	nodenames={"industrialtest:water_mill"},
	neighbors=neighbors,
	interval=industrialtest.updateDelay,
	chance=1,
	action=function(pos,node)
		local meta=minetest.get_meta(pos)
		local inv=meta:get_inventory()
		local chargedSlot=inv:get_stack("charged",1)
		local powerToAdd=0
		local neighbourPositions={
			vector.offset(pos,-1,0,0),
			vector.offset(pos,1,0,0),
			vector.offset(pos,0,-1,0),
			vector.offset(pos,0,1,0),
			vector.offset(pos,0,0,-1),
			vector.offset(pos,0,0,1)
		}
		for _,value in ipairs(neighbourPositions) do
			local node=minetest.get_node_or_nil(value)
			if node then
				local fuel=industrialtest.api.getWaterMillFuel(node.name)
				if fuel then
					powerToAdd=powerToAdd+fuel.calorificValue*0.2
				end
			end
		end
		if industrialtest.api.addPower(meta,powerToAdd)>0 then
			local def=minetest.registered_nodes[node.name]
			def._industrialtest_updateFormspec(meta)
		end
		if chargedSlot:get_count()>0 and meta:get_int("industrialtest.powerAmount")>0 then
			if industrialtest.api.transferPowerToItem(meta,chargedSlot,industrialtest.api.lvPowerFlow)>0 then
				inv:set_stack("charged",1,chargedSlot)
			end
		end
	end
})

minetest.register_craft({
	type="shaped",
	output="industrialtest:water_mill",
	recipe={
		{"",industrialtest.elementKeys.stick,""},
		{industrialtest.elementKeys.stick,"industrialtest:generator",industrialtest.elementKeys.stick},
		{"",industrialtest.elementKeys.stick,""}
	}
})
