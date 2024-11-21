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

local electricDrill={}

electricDrill.afterUse=function(itemstack,config)
	local meta=itemstack:get_meta()
	industrialtest.api.addPowerToItem(itemstack,-20)
	if meta:get_int("industrialtest.powerAmount")<20 then
		itemstack:set_name("industrialtest:"..config.name)
	end
	return itemstack
end

local function registerElectricDrill(config)
	local definition={
		description=config.displayName,
		inventory_image="industrialtest_"..config.name..".png",
		after_use=function()
			-- Hack to make sure that drill won't be destroyed when has 0 EU
			return nil
		end,
		_industrialtest_powerStorage=true,
		_industrialtest_powerCapacity=10000,
		_industrialtest_powerFlow=industrialtest.api.lvPowerFlow,
		_industrialtest_inactiveName="industrialtest:"..config.name
	}
	if industrialtest.mtgAvailable then
		definition.tool_capabilities={
			full_punch_interval=0.5,
			max_drop_level=config.maxDropLevel,
			groupcaps={
				cracky={
					times=config.inactiveTimes,
					maxlevel=config.maxLevel
				},
				crumbly={
					times=config.inactiveTimes,
					maxlevel=config.maxLevel
				}
			}
		}
		definition.groups={
			pickaxe=1,
			shovel=1
		}
	elseif industrialtest.mclAvailable then
		definition.tool_capabilities={
			full_punch_interval=0.5,
			max_drop_level=config.maxDropLevel
		}
		definition.groups={
			tool=1,
			dig_speed_class=config.digSpeedClass
		}
		definition._mcl_diggroups={
			pickaxey={
				speed=config.inactiveDigSpeed,
				level=config.digLevel,
				uses=-1
			},
			shovely={
				speed=config.inactiveDigSpeed,
				level=config.digLevel,
				uses=-1
			}
		}
		definition._mcl_toollike_wield=true
	end
	minetest.register_tool("industrialtest:"..config.name,definition)
	definition=table.copy(definition)
	if industrialtest.mtgAvailable then
		definition.tool_capabilities.groupcaps.cracky.times=config.activeTimes
		definition.tool_capabilities.groupcaps.crumbly.times=config.activeTimes
	elseif industrialtest.mclAvailable then
		definition._mcl_diggroups.pickaxey.speed=config.activeDigSpeed
		definition._mcl_diggroups.shovely.speed=config.activeDigSpeed
	end
	definition.groups.not_in_creative_inventory=1
	definition.after_use=function(itemstack)
		return electricDrill.afterUse(itemstack,config)
	end
	minetest.register_tool("industrialtest:"..config.name.."_active",definition)
	industrialtest.internal.registeredElectricDrills["industrialtest:"..config.name]=true
	industrialtest.internal.registeredElectricDrills["industrialtest:"..config.name.."_active"]=true
end
local definition={
	name="electric_drill",
	displayName=S("Electric Drill")
}
if industrialtest.mtgAvailable then
	definition.maxDropLevel=1
	definition.inactiveTimes={[1]=10,[2]=5.6,[3]=4}
	definition.maxLevel=2
	definition.activeTimes={[1]=2.0,[2]=0.8,[3]=0.4}
elseif industrialtest.mclAvailable then
	definition.digSpeedClass=4
	definition.maxDropLevel=4
	definition.inactiveDigSpeed=1
	definition.digLevel=4
	definition.activeDigSpeed=7
end
registerElectricDrill(definition)
minetest.register_craft({
	type="shaped",
	output="industrialtest:electric_drill",
	recipe={
		{"","industrialtest:refined_iron_ingot",""},
		{"industrialtest:refined_iron_ingot","industrialtest:electronic_circuit","industrialtest:refined_iron_ingot"},
		{"industrialtest:refined_iron_ingot","industrialtest:re_battery","industrialtest:refined_iron_ingot"}
	}
})
definition={
	name="diamond_electric_drill",
	displayName=S("Diamond Electric Drill")
}
if industrialtest.mtgAvailable then
	definition.maxDropLevel=1
	definition.inactiveTimes={[1]=10,[2]=5.6,[3]=4}
	definition.maxLevel=3
	definition.activeTimes={[1]=2.0,[2]=0.8,[3]=0.4}
elseif industrialtest.mclAvailable then
	definition.digSpeedClass=5
	definition.maxDropLevel=5
	definition.inactiveDigSpeed=1
	definition.digLevel=5
	definition.activeDigSpeed=9
end
registerElectricDrill(definition)
minetest.register_craft({
	type="shaped",
	output="industrialtest:diamond_electric_drill",
	recipe={
		{"",industrialtest.elementKeys.diamond,""},
		{industrialtest.elementKeys.diamond,"industrialtest:electric_drill",industrialtest.elementKeys.diamond}
	}
})
