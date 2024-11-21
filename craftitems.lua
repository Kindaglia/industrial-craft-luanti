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
local colors={
	bronze="#be4325ff",
	clay="#707070ff",
	coal="#262523ff",
	copper="#bf644aff",
	diamond="#77cefbff",
	gold="#eac162ff",
	iron="#afaca5ff",
	lapis_lazuli="#3a4cceff",
	lead="#6d6393ff",
	mese="#909000ff",
	obsidian="#292843ff",
	refined_iron="#94bab9ff",
	sulfur="#b88805ff",
	tin="#ebd182ff",
	uranium="#3b8c09ff",
	-- fluid colors
	lava="#ff5712ff",
	water="#277bbcff",
	river_water="#0ebfc2ff",
	biomass="#2a8626ff",
	biofuel="#4eba49ff",
	coalfuel="#462228ff",
	coolant="#188676ff"
}

-- Power storage items
minetest.register_tool("industrialtest:re_battery",{
	description=S("RE-Battery"),
	inventory_image="industrialtest_re_battery.png",
	_industrialtest_powerStorage=true,
	_industrialtest_powerCapacity=7000,
	_industrialtest_powerFlow=industrialtest.api.lvPowerFlow
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:re_battery",
	recipe={
		{"","industrialtest:insulated_tin_cable",""},
		{industrialtest.elementKeys.tinIngot,industrialtest.elementKeys.powerCarrier,industrialtest.elementKeys.tinIngot},
		{industrialtest.elementKeys.tinIngot,industrialtest.elementKeys.powerCarrier,industrialtest.elementKeys.tinIngot}
	}
})

minetest.register_tool("industrialtest:advanced_re_battery",{
	description=S("Advanced RE-Battery"),
	inventory_image="industrialtest_advanced_re_battery.png",
	_industrialtest_powerStorage=true,
	_industrialtest_powerCapacity=100000,
	_industrialtest_powerFlow=industrialtest.api.mvPowerFlow
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:advanced_re_battery",
	recipe={
		{"industrialtest:insulated_copper_cable",industrialtest.elementKeys.bronzeIngot,"industrialtest:insulated_copper_cable"},
		{industrialtest.elementKeys.bronzeIngot,"industrialtest:sulfur_dust",industrialtest.elementKeys.bronzeIngot},
		{industrialtest.elementKeys.bronzeIngot,"industrialtest:lead_dust",industrialtest.elementKeys.bronzeIngot}
	}
})

minetest.register_tool("industrialtest:energy_crystal",{
	description=S("Energy Crystal"),
	inventory_image="industrialtest_energy_crystal.png",
	_industrialtest_powerStorage=true,
	_industrialtest_powerCapacity=100000,
	_industrialtest_powerFlow=industrialtest.api.hvPowerFlow
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:energy_crystal",
	recipe={
		{industrialtest.elementKeys.powerCarrier,industrialtest.elementKeys.powerCarrier,industrialtest.elementKeys.powerCarrier},
		{industrialtest.elementKeys.powerCarrier,industrialtest.elementKeys.diamond,industrialtest.elementKeys.powerCarrier},
		{industrialtest.elementKeys.powerCarrier,industrialtest.elementKeys.powerCarrier,industrialtest.elementKeys.powerCarrier}
	}
})

minetest.register_tool("industrialtest:lapotron_crystal",{
	description=S("Lapotron Crystal"),
	inventory_image="industrialtest_lapotron_crystal.png",
	_industrialtest_powerStorage=true,
	_industrialtest_powerCapacity=1000000,
	_industrialtest_powerFlow=industrialtest.api.evPowerFlow
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:lapotron_crystal",
	recipe={
		{industrialtest.elementKeys.blueDye,"industrialtest:electronic_circuit",industrialtest.elementKeys.blueDye},
		{industrialtest.elementKeys.blueDye,"industrialtest:energy_crystal",industrialtest.elementKeys.blueDye},
		{industrialtest.elementKeys.blueDye,"industrialtest:electronic_circuit",industrialtest.elementKeys.blueDye}
	}
})

