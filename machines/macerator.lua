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

industrialtest.internal.registerSimpleElectricItemProcessor({
	name="macerator",
	displayName=S("Macerator"),
	customFrontTexture=true,
	requiresWrench=true,
	capacity=1200,
	flow=industrialtest.api.lvPowerFlow,
	opPower=100,
	method="industrialtest.macerating",
	efficiency=1
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:macerator",
	recipe={
		{industrialtest.elementKeys.flint,industrialtest.elementKeys.flint,industrialtest.elementKeys.flint},
		{industrialtest.elementKeys.cobble,"industrialtest:machine_block",industrialtest.elementKeys.cobble},
		{"","industrialtest:electronic_circuit",""}
	}
})
