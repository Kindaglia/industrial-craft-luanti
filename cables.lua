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
local cable={}

cable.onConstruct=function(pos)
	local connections=industrialtest.api.getConnections(pos)
	for _,conn in ipairs(connections) do
		local meta=minetest.get_meta(conn)
		if industrialtest.api.isNetworkMaster(meta) then
			industrialtest.api.createNetworkMapForNode(conn)
		else
			local networks=industrialtest.api.isAttachedToNetwork(meta)
			if networks then
				for _,network in ipairs(networks) do
					industrialtest.api.createNetworkMapForNode(network)
					minetest.get_node_timer(network):start(industrialtest.updateDelay)
				end
			end
		end
	end
end

cable.onDestruct=function(pos)
	local meta=minetest.get_meta(pos)
	local networks=industrialtest.api.isAttachedToNetwork(meta)
	if networks then
		for _,network in ipairs(networks) do
			industrialtest.api.createNetworkMapForNode(network,pos)
		end
	end
end

local function registerCable(name,displayName,size,flow,registerInsulated)
	local definition={
		description=S(displayName.." Cable"),
		inventory_image="industrialtest_"..name.."_cable_inv.png",
		tiles={"industrialtest_"..name.."_cable.png"},
		wield_image="industrialtest_"..name.."_cable_inv.png",
		paramtype="light",
		sunlight_propagates=true,
		drawtype="nodebox",
		node_box={
			type="connected",
			fixed={
				-size,
				-size,
				-size,
				size,
				size,
				size
			},
			connect_top={
				-size,
				-size,
				-size,
				size,
				0.5,
				size
			},
			connect_bottom={
				-size,
				-0.5,
				-size,
				size,
				size,
				size
			},
			connect_front={
				-size,
				-size,
				-0.5,
				size,
				size,
				size,
			},
			connect_left={
				-0.5,
				-size,
				-size,
				size,
				size,
				size
			},
			connect_back={
				-size,
				-size,
				-size,
				size,
				size,
				0.5
			},
			connect_right={
				-size,
				-size,
				-size,
				0.5,
				size,
				size
			}
		},
		connects_to={
			"group:_industrialtest_hasPowerInput",
			"group:_industrialtest_hasPowerOutput",
			"group:_industrialtest_cable"
		},
		on_construct=cable.onConstruct,
		on_destruct=cable.onDestruct,
		_industrialtest_cableFlow=flow
	}
	if industrialtest.mtgAvailable then
		definition.groups={
			cracky=1,
			level=1,
			oddly_breakable_by_hand=1
		}
		definition.sound=default.node_sound_metal_defaults()
	elseif industrialtest.mclAvailable then
		definition.groups={
			handy=1,
			pickaxey=1
		}
		definition._mcl_blast_resistance=1
		definition._mcl_hardness=0.5
		definition.sound=mcl_sounds.node_sound_metal_defaults()
	end
	definition.groups._industrialtest_cable=1
	minetest.register_node("industrialtest:"..name.."_cable",definition)
	if registerInsulated then
		definition=table.copy(definition)
		definition.description=S("Insulated "..displayName.." Cable")
		definition.inventory_image="industrialtest_insulated_"..name.."_cable_inv.png"
		definition.tiles={"industrialtest_insulated_"..name.."_cable.png"}
		definition.wield_image="industrialtest_insulated_"..name.."_cable_inv.png"
		minetest.register_node("industrialtest:insulated_"..name.."_cable",definition)
	end
end

registerCable("tin","Tin",0.19,industrialtest.api.lvPowerFlow,true)
minetest.register_craft({
	type="shaped",
	output="industrialtest:tin_cable 6",
	recipe={
		{industrialtest.elementKeys.tinIngot,industrialtest.elementKeys.tinIngot,industrialtest.elementKeys.tinIngot}
	}
})
minetest.register_craft({
	type="shapeless",
	output="industrialtest:insulated_tin_cable",
	recipe={
		"industrialtest:tin_cable",
		industrialtest.elementKeys.rubber
	}
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:insulated_tin_cable 6",
	recipe={
		{industrialtest.elementKeys.rubber,industrialtest.elementKeys.rubber,industrialtest.elementKeys.rubber},
		{industrialtest.elementKeys.tinIngot,industrialtest.elementKeys.tinIngot,industrialtest.elementKeys.tinIngot},
		{industrialtest.elementKeys.rubber,industrialtest.elementKeys.rubber,industrialtest.elementKeys.rubber}
	}
})
industrialtest.api.registerCableFormerRecipe({
	output="industrialtest:tin_cable 12",
	recipe=industrialtest.elementKeys.tinIngot,
	time=1
})