-- Other resources
minetest.register_craftitem("industrialtest:refined_iron_ingot",{
	description=S("Refined Iron Ingot"),
	inventory_image="industrialtest_"..industrialtest.gameTexturePrefix.."_refined_iron_ingot.png",
})
minetest.register_craft({
	type="cooking",
	output="industrialtest:refined_iron_ingot",
	recipe=industrialtest.elementKeys.ironIngot
})
minetest.register_craft({
	type="cooking",
	output="industrialtest:refined_iron_ingot",
	recipe="industrialtest:refined_iron_dust"
})
minetest.register_craft({
	type="shapeless",
	output="industrialtest:refined_iron_ingot 8",
	recipe={
		"industrialtest:machine_block"
	}
})

minetest.register_craftitem("industrialtest:mixed_metal_ingot",{
	description=S("Mixed Metal Ingot"),
	inventory_image="industrialtest_"..industrialtest.gameTexturePrefix.."_mixed_metal_ingot.png"
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:mixed_metal_ingot",
	recipe={
		{"industrialtest:refined_iron_ingot","industrialtest:refined_iron_ingot","industrialtest:refined_iron_ingot",},
		{industrialtest.elementKeys.bronzeIngot,industrialtest.elementKeys.bronzeIngot,industrialtest.elementKeys.bronzeIngot},
		{industrialtest.elementKeys.tinIngot,industrialtest.elementKeys.tinIngot,industrialtest.elementKeys.tinIngot}
	}
})

if not industrialtest.mods.mclRubber then
	minetest.register_craftitem("industrialtest:sticky_resin",{
		description=S("Sticky Resin"),
		inventory_image="industrialtest_sticky_resin.png"
	})

	minetest.register_craftitem("industrialtest:rubber",{
		description=S("Rubber"),
		inventory_image="industrialtest_rubber.png"
	})
	minetest.register_craft({
		type="cooking",
		output="industrialtest:rubber",
		recipe="industrialtest:sticky_resin"
	})
end
industrialtest.api.registerExtractorRecipe({
	output=industrialtest.elementKeys.rubber,
	recipe=industrialtest.elementKeys.rubberWood
})
industrialtest.api.registerExtractorRecipe({
	output=industrialtest.elementKeys.rubber,
	recipe=industrialtest.elementKeys.rubberSapling
})
industrialtest.api.registerExtractorRecipe({
	output=industrialtest.elementKeys.rubber.." 3",
	recipe=industrialtest.elementKeys.stickyResin
})

minetest.register_craftitem("industrialtest:raw_carbon_fibre",{
	description=S("Raw Carbon Fibre"),
	inventory_image="industrialtest_raw_carbon_fibre.png"
})
minetest.register_craft({
	type="shapeless",
	output="industrialtest:raw_carbon_fibre",
	recipe={
		"industrialtest:coal_dust",
		"industrialtest:coal_dust",
		"industrialtest:coal_dust",
		"industrialtest:coal_dust"
	}
})

minetest.register_craftitem("industrialtest:raw_carbon_mesh",{
	description=S("Raw Carbon Mesh"),
	inventory_image="industrialtest_raw_carbon_mesh.png"
})
minetest.register_craft({
	type="shapeless",
	output="industrialtest:raw_carbon_mesh",
	recipe={
		"industrialtest:raw_carbon_fibre",
		"industrialtest:raw_carbon_fibre"
	}
})

-- Dust
local resources={
	{
		resource=industrialtest.elementKeys.coalBlock,
		count=9
	},
	{
		resource=industrialtest.elementKeys.stoneWithCoal,
		count=2
	},
	{resource=industrialtest.elementKeys.coal}
}
if industrialtest.mclAvailable then
	table.insert(resources,{
		resource="mcl_deepslate:deepslate_with_coal",
		count=2
	})
