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

industrialtest.internal.applyUpgrade=function(pos,meta,stack)
	local def=minetest.registered_items[stack:get_name()]
	if def.groups._industrialtest_upgradeSpeed then
		local speed=industrialtest.api.getMachineSpeed(meta)
		meta:set_int("industrialtest.speed",math.min(4,speed+def.groups._industrialtest_upgradeSpeed))
	elseif def.groups._industrialtest_upgradeTransformer then
		local flows={
			industrialtest.api.lvPowerFlow,
			industrialtest.api.mvPowerFlow,
			industrialtest.api.hvPowerFlow,
			industrialtest.api.evPowerFlow,
			industrialtest.api.ivPowerFlow
		}
		local machineFlow=meta:get_int("industrialtest.powerFlow")
		local upgradedFlow=machineFlow
		for _,flow in ipairs(flows) do
			if flow>machineFlow then
				upgradedFlow=flow
				break
			end
		end
		meta:set_int("industrialtest.powerFlow",upgradedFlow)
		local networks=industrialtest.api.isAttachedToNetwork(meta)
		if networks then
			for _,network in ipairs(networks) do
				industrialtest.api.createNetworkMapForNode(network)
			end
		end
	elseif def.groups._industrialtest_upgradePowerStorage then
		meta:set_int("industrialtest.powerCapacity",meta:get_int("industrialtest.powerCapacity")+10000)
		local nodeDef=minetest.registered_nodes[minetest.get_node(pos).name]
		if nodeDef._industrialtest_updateFormspec then
			nodeDef._industrialtest_updateFormspec(pos)
		end
		local networks=industrialtest.api.isAttachedToNetwork(meta)
		if networks then
			for _,network in ipairs(networks) do
				minetest.get_node_timer(network):start(industrialtest.updateDelay)
			end
		end
	end
end

industrialtest.internal.removeUpgrade=function(pos,meta,stack)
	local def=minetest.registered_items[stack:get_name()]
	if def.groups._industrialtest_upgradeSpeed and meta:contains("industrialtest.speed") then
		local speed=meta:get_int("industrialtest.speed")
		meta:set_int("industrialtest.speed",math.max(1,speed-def.groups._industrialtest_upgradeSpeed))
	elseif def.groups._industrialtest_upgradeTransformer then
		local flows={
			industrialtest.api.lvPowerFlow,
			industrialtest.api.mvPowerFlow,
			industrialtest.api.hvPowerFlow,
			industrialtest.api.evPowerFlow,
			industrialtest.api.ivPowerFlow
		}
		local machineFlow=meta:get_int("industrialtest.powerFlow")
		local downgradedFlow=machineFlow
		for i=#flows,1,-1 do
			local flow=flows[i]
			if flow<machineFlow then
				downgradedFlow=flow
				break
			end
		end
		meta:set_int("industrialtest.powerFlow",downgradedFlow)
		local networks=industrialtest.api.isAttachedToNetwork(meta)
		if networks then
			for _,network in ipairs(networks) do
				minetest.get_node_timer(network):start(industrialtest.updateDelay)
			end
		end
	elseif def.groups._industrialtest_upgradePowerStorage then
		meta:set_int("industrialtest.powerCapacity",meta:get_int("industrialtest.powerCapacity")-10000)
		meta:set_int("industrialtest.powerAmount",math.min(meta:get_int("industrialtest.powerAmount"),meta:get_int("industrialtest.powerCapacity")))
		local nodeDef=minetest.registered_nodes[minetest.get_node(pos).name]
		if nodeDef._industrialtest_updateFormspec then
			nodeDef._industrialtest_updateFormspec(pos)
		end
	end
end

local function registerMachineUpgrade(config)
	minetest.register_craftitem("industrialtest:"..config.name,{
		description=config.displayName,
		inventory_image="industrialtest_"..config.name..".png",
		groups={
			_industrialtest_machineUpgrade=1,
			_industrialtest_upgradeSpeed=config.speed or nil,
			_industrialtest_upgradeTransformer=config.transformer or nil,
			_industrialtest_upgradePowerStorage=config.powerStorage or nil,
		}
	})
end

registerMachineUpgrade({
	name="overclocker_upgrade",
	displayName=S("Overclocker Upgrade"),
	speed=1
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:overclocker_upgrade",
	recipe={
		{"industrialtest:coolant_cell","industrialtest:coolant_cell","industrialtest:coolant_cell"},
		{"industrialtest:insulated_copper_cable","industrialtest:electronic_circuit","industrialtest:insulated_copper_cable"}
	}
})

registerMachineUpgrade({
	name="transformer_upgrade",
	displayName=S("Transformer Upgrade"),
	transformer=1
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:transformer_upgrade",
	recipe={
		{industrialtest.elementKeys.glass,industrialtest.elementKeys.glass,industrialtest.elementKeys.glass},
		{"industrialtest:insulated_gold_cable","industrialtest:mv_transformer","industrialtest:insulated_gold_cable"},
		{industrialtest.elementKeys.glass,"industrialtest:electronic_circuit",industrialtest.elementKeys.glass}
	}
})

registerMachineUpgrade({
	name="power_storage_upgrade",
	displayName=S("Power Storage Upgrade"),
	powerStorage=1
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:power_storage_upgrade",
	recipe={
		{"group:wood","group:wood","group:wood"},
		{"industrialtest:insulated_copper_cable","industrialtest:re_battery","industrialtest:insulated_copper_cable"},
		{"group:wood","industrialtest:electronic_circuit","group:wood"}
	}
})
