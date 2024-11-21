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

local electricSaber={}

electricSaber.afterUse=function(itemstack,config)
	local meta=itemstack:get_meta()
	industrialtest.api.addPowerToItem(itemstack,-20)
	if meta:get_int("industrialtest.powerAmount")<20 then
		itemstack:set_name("industrialtest:"..config.name)
	end
	return itemstack
end

local function registerElectricSaber(config)
	local definition={
		description=config.displayName,
		inventory_image="industrialtest_"..config.name..".png",
		after_use=function()
			-- Hack to make sure that saber won't be destroyed when has 0 EU
			return nil
		end,
		_industrialtest_powerStorage=true,
		_industrialtest_powerCapacity=10000,
		_industrialtest_powerFlow=industrialtest.api.lvPowerFlow,
		_industrialtest_inactiveName="industrialtest:"..config.name
	}
	if industrialtest.mtgAvailable then
		definition.groups={
			sword=1
		}
		definition.tool_capabilities={
			full_punch_interval=0.5,
			max_drop_level=config.maxDropLevel,
			groupcaps={
				snappy={
					times=config.inactiveTimes,
					maxlevel=config.maxLevel
				}
			},
			damage_groups={fleshy=config.inactiveDamage}
		}
	elseif industrialtest.mclAvailable then
		definition.groups={
			weapon=1,
			sword=1,
			dig_speed_class=config.digSpeedClass
		}
		definition.tool_capabilities={
			full_punch_interval=0.5,
			max_drop_level=config.maxDropLevel,
			damage_groups={fleshy=config.inactiveDamage}
		}
		definition._mcl_toollike_wield=true
		definition._mcl_diggroups={
			swordy={
				speed=config.inactiveDigSpeed,
				level=config.digLevel,
				uses=-1
			},
			swordy_cobweb={
				speed=config.inactiveDigSpeed,
				level=config.digLevel,
				uses=-1
			}
		}
	end
	minetest.register_tool("industrialtest:"..config.name,definition)
	definition=table.copy(definition)
	if industrialtest.mtgAvailable then
		definition.tool_capabilities.groupcaps.snappy.times=config.activeTimes
		definition.tool_capabilities.damage_groups.fleshy=config.activeDamage
	elseif industrialtest.mclAvailable then
		definition.tool_capabilities.damage_groups.fleshy=config.activeDamage
		definition._mcl_diggroups.swordy.speed=config.activeDigSpeed
		definition._mcl_diggroups.swordy_cobweb.speed=config.activeDigSpeed
	end
	definition.groups.not_in_creative_inventory=1
	definition.after_use=function(itemstack)
		return electricSaber.afterUse(itemstack,config)
	end
	minetest.register_tool("industrialtest:"..config.name.."_active",definition)
	industrialtest.internal.registeredElectricSabers["industrialtest:"..config.name]=true
	industrialtest.internal.registeredElectricSabers["industrialtest:"..config.name.."_active"]=true
end
local definition={
	name="electric_saber",
	displayName=S("Electric Saber")
}
if industrialtest.mtgAvailable then
	definition.maxDropLevel=1
	definition.inactiveTimes={[1]=10,[2]=5.6,[3]=4}
	definition.maxLevel=3
	definition.inactiveDamage=1
	definition.activeTimes={[1]=2.0,[2]=0.8,[3]=0.4}
	definition.activeDamage=6
elseif industrialtest.mclAvailable then
	definition.digSpeedClass=4
	definition.maxDropLevel=4
	definition.inactiveDamage=1
	definition.inactiveDigSpeed=1
	definition.digLevel=4
	definition.activeDamage=6
	definition.activeDigSpeed=7
end
registerElectricSaber(definition)
minetest.register_craft({
	type="shaped",
	output="industrialtest:electric_saber",
	recipe={
		{"industrialtest:refined_iron_ingot"},
		{"industrialtest:refined_iron_ingot"},
		{"industrialtest:re_battery"}
	}
})
definition={
	name="diamond_electric_saber",
	displayName=S("Diamond Electric Saber")
}
if industrialtest.mtgAvailable then
	definition.maxDropLevel=1
	definition.inactiveTimes={[1]=10,[2]=5.6,[3]=4}
	definition.maxLevel=3
	definition.inactiveDamage=1
	definition.activeTimes={[1]=2.0,[2]=0.8,[3]=0.4}
	definition.activeDamage=9
elseif industrialtest.mclAvailable then
	definition.digSpeedClass=5
	definition.maxDropLevel=5
	definition.inactiveDamage=1
	definition.inactiveDigSpeed=1
	definition.digLevel=5
	definition.activeDamage=9
	definition.activeDigSpeed=9
end
registerElectricSaber(definition)
minetest.register_craft({
	type="shapeless",
	output="industrialtest:diamond_electric_saber",
	recipe={
		"industrialtest:electric_saber",
		industrialtest.elementKeys.diamond,
		industrialtest.elementKeys.diamond
	}
})

minetest.register_on_punchplayer(function(player,hitter)
	local itemstack=hitter:get_wielded_item()
	if industrialtest.internal.registeredElectricSabers[itemstack:get_name()] then
		local meta=itemstack:get_meta()
		if meta:get_int("industrialtest.powerAmount")>=20 then
			industrialtest.api.addPowerToItem(itemstack,-20)
			hitter:set_wielded_item(itemstack)
			local def=minetest.registered_tools[itemstack:get_name().."_active"]
			player:set_hp(player:get_hp()-def.tool_capabilites.damage_groups.fleshy)
			return true
		end
	end
	return false
end)