end
industrialtest.api.registerResourceDust("coal","Coal",resources,colors.coal,true)
industrialtest.api.registerResourceDust("clay","Clay",{
	{
		resource=industrialtest.elementKeys.clayBlock,
		count=2
	}
},colors.clay,true)
resources={
	{
		resource=industrialtest.elementKeys.diamondBlock,
		count=9
	},
	{
		resource=industrialtest.elementKeys.stoneWithDiamond,
		count=2
	},
	{resource=industrialtest.elementKeys.diamond}
}
if industrialtest.mclAvailable then
	table.insert(resources,{
		resource="mcl_deepslate:deepslate_with_diamond",
		count=2
	})
end
industrialtest.api.registerResourceDust("diamond","Diamond",resources,colors.diamond,true)
minetest.register_craft({
	type="cooking",
	output=industrialtest.elementKeys.diamond,
	recipe="industrialtest:diamond_dust"
})
resources={
	{
		resource=industrialtest.elementKeys.ironBlock,
		count=9
	},
	{
		resource=industrialtest.elementKeys.stoneWithIron,
		count=2
	},
	{
		resource=industrialtest.elementKeys.ironLump,
		count=2
	},
	{resource=industrialtest.elementKeys.ironIngot}
}
if industrialtest.mclAvailable then
	table.insert(resources,{
		resource="mcl_deepslate:deepslate_with_iron",
		count=2
	})
end
industrialtest.api.registerResourceDust("iron","Iron",resources,colors.iron,true)
minetest.register_craft({
	type="cooking",
	output=industrialtest.elementKeys.ironIngot,
	recipe="industrialtest:iron_dust"
})
if industrialtest.mclAvailable then
	industrialtest.api.registerResourceDust("lapis_lazuli","Lapis Lazuli",{
		{
			resource="mcl_core:lapislazuliblock",
			count=9
		},
		{
			resource="mcl_core:stone_with_lapis_lazuli",
			count=2
		},
		{
			resource="mcl_deepslate:deepslate_with_lapis_lazuli",
			count=9
		},
		{resource="mcl_core:lapis_lazuli"}
	},colors.lapis_lazuli,true)
end
industrialtest.api.registerResourceDust("obsidian","Obsidian",{{resource=industrialtest.elementKeys.obsidian}},colors.obsidian,true)
resources={
	{
		resource=industrialtest.elementKeys.goldBlock,
		count=9
	},
	{
		resource=industrialtest.elementKeys.stoneWithGold,
		count=2
	},
	{
		resource=industrialtest.elementKeys.goldLump,
		count=2
	},
	{resource=industrialtest.elementKeys.goldIngot}
}
if industrialtest.mclAvailable then
	table.insert(resources,{
		resource="mcl_deepslate:deepslate_with_gold",
		count=2
	})
end
industrialtest.api.registerResourceDust("gold","Gold",resources,colors.gold,true)
minetest.register_craft({
	type="cooking",
	output=industrialtest.elementKeys.goldIngot,
	recipe="industrialtest:gold_dust"
})
resources={
	{
		resource=industrialtest.elementKeys.copperBlock,
		count=9
	},
	{
		resource=industrialtest.elementKeys.stoneWithCopper,
		count=2
	},
	{
		resource=industrialtest.elementKeys.copperLump,
		count=2
	},
	{resource=industrialtest.elementKeys.copperIngot}
}
if industrialtest.mclAvailable then
	table.insert(resources,{
		resource="mcl_deepslate:deepslate_with_copper",
		count=2
	})
