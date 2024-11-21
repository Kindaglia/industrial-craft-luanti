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

-- Macerator crafts
industrialtest.api.registerMaceratorRecipe({
	output=industrialtest.elementKeys.cobble,
	recipe=industrialtest.elementKeys.stone
})
industrialtest.api.registerMaceratorRecipe({
	output=industrialtest.elementKeys.sand,
	recipe=industrialtest.elementKeys.cobble
})
industrialtest.api.registerMaceratorRecipe({
	output=industrialtest.elementKeys.flint,
	recipe=industrialtest.elementKeys.gravel
})
industrialtest.api.registerMaceratorRecipe({
	output=industrialtest.elementKeys.snowball,
	recipe=industrialtest.elementKeys.ice
})
industrialtest.api.registerMaceratorRecipe({
	output=industrialtest.elementKeys.sand,
	recipe=industrialtest.elementKeys.sandstone
})
industrialtest.api.registerMaceratorRecipe({
	output=industrialtest.elementKeys.string.." 2",
	recipe=industrialtest.elementKeys.whiteWool
})
if industrialtest.mclAvailable then
	industrialtest.api.registerMaceratorRecipe({
		output="mcl_mobitems:blaze_powder 5",
		recipe="mcl_mobitems:blaze_rod"
	})
	industrialtest.api.registerMaceratorRecipe({
		output="mesecons:mesecon 9",
		recipe="mesecons_torch:redstoneblock"
	})
	industrialtest.api.registerMaceratorRecipe({
		output="mcl_nether:quartz 4",
		recipe="mcl_nether:quartz_block"
	})
	industrialtest.api.registerMaceratorRecipe({
		output="mcl_bone_meal:bone_meal 4",
		recipe="mcl_mobitems:bone"
	})
end

-- Compressor crafts
industrialtest.api.registerCompressorRecipe({
	output=industrialtest.elementKeys.sandstone,
	recipe=industrialtest.elementKeys.sand
})
industrialtest.api.registerCompressorRecipe({
	output=industrialtest.elementKeys.ice,
	recipe=industrialtest.elementKeys.snowball
})
if industrialtest.mclAvailable then
	industrialtest.api.registerCompressorRecipe({
		output="mcl_nether:nether_brick",
		recipe="mcl_nether:netherrack",
		count=3
	})
end

-- Geothermal Generator fuels
industrialtest.api.registerGeothermalGeneratorFuel({
	name=industrialtest.elementKeys.lavaSource,
	calorificValue=industrialtest.api.lvPowerFlow*2,
	texture="industrialtest_gui_lava.png",
	storageItems={
		{
			name=industrialtest.elementKeys.bucketWithLava,
			leftover=industrialtest.elementKeys.bucket
		},
		{
			name="industrialtest:lava_cell",
			leftover="industrialtest:empty_cell"
		}
	}
})

-- Water Mill fuels
industrialtest.api.registerWaterMillFuel({
	name=industrialtest.elementKeys.waterSource,
	calorificValue=industrialtest.api.lvPowerFlow,
	texture="industrialtest_gui_water.png",
	storageItems={
		{
			name=industrialtest.elementKeys.bucketWithWater,
			leftover=industrialtest.elementKeys.bucket
		},
		{
			name="industrialtest:water_cell",
			leftover="industrialtest:empty_cell"
		}
	}
})
if industrialtest.mtgAvailable then
	industrialtest.api.registerWaterMillFuel({
		name="default:river_water_source",
		calorificValue=industrialtest.api.lvPowerFlow,
		texture="industrialtest_gui_river_water.png",
		storageItems={
			{
				name="bucket:bucket_river_water",
				leftover=industrialtest.elementKeys.bucket
			},
			{
				name="industrialtest:river_water_cell",
				leftover="industrialtest:empty_cell"
			}
		}
	})
end
