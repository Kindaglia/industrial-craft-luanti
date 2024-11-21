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
local transformer={}

transformer.onPowerFlow=function(pos,side,amount)
	local normalized=industrialtest.api.normalizeSide(pos,side)
	local def=minetest.registered_nodes[minetest.get_node(pos).name]
	if normalized~=5 and amount>def._industrialtest_lowerFlow then
		minetest.remove_node(pos)
		industrialtest.internal.explode(pos,2)
	end
end

transformer.onTimer=function(pos,elapsed,meta)
	local powerAmount=meta:get_int("industrialtest.powerAmount")
	local def=minetest.registered_nodes[minetest.get_node(pos).name]
	local afterFlowLower=false
	local afterFlowUpper=false
	if powerAmount>=def._industrialtest_lowerFlow then
		afterFlowLower,_=industrialtest.api.powerFlow(pos,{
			[1]=true,
			[2]=true,
			[3]=true,
			[4]=true,
			[6]=true
		},def._industrialtest_lowerFlow)
	end
	if powerAmount>=def._industrialtest_upperFlow then
		afterFlowUpper,_=industrialtest.api.powerFlow(pos,{[5]=true},def._industrialtest_upperFlow)
	end
	return powerAmount>0 and (afterFlowLower or afterFlowUpper),false
end

local function registerTransformer(config)
	industrialtest.internal.registerMachine({
		name=config.name,
		displayName=config.displayName,
		capacity=industrialtest.api.ivPowerFlow,
		flow=industrialtest.api.ivPowerFlow,
		ioConfig="aaaaaa",
		storageSlots={},
		powerSlots={},
		sounds=config.sounds,
		groups={
			_industrialtest_hasPowerOutput=1,
			_industrialtest_hasPowerInput=1,
		},
		customKeys={
			tiles={
				config.machineBlockTexture.."^industrialtest_"..config.name.."_side.png",
				config.machineBlockTexture.."^industrialtest_"..config.name.."_side.png",
				config.machineBlockTexture.."^industrialtest_"..config.name.."_side.png",
				config.machineBlockTexture.."^industrialtest_"..config.name.."_side.png",
				config.machineBlockTexture.."^industrialtest_"..config.name.."_side.png",
				config.machineBlockTexture.."^industrialtest_"..config.name.."_front.png"
			},
			paramtype2="facedir",
			legacy_facedir_simple=true,
			_industrialtest_lowerFlow=config.lowerFlow,
			_industrialtest_upperFlow=config.upperFlow,
			_industrialtest_onPowerFlow=transformer.onPowerFlow
		},
		requiresWrench=config.requiresWrench,
		withoutFormspec=true,
		onTimer=transformer.onTimer
	})
end

registerTransformer({
	name="lv_transformer",
	displayName=S("LV Transformer"),
	machineBlockTexture="industrialtest_wood_machine_block.png",
	requiresWrench=false,
	lowerFlow=industrialtest.api.lvPowerFlow,
	upperFlow=industrialtest.api.mvPowerFlow,
	sounds="wood"
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:lv_transformer",
	recipe={
		{"group:wood","industrialtest:insulated_tin_cable","group:wood"},
		{industrialtest.elementKeys.copperIngot,industrialtest.elementKeys.copperIngot,industrialtest.elementKeys.copperIngot},
		{"group:wood","industrialtest:insulated_copper_cable","group:wood"}
	}
})

registerTransformer({
	name="mv_transformer",
	displayName=S("MV Transformer"),
	machineBlockTexture="industrialtest_machine_block.png",
	requiresWrench=true,
	lowerFlow=industrialtest.api.mvPowerFlow,
	upperFlow=industrialtest.api.hvPowerFlow,
	sounds="metal"
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:mv_transformer",
	recipe={
		{"industrialtest:insulated_copper_cable"},
		{"industrialtest:machine_block"},
		{"industrialtest:insulated_gold_cable"}
	}
})

registerTransformer({
	name="hv_transformer",
	displayName=S("HV Transformer"),
	machineBlockTexture="industrialtest_machine_block.png",
	requiresWrench=true,
	lowerFlow=industrialtest.api.hvPowerFlow,
	upperFlow=industrialtest.api.evPowerFlow,
	sounds="metal"
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:hv_transformer",
	recipe={
		{"","industrialtest:insulated_iron_cable",""},
		{"industrialtest:electronic_circuit","industrialtest:mv_transformer","industrialtest:energy_crystal"},
		{"","industrialtest:insulated_iron_cable",""}
	}
})

registerTransformer({
	name="ev_transformer",
	displayName=S("EV Transformer"),
	machineBlockTexture="industrialtest_machine_block.png",
	requiresWrench=true,
	lowerFlow=industrialtest.api.evPowerFlow,
	upperFlow=industrialtest.api.ivPowerFlow,
	sounds="metal"
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:ev_transformer",
	recipe={
		{"","industrialtest:insulated_iron_cable",""},
		{"industrialtest:advanced_electronic_circuit","industrialtest:hv_transformer","industrialtest:lapotron_crystal"},
		{"","industrialtest:insulated_iron_cable",""}
	}
})