end
industrialtest.api.registerResourceDust("copper","Copper",resources,colors.copper,true)
minetest.register_craft({
	type="cooking",
	output=industrialtest.elementKeys.copperIngot,
	recipe="industrialtest:copper_dust"
})
resources={
	{
		resource=industrialtest.elementKeys.tinBlock,
		count=9
	},
	{
		resource=industrialtest.elementKeys.stoneWithTin,
		count=2
	},
	{
		resource=industrialtest.elementKeys.tinLump,
		count=2
	},
	{resource=industrialtest.elementKeys.tinIngot}
}
if industrialtest.mclAvailable then
	table.insert(resources,{
		resource="industrialtest:deepslate_with_tin",
		count=2
	})
end
industrialtest.api.registerResourceDust("tin","Tin",resources,colors.tin,true)
minetest.register_craft({
	type="cooking",
	output=industrialtest.elementKeys.tinIngot,
	recipe="industrialtest:tin_dust"
})
resources={
	{
		resource="industrialtest:uranium_block",
		count=9
	},
	{
		resource="industrialtest:stone_with_uranium",
		count=2
	},
	{
		resource=industrialtest.elementKeys.uraniumLump,
		count=2
	},
	{resource="industrialtest:uranium_ingot"}
}
if industrialtest.mclAvailable then
	table.insert(resources,{
		resource="industrialtest:deepslate_with_uranium",
		count=2
	})
end
industrialtest.api.registerResourceDust("uranium","Uranium",resources,colors.uranium,true)
minetest.register_craft({
	type="cooking",
	output="industrialtest:uranium_ingot",
	recipe="industrialtest:uranium_dust"
})
if industrialtest.mtgAvailable then
	industrialtest.api.registerResourceDust("mese","Mese",{
		{
			resource="default:mese",
			count=9
		},
		{
			resource="default:stone_with_mese",
			count=2
		},
		{resource="default:mese_crystal"}
	},colors.mese,true)
	minetest.register_craft({
		type="cooking",
		output="default:mese_crystal",
		recipe="industrialtest:mese_dust"
	})
end
industrialtest.api.registerResourceDust("bronze","Bronze",{
	{
		resource=industrialtest.elementKeys.bronzeBlock,
		count=9
	},
	{resource=industrialtest.elementKeys.bronzeIngot}
},colors.bronze,true)
minetest.register_craft({
	type="shaped",
	output="industrialtest:bronze_dust 9",
	recipe={
		{"industrialtest:copper_dust","industrialtest:copper_dust","industrialtest:copper_dust"},
		{"industrialtest:copper_dust","industrialtest:tin_dust","industrialtest:copper_dust"},
		{"industrialtest:copper_dust","industrialtest:copper_dust","industrialtest:copper_dust"}
	}
})
minetest.register_craft({
	type="cooking",
	output=industrialtest.elementKeys.bronzeIngot,
	recipe="industrialtest:bronze_dust"
})
industrialtest.api.registerRotaryMaceratorModifier({
	name=industrialtest.elementKeys.copperLump,
	modifier=industrialtest.elementKeys.tinLump,
	output="industrialtest:bronze_dust 2",
	uses=4
})
industrialtest.api.registerRotaryMaceratorModifier({
	name=industrialtest.elementKeys.copperIngot,
	modifier=industrialtest.elementKeys.tinIngot,
	output="industrialtest:bronze_dust",
	uses=4
})
industrialtest.api.registerResourceDust("sulfur","Sulfur",{},colors.sulfur,false)
industrialtest.api.registerExtractorRecipe({
	output="industrialtest:sulfur_dust",
	recipe=industrialtest.elementKeys.gunpowder
})
industrialtest.api.registerResourceDust("lead","Lead",{
	{
		resource="industrialtest:lead_block",
		count=9
	},
	{
		resource="industrialtest:lead_ore",
		count=2
	},
	{
		resource=industrialtest.elementKeys.leadLump,
		count=2
	},
	{resource="industrialtest:lead_ingot"}
},colors.lead,true)
minetest.register_craft({
	type="cooking",
	output="industrialtest:lead_ingot",
	recipe="industrialtest:lead_dust"
})
industrialtest.api.registerResourceDust("refined_iron","Refined Iron",{
	{
		resource="industrialtest:refined_iron_ingot",
		count=1
	}
},colors.refined_iron,true)
industrialtest.api.registerRotaryMaceratorModifier({
	name=industrialtest.elementKeys.ironLump,
	modifier=industrialtest.elementKeys.coal,
	output="industrialtest:refined_iron_dust 2",
	uses=industrialtest.stackMax
})

