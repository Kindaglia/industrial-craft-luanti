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

MODNAME="industrialtest"
local modpath=minetest.get_modpath(MODNAME)

-- table with global functions, variables etc
industrialtest={}

-- Initial constants
industrialtest.updateDelay=1 -- Note: Make this value smaller to make machines update more frequently (it may make server more laggy)
industrialtest.developerMode=true -- Enables additional utils useful when developing mod

-- Others
industrialtest.random=PseudoRandom(os.time())

-- load other lua files
dofile(modpath.."/compatibility.lua")
dofile(modpath.."/api.lua")
dofile(modpath.."/minerals.lua")

dofile(modpath.."/machines/common.lua")
dofile(modpath.."/machines/canning_machine.lua")
dofile(modpath.."/machines/chargepad.lua")
dofile(modpath.."/machines/compressor.lua")
dofile(modpath.."/machines/cable_former.lua")
dofile(modpath.."/machines/electric_furnace.lua")
dofile(modpath.."/machines/extractor.lua")
dofile(modpath.."/machines/fluid_generator.lua")
dofile(modpath.."/machines/generator.lua")
dofile(modpath.."/machines/induction_furnace.lua")
dofile(modpath.."/machines/iron_furnace.lua")
dofile(modpath.."/machines/macerator.lua")
dofile(modpath.."/machines/mass_fabricator.lua")
dofile(modpath.."/machines/nuclear_reactor.lua")
dofile(modpath.."/machines/power_storage.lua")
dofile(modpath.."/machines/recycler.lua")
dofile(modpath.."/machines/rotary_macerator.lua")
dofile(modpath.."/machines/tool_workshop.lua")
dofile(modpath.."/machines/transformer.lua")
dofile(modpath.."/machines/solar_panel_generator.lua")
dofile(modpath.."/machines/wind_mill.lua")

dofile(modpath.."/tools/common.lua")
dofile(modpath.."/tools/batpack.lua")
dofile(modpath.."/tools/electric_chainsaw.lua")
dofile(modpath.."/tools/electric_drill.lua")
dofile(modpath.."/tools/electric_hoe.lua")
dofile(modpath.."/tools/electric_saber.lua")
dofile(modpath.."/tools/jetpack.lua")
dofile(modpath.."/tools/mining_laser.lua")
dofile(modpath.."/tools/nano_suit.lua")
dofile(modpath.."/tools/solar_helmet.lua")
dofile(modpath.."/tools/static_boots.lua")
dofile(modpath.."/tools/treetap.lua")
dofile(modpath.."/tools/quantum_suit.lua")
dofile(modpath.."/tools/wrench.lua")

dofile(modpath.."/upgrades.lua")
dofile(modpath.."/craftitems.lua")
dofile(modpath.."/nodes.lua")
if industrialtest.developerMode then
	dofile(modpath.."/utils.lua")
end
dofile(modpath.."/cables.lua")
dofile(modpath.."/mapgen.lua")
dofile(modpath.."/uu_matter_crafts.lua")
dofile(modpath.."/crafts.lua")

-- compatibility with other mods
if industrialtest.mods.pipeworks then
	dofile(modpath.."/compat/pipeworks.lua")
end
if industrialtest.mods.mesecons then
	dofile(modpath.."/compat/mesecons.lua")
end
