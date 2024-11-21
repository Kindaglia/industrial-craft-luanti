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

local chargepad={}
industrialtest.internal.chargepads={}

local function chargePlayer(meta,player,flow)
	local inv
	if industrialtest.mtgAvailable then
		_,inv=armor:get_valid_player(player,"")
		if not inv then
			return false
		end
	elseif industrialtest.mclAvailable then
		inv=player:get_inventory()
	end

	local armorList=inv:get_list("armor")
	local chargedSlots={}
	for i,stack in ipairs(armorList) do
		local stackMeta=stack:get_meta()
		if industrialtest.api.hasPowerStorage(stackMeta) and not industrialtest.api.isFullyCharged(stackMeta) then
			table.insert(chargedSlots,{
				index=i,
				stack=stack
			})
		end
	end
	local wielded=player:get_wielded_item()
	if not wielded:is_empty() then
		local wieldedMeta=wielded:get_meta()
		if industrialtest.api.hasPowerStorage(wieldedMeta) and not industrialtest.api.isFullyCharged(wieldedMeta) then
			table.insert(chargedSlots,{
				stack=wielded
			})
		end
	end

	if #chargedSlots==0 then
		return false
	end
	local distribution=math.min(flow,meta:get_int("industrialtest.powerAmount"))/#chargedSlots

	for _,chargedSlot in ipairs(chargedSlots) do
		industrialtest.api.transferPowerToItem(meta,chargedSlot.stack,distribution)
		if chargedSlot.index then
			inv:set_stack("armor",chargedSlot.index,chargedSlot.stack)
		else
			player:set_wielded_item(chargedSlot.stack)
		end
	end

	return true
end

chargepad.getFormspec=function(pos)
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

chargepad.onConstruct=function(pos,meta,inv)
	inv:set_size("charged",1)
	inv:set_size("discharged",1)
	meta:set_int("active",0)
end

chargepad.action=function(pos,node)
	local meta=minetest.get_meta(pos)
	local inv=meta:get_inventory()
	local chargedSlot=inv:get_stack("charged",1)
	local dischargedSlot=inv:get_stack("discharged",1)
	local _,shouldUpdateFormspec=industrialtest.api.powerFlow(pos)
	local flow=meta:get_int("industrialtest.powerFlow")

	if chargedSlot:get_count()>0 and meta:get_int("industrialtest.powerAmount")>0 and industrialtest.api.transferPowerToItem(meta,chargedSlot,flow)>0 then
		inv:set_stack("charged",1,chargedSlot)
		shouldUpdateFormspec=true
	end
	if dischargedSlot:get_count()>0 and not industrialtest.api.isFullyCharged(meta) and industrialtest.api.transferPowerFromItem(dischargedSlot,meta,flow)>0 then
		inv:set_stack("discharged",1,dischargedSlot)
		shouldUpdateFormspec=true
	end

	local players=minetest.get_connected_players()
	local p1=vector.offset(pos,-0.5,0,-0.5)
	local p2=vector.offset(pos,0.5,2,0.5)
	local playerFound=false
	for _,player in ipairs(players) do
		if vector.in_area(player:get_pos(),p1,p2) then
			playerFound=true
			shouldUpdateFormspec=shouldUpdateFormspec or chargePlayer(meta,player,flow)
			break
		end
	end
	local active=meta:get_int("active")==1
	if playerFound and not active then
		minetest.swap_node(pos,{
			name=node.name.."_active",
			param2=node.param2
		})
		meta:set_int("active",1)
	elseif (not playerFound or meta:get_int("industrialtest.powerAmount")==0) and active then
		local def=minetest.registered_nodes[node.name]
		minetest.swap_node(pos,{
			name=def._industrialtest_baseNodeName,
			param2=node.param2
		})
		meta:set_int("active",0)
	end

	if shouldUpdateFormspec then
		local def=minetest.registered_nodes[node.name]
		def._industrialtest_updateFormspec(pos)
	end
end

local function registerChargepad(config)
	industrialtest.internal.registerMachine({
		name=config.name,
		displayName=config.displayName,
		capacity=config.capacity,
		flow=config.flow,
		ioConfig="iiiioi",
		sounds=config.sounds,
		powerSlots={"charged","discharged"},
		storageSlots={"charged","discharged"},
		requiresWrench=config.requiresWrench,
		registerActiveVariant=true,
		groups={
			_industrialtest_hasPowerOutput=1,
			_industrialtest_hasPowerInput=1
		},
		customKeys={
			tiles={
				config.machineBlockTexture.."^industrialtest_chargepad_top.png",
				config.machineBlockTexture,
				config.machineBlockTexture,
				config.machineBlockTexture,
				config.machineBlockTexture,
				config.machineBlockTexture.."^"..config.frontTexture
			},
			paramtype2="facedir",
			legacy_facedir_simple=true
		},
		activeCustomKeys={
			tiles={
				config.machineBlockTexture.."^industrialtest_chargepad_top_active.png",
				config.machineBlockTexture,
				config.machineBlockTexture,
				config.machineBlockTexture,
				config.machineBlockTexture,
				config.machineBlockTexture.."^"..config.frontTexture
			},
			_industrialtest_baseNodeName="industrialtest:"..config.name
		},
		getFormspec=chargepad.getFormspec,
		onConstruct=chargepad.onConstruct
	})
	minetest.register_craft({
		type="shaped",
		output="industrialtest:"..config.name,
		recipe={
			{"industrialtest:electronic_circuit",industrialtest.elementKeys.stoneSlab,"industrialtest:electronic_circuit"},
			{industrialtest.elementKeys.rubber,"industrialtest:"..config.basePowerStorage,industrialtest.elementKeys.rubber}
		}
	})
	table.insert(industrialtest.internal.chargepads,"industrialtest:"..config.name)
	table.insert(industrialtest.internal.chargepads,"industrialtest:"..config.name.."_active")
end

registerChargepad({
	name="batbox_chargepad",
	displayName=S("BatBox Chargepad"),
	capacity=25000,
	flow=industrialtest.api.lvPowerFlow,
	sounds="wood",
	machineBlockTexture="industrialtest_wood_machine_block.png",
	frontTexture="industrialtest_batbox_front.png",
	requiresWrench=false,
	basePowerStorage="batbox"
})

registerChargepad({
	name="cesu_chargepad",
	displayName=S("CESU Chargepad"),
	capacity=400000,
	flow=industrialtest.api.mvPowerFlow,
	sounds="metal",
	machineBlockTexture="industrialtest_bronze_machine_block.png",
	frontTexture="industrialtest_cesu_front.png",
	requiresWrench=false,
	basePowerStorage="cesu"
})

registerChargepad({
	name="mfe_chargepad",
	displayName=S("MFE Chargepad"),
	capacity=3000000,
	flow=industrialtest.api.hvPowerFlow,
	sounds="metal",
	machineBlockTexture="industrialtest_machine_block.png",
	frontTexture="industrialtest_mfe_front.png",
	requiresWrench=true,
	basePowerStorage="mfe"
})

registerChargepad({
	name="mfsu_chargepad",
	displayName=S("MFSU Chargepad"),
	capacity=30000000,
	flow=industrialtest.api.evPowerFlow,
	sounds="metal",
	machineBlockTexture="industrialtest_advanced_machine_block.png",
	frontTexture="industrialtest_mfsu_front.png",
	requiresWrench=true,
	basePowerStorage="mfsu"
})

minetest.register_abm({
	label="Chargepad updating",
	nodenames=industrialtest.internal.chargepads,
	interval=industrialtest.updateDelay,
	chance=1,
	action=chargepad.action
})