minetest.register_craftitem("industrialtest:hydrated_coal_dust",{
	description=S("Hydrated Coal Dust"),
	inventory_image="industrialtest_hydrated_coal_dust.png"
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:hydrated_coal_dust 8",
	recipe={
		{"industrialtest:coal_dust","industrialtest:coal_dust","industrialtest:coal_dust"},
		{"industrialtest:coal_dust",industrialtest.elementKeys.bucketWithWater,"industrialtest:coal_dust"},
		{"industrialtest:coal_dust","industrialtest:coal_dust","industrialtest:coal_dust"}
	},
	replacements={
		{
			industrialtest.elementKeys.bucketWithWater,
			industrialtest.elementKeys.bucket
		}
	}
})
minetest.register_craft({
	type="shapeless",
	output="industrialtest:hydrated_coal_dust",
	recipe={
		"industrialtest:coal_dust",
		industrialtest.elementKeys.bucketWithWater
	},
	replacements={
		{
			industrialtest.elementKeys.bucketWithWater,
			industrialtest.elementKeys.bucket
		}
	}
})
industrialtest.api.registerRotaryMaceratorModifier({
	name=industrialtest.elementKeys.coal,
	modifier="industrialtest:water_cell",
	output="industrialtest:hydrated_coal_dust",
	uses=8
})

minetest.register_craftitem("industrialtest:hydrated_coal",{
	description=S("Hydrated Coal"),
	inventory_image="industrialtest_hydrated_coal.png"
})
industrialtest.api.registerCompressorRecipe({
	output="industrialtest:hydrated_coal",
	recipe="industrialtest:hydrated_coal_dust"
})

-- Plates
industrialtest.api.registerPlate("bronze_plate",S("Bronze Plate"),{
	{
		resource=industrialtest.elementKeys.bronzeIngot,
		count=1
	}
},colors.bronze,true)

industrialtest.api.registerPlate("copper_plate",S("Copper Plate"),{
	{
		resource=industrialtest.elementKeys.copperIngot,
		count=1
	}
},colors.copper,true)

industrialtest.api.registerPlate("advanced_alloy",S("Advanced Alloy"),{
	{
		resource="industrialtest:mixed_metal_ingot",
		count=1
	}
},"#908372ff",true)

industrialtest.api.registerPlate("carbon_plate",S("Carbon Plate"),{
	{
		resource="industrialtest:raw_carbon_mesh",
		count=1
	}
},"#272725ff",true)

industrialtest.api.registerPlate("tin_plate",S("Tin Plate"),{
	{
		resource=industrialtest.elementKeys.tinIngot,
		count=1
	}
},colors.tin,true)

industrialtest.api.registerPlate("lead_plate",S("Lead Plate"),{
	{
		resource="industrialtest:lead_ingot",
		count=1
	}
},colors.lead,true)

industrialtest.api.registerPlate("iridium_plate",S("Iridium Plate"),{},false,"#ffffffff")
minetest.register_craft({
	type="shaped",
	output="industrialtest:iridium_plate",
	recipe={
		{"industrialtest:iridium_ingot","industrialtest:advanced_alloy","industrialtest:iridium_ingot"},
		{"industrialtest:advanced_alloy",industrialtest.elementKeys.diamond,"industrialtest:advanced_alloy"},
		{"industrialtest:iridium_ingot","industrialtest:advanced_alloy","industrialtest:iridium_ingot"}
	}
})

