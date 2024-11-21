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
local massFabricator={}

industrialtest.internal.registerSimpleElectricItemProcessor({
	name="mass_fabricator",
	displayName=S("Mass Fabricator"),
	capacity=100000,
	requiresWrench=true,
	flow=industrialtest.api.evPowerFlow,
	opPower=10000,
	machineBlockTexture="industrialtest_advanced_machine_block.png",
	customFrontTexture=true,
	method="industrialtest.mass_fabricating",
	efficiency=1
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:mass_fabricator",
	recipe={
		{industrialtest.elementKeys.yellowDust,"industrialtest:advanced_circuit",industrialtest.elementKeys.yellowDust},
		{"industrialtest:advanced_machine_block","industrialtest:lapotron_crystal","industrialtest:advanced_machine_block"},
		{industrialtest.elementKeys.yellowDust,"industrialtest:advanced_circuit",industrialtest.elementKeys.yellowDust}
	}
})