registerCable("copper","Copper",0.15,industrialtest.api.mvPowerFlow,true)
minetest.register_craft({
	type="shaped",
	output="industrialtest:copper_cable 6",
	recipe={
		{industrialtest.elementKeys.copperIngot,industrialtest.elementKeys.copperIngot,industrialtest.elementKeys.copperIngot}
	}
})
minetest.register_craft({
	type="shapeless",
	output="industrialtest:insulated_copper_cable",
	recipe={
		"industrialtest:copper_cable",
		industrialtest.elementKeys.rubber
	}
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:insulated_copper_cable 6",
	recipe={
		{industrialtest.elementKeys.rubber,industrialtest.elementKeys.rubber,industrialtest.elementKeys.rubber},
		{industrialtest.elementKeys.copperIngot,industrialtest.elementKeys.copperIngot,industrialtest.elementKeys.copperIngot},
		{industrialtest.elementKeys.rubber,industrialtest.elementKeys.rubber,industrialtest.elementKeys.rubber}
	}
})
industrialtest.api.registerCableFormerRecipe({
	output="industrialtest:copper_cable 12",
	recipe=industrialtest.elementKeys.copperIngot
})

registerCable("gold","Gold",0.15,industrialtest.api.hvPowerFlow,true)
minetest.register_craft({
	type="shaped",
	output="industrialtest:gold_cable 6",
	recipe={
		{industrialtest.elementKeys.goldIngot,industrialtest.elementKeys.goldIngot,industrialtest.elementKeys.goldIngot}
	}
})
minetest.register_craft({
	type="shapeless",
	output="industrialtest:insulated_gold_cable",
	recipe={
		"industrialtest:gold_cable",
		industrialtest.elementKeys.rubber
	}
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:insulated_gold_cable 6",
	recipe={
		{industrialtest.elementKeys.rubber,industrialtest.elementKeys.rubber,industrialtest.elementKeys.rubber},
		{industrialtest.elementKeys.goldIngot,industrialtest.elementKeys.goldIngot,industrialtest.elementKeys.goldIngot},
		{industrialtest.elementKeys.rubber,industrialtest.elementKeys.rubber,industrialtest.elementKeys.rubber}
	}
})
industrialtest.api.registerCableFormerRecipe({
	output="industrialtest:gold_cable 12",
	recipe=industrialtest.elementKeys.goldIngot
})

registerCable("iron","Iron",0.15,industrialtest.api.evPowerFlow,true)
minetest.register_craft({
	type="shaped",
	output="industrialtest:iron_cable 6",
	recipe={
		{"industrialtest:refined_iron_ingot","industrialtest:refined_iron_ingot","industrialtest:refined_iron_ingot"}
	}
})
minetest.register_craft({
	type="shapeless",
	output="industrialtest:insulated_iron_cable",
	recipe={
		"industrialtest:iron_cable",
		industrialtest.elementKeys.rubber
	}
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:insulated_iron_cable 6",
	recipe={
		{industrialtest.elementKeys.rubber,industrialtest.elementKeys.rubber,industrialtest.elementKeys.rubber},
		{"industrialtest:refined_iron_ingot","industrialtest:refined_iron_ingot","industrialtest:refined_iron_ingot"},
		{industrialtest.elementKeys.rubber,industrialtest.elementKeys.rubber,industrialtest.elementKeys.rubber}
	}
})
industrialtest.api.registerCableFormerRecipe({
	output="industrialtest:iron_cable 12",
	recipe="industrialtest:refined_iron_ingot",
	time=3
})

registerCable("glass_fibre","Glass Fibre",0.15,industrialtest.api.ivPowerFlow,false)
minetest.register_craft({
	type="shaped",
	output="industrialtest:glass_fibre_cable 4",
	recipe={
		{industrialtest.elementKeys.glass,industrialtest.elementKeys.glass,industrialtest.elementKeys.glass},
		{industrialtest.elementKeys.powerCarrier,industrialtest.elementKeys.diamond,industrialtest.elementKeys.powerCarrier},
		{industrialtest.elementKeys.glass,industrialtest.elementKeys.glass,industrialtest.elementKeys.glass}
	}
})
-- TODO: Add glass fibre cable craft with silver ingot