-- Cells
minetest.register_craftitem("industrialtest:empty_cell",{
	description=S("Empty Cell"),
	inventory_image="industrialtest_empty_cell.png",
	liquids_pointable=true,
	on_place=function(itemstack,user,pointed)
		if pointed.type~="node" or not user or not user:is_player() then
			return nil
		end
		local node=minetest.get_node_or_nil(pointed.under)
		if not node then
			return nil
		end
		local storage=industrialtest.api.getStorageCellByNode(node.name)
		if not storage then
			return nil
		end
		if itemstack:get_count()==1 then
			itemstack:set_name(storage.name)
		else
			local inv=user:get_inventory()
			inv:add_item("main",ItemStack(storage.name))
			itemstack:take_item()
		end
		minetest.remove_node(pointed.under)
		return itemstack
	end
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:empty_cell 16",
	recipe={
		{"",industrialtest.elementKeys.tinIngot,""},
		{industrialtest.elementKeys.tinIngot,"",industrialtest.elementKeys.tinIngot},
		{"",industrialtest.elementKeys.tinIngot,""}
	}
})
industrialtest.api.registerStorageCell("water","Water",industrialtest.elementKeys.waterSource,nil,colors.water)
if industrialtest.mtgAvailable then
	industrialtest.api.registerStorageCell("river_water","River Water","default:river_water_source",nil,colors.river_water)
end

industrialtest.api.registerStorageCell("lava","Lava",industrialtest.elementKeys.lavaSource,nil,colors.lava)

minetest.register_tool("industrialtest:uranium_cell",{
	description=S("Uranium Cell"),
	groups={
		_industrialtest_placedInNuclearReactor=1,
		_industrialtest_nuclearReactorFuel=1
	},
	inventory_image="industrialtest_cell_fluid.png",
	inventory_overlay="industrialtest_cell_casing.png",
	color=colors.uranium,
})
minetest.register_craft({
	type="shapeless",
	output="industrialtest:uranium_cell",
	recipe={
		"industrialtest:empty_cell",
		"industrialtest:uranium_ingot"
	}
})

minetest.register_tool("industrialtest:coolant_cell",{
	description=S("Coolant Cell"),
	groups={
		_industrialtest_placedInNuclearReactor=1,
		_industrialtest_nuclearReactorCoolant=1
	},
	inventory_image="industrialtest_cell_fluid.png",
	inventory_overlay="industrialtest_cell_casing.png",
	color=colors.coolant,
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:coolant_cell 16",
	recipe={
		{"",industrialtest.elementKeys.tinIngot,""},
		{industrialtest.elementKeys.tinIngot,"industrialtest:water_cell",industrialtest.elementKeys.tinIngot},
		{"",industrialtest.elementKeys.tinIngot,""}
	}
})
if industrialtest.mtgAvailable then
	minetest.register_craft({
		type="shaped",
		output="industrialtest:coolant_cell 16",
		recipe={
			{"",industrialtest.elementKeys.tinIngot,""},
			{industrialtest.elementKeys.tinIngot,"industrialtest:river_water_cell",industrialtest.elementKeys.tinIngot},
			{"",industrialtest.elementKeys.tinIngot,""}
		}
	})
end

minetest.register_craftitem("industrialtest:bio_cell",{
	description=S("Bio Cell"),
	inventory_image="industrialtest_cell_fluid.png",
	inventory_overlay="industrialtest_cell_casing.png",
	color=colors.biomass,
})
minetest.register_craft({
	type="shapeless",
	output="industrialtest:bio_cell",
	recipe={
		"industrialtest:empty_cell",
		"industrialtest:compressed_plantball"
	}
})

minetest.register_craftitem("industrialtest:biofuel_cell",{
	description=S("Biofuel Cell"),
	inventory_image="industrialtest_cell_fluid.png",
	inventory_overlay="industrialtest_cell_casing.png",
	color=colors.biofuel,
	groups={
		_industrialtest_fuel=1
	},
	_industrialtest_fuelAmount=500,
	_industrialtest_emptyVariant="industrialtest:empty_cell"
})
industrialtest.api.registerExtractorRecipe({
	output="industrialtest:biofuel_cell",
	recipe="industrialtest:bio_cell",
	time=4
})

minetest.register_craftitem("industrialtest:hydrated_coal_cell",{
	description=S("Hydrated Coal Cell"),
	inventory_image="industrialtest_cell_fluid.png",
	inventory_overlay="industrialtest_cell_casing.png",
	color=colors.coal,
})
minetest.register_craft({
	type="shapeless",
	output="industrialtest:hydrated_coal_cell",
	recipe={
		"industrialtest:empty_cell",
		"industrialtest:hydrated_coal"
	}
})

minetest.register_craftitem("industrialtest:coalfuel_cell",{
	description=S("Coalfuel Cell"),
	inventory_image="industrialtest_cell_fluid.png",
	inventory_overlay="industrialtest_cell_casing.png",
	color=colors.coalfuel,
	groups={
		_industrialtest_fuel=1
	},
	_industrialtest_fuelAmount=1000,
	_industrialtest_emptyVariant="industrialtest:empty_cell"
})
industrialtest.api.registerExtractorRecipe({
	output="industrialtest:coalfuel_cell",
	recipe="industrialtest:hydrated_coal_cell",
	time=4
})

-- Other items
minetest.register_craftitem("industrialtest:electronic_circuit",{
	description=S("Electronic Circuit"),
	inventory_image="industrialtest_electronic_circuit.png"
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:electronic_circuit",
	recipe={
		{"industrialtest:insulated_copper_cable","industrialtest:insulated_copper_cable","industrialtest:insulated_copper_cable"},
		{industrialtest.elementKeys.powerCarrier,"industrialtest:refined_iron_ingot",industrialtest.elementKeys.powerCarrier},
		{"industrialtest:insulated_copper_cable","industrialtest:insulated_copper_cable","industrialtest:insulated_copper_cable"}
	}
})

minetest.register_craftitem("industrialtest:advanced_electronic_circuit",{
	description=S("Advanced Electronic Circuit"),
	inventory_image="industrialtest_advanced_electronic_circuit.png"
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:advanced_electronic_circuit",
	recipe={
		{industrialtest.elementKeys.powerCarrier,industrialtest.elementKeys.yellowDust,industrialtest.elementKeys.powerCarrier},
		{industrialtest.elementKeys.blueDye,"industrialtest:electronic_circuit",industrialtest.elementKeys.blueDye},
		{industrialtest.elementKeys.powerCarrier,industrialtest.elementKeys.yellowDust,industrialtest.elementKeys.powerCarrier}
	}
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:advanced_electronic_circuit",
	recipe={
		{industrialtest.elementKeys.powerCarrier,industrialtest.elementKeys.blueDye,industrialtest.elementKeys.powerCarrier},
		{industrialtest.elementKeys.yellowDust,"industrialtest:electronic_circuit",industrialtest.elementKeys.yellowDust},
		{industrialtest.elementKeys.powerCarrier,industrialtest.elementKeys.blueDye,industrialtest.elementKeys.powerCarrier}
	}
})

minetest.register_craftitem("industrialtest:scrap",{
	description=S("Scrap"),
	inventory_image="industrialtest_scrap.png"
})

minetest.register_craftitem("industrialtest:uu_matter",{
	description=S("UU-Matter"),
	inventory_image="industrialtest_uu_matter.png"
})

minetest.register_craftitem("industrialtest:plantball",{
	description=S("Plantball"),
	inventory_image="industrialtest_plantball.png"
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:plantball 2",
	recipe={
		{industrialtest.elementKeys.groupSapling,industrialtest.elementKeys.groupSapling,industrialtest.elementKeys.groupSapling},
		{industrialtest.elementKeys.groupSapling,"",industrialtest.elementKeys.groupSapling},
		{industrialtest.elementKeys.groupSapling,industrialtest.elementKeys.groupSapling,industrialtest.elementKeys.groupSapling}
	}
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:plantball",
	recipe={
		{industrialtest.elementKeys.groupLeaves,industrialtest.elementKeys.groupLeaves,industrialtest.elementKeys.groupLeaves},
		{industrialtest.elementKeys.groupLeaves,"",industrialtest.elementKeys.groupLeaves},
		{industrialtest.elementKeys.groupLeaves,industrialtest.elementKeys.groupLeaves,industrialtest.elementKeys.groupLeaves}
	}
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:plantball",
	recipe={
		{industrialtest.elementKeys.sugarCane,industrialtest.elementKeys.sugarCane,industrialtest.elementKeys.sugarCane},
		{industrialtest.elementKeys.sugarCane,"",industrialtest.elementKeys.sugarCane},
		{industrialtest.elementKeys.sugarCane,industrialtest.elementKeys.sugarCane,industrialtest.elementKeys.sugarCane}
	}
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:plantball",
	recipe={
		{industrialtest.elementKeys.wheat,industrialtest.elementKeys.wheat,industrialtest.elementKeys.wheat},
		{industrialtest.elementKeys.wheat,"",industrialtest.elementKeys.wheat},
		{industrialtest.elementKeys.wheat,industrialtest.elementKeys.wheat,industrialtest.elementKeys.wheat}
	}
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:plantball",
	recipe={
		{industrialtest.elementKeys.dryShrub,industrialtest.elementKeys.dryShrub,industrialtest.elementKeys.dryShrub},
		{industrialtest.elementKeys.dryShrub,"",industrialtest.elementKeys.dryShrub},
		{industrialtest.elementKeys.dryShrub,industrialtest.elementKeys.dryShrub,industrialtest.elementKeys.dryShrub}
	}
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:plantball",
	recipe={
		{industrialtest.elementKeys.cactus,industrialtest.elementKeys.cactus,industrialtest.elementKeys.cactus},
		{industrialtest.elementKeys.cactus,"",industrialtest.elementKeys.cactus},
		{industrialtest.elementKeys.cactus,industrialtest.elementKeys.cactus,industrialtest.elementKeys.cactus}
	}
})

minetest.register_craftitem("industrialtest:compressed_plantball",{
	description=S("Compressed Plantball"),
	inventory_image="industrialtest_compressed_plantball.png"
})
industrialtest.api.registerCompressorRecipe({
	output="industrialtest:compressed_plantball",
	recipe="industrialtest:plantball",
	time=5
})

minetest.register_tool("industrialtest:fuel_can",{
	description=S("Fuel Can"),
	inventory_image="industrialtest_fuel_can.png",
	groups={
		_industrialtest_fueled=1,
		_industrialtest_fuel=1,
		_industrialtest_fluidStorage=1
	},
	_industrialtest_fluidCapacity=10000
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:fuel_can",
	recipe={
		{"","industrialtest:tin_plate","industrialtest:tin_plate"},
		{"industrialtest:tin_plate","","industrialtest:tin_plate"},
		{"industrialtest:tin_plate","industrialtest:tin_plate","industrialtest:tin_plate"}
	}
})

-- Item callbacks
minetest.register_on_player_inventory_action(function(player,action,inventory,info)
	if action=="put" then
		if industrialtest.api.preparePowerStorageItem(info.stack) or industrialtest.api.prepareToolItem(info.stack) or industrialtest.api.prepareFluidStorageItem(info.stack) then
			inventory:set_stack(info.listname,info.index,info.stack)
		end
	end
end)
minetest.register_on_craft(function(itemstack)
	if industrialtest.api.preparePowerStorageItem(itemstack) or industrialtest.api.prepareToolItem(itemstack) then
		return
	end
	industrialtest.api.prepareFluidStorageItem(itemstack)
end)
