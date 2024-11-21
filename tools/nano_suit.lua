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

local function registerNanoSuitPart(config)
	local groups={
		_industrialtest_nanoSuit=1
	}
	if config.element=="head" then
		groups.armor_head=1
	elseif config.element=="torso" then
		groups.armor_torso=1
	elseif config.element=="legs" then
		groups.armor_legs=1
	elseif config.element=="feet" then
		groups.armor_feet=1
	end
	if industrialtest.mtgAvailable then
		groups.armor_heal=0
		armor:register_armor("industrialtest:"..config.name,{
			description=config.displayName,
			inventory_image="industrialtest_"..config.name.."_inv.png",
			groups=groups,
			_industrialtest_powerStorage=true,
			_industrialtest_powerCapacity=1000000,
			_industrialtest_powerFlow=industrialtest.api.evPowerFlow,
			_industrialtest_damageReduction=config.damageReduction,
			industrialtest_powerPerDamage=5000
		})
	elseif industrialtest.mclAvailable then
		groups.armor=1
		groups.non_combat_armor=1
		minetest.register_tool("industrialtest:"..config.name,{
			description=config.displayName,
			inventory_image="industrialtest_"..config.name.."_inv.png",
			groups=groups,
			sounds={
				_mcl_armor_equip="mcl_armor_equip_iron",
				_mcl_armor_unequip="mcl_armor_unequip_iron"
			},
			on_place=mcl_armor.equip_on_use,
			on_secondary_use=mcl_armor.equip_on_use,
			_mcl_armor_element=config.element,
			_mcl_armor_texture=(config.element=="feet" and "industrialtest_mcl_" or "industrialtest_")..config.name..".png",
			_industrialtest_powerStorage=true,
			_industrialtest_powerCapacity=1000000,
			_industrialtest_powerFlow=industrialtest.api.evPowerFlow,
			_industrialtest_damageReduction=config.damageReduction,
			_industrialtest_powerPerDamage=5000
		})
	end
end

registerNanoSuitPart({
	name="nano_helmet",
	displayName=S("Nano Helmet"),
	element="head",
	damageReduction=0.12
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:nano_helmet",
	recipe={
		{"industrialtest:carbon_plate","industrialtest:energy_crystal","industrialtest:carbon_plate"},
		{"industrialtest:carbon_plate",industrialtest.elementKeys.glass,"industrialtest:carbon_plate"}
	}
})

registerNanoSuitPart({
	name="nano_bodyarmor",
	displayName=S("Nano Bodyarmor"),
	element="torso",
	damageReduction=0.32
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:nano_bodyarmor",
	recipe={
		{"industrialtest:carbon_plate","","industrialtest:carbon_plate"},
		{"industrialtest:carbon_plate","industrialtest:energy_crystal","industrialtest:carbon_plate"},
		{"industrialtest:carbon_plate","industrialtest:carbon_plate","industrialtest:carbon_plate"}
	}
})

registerNanoSuitPart({
	name="nano_leggings",
	displayName=S("Nano Leggings"),
	element="legs",
	damageReduction=0.3
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:nano_leggings",
	recipe={
		{"industrialtest:carbon_plate","industrialtest:energy_crystal","industrialtest:carbon_plate"},
		{"industrialtest:carbon_plate","","industrialtest:carbon_plate"},
		{"industrialtest:carbon_plate","","industrialtest:carbon_plate"}
	}
})

registerNanoSuitPart({
	name="nano_boots",
	displayName=S("Nano Boots"),
	element="feet",
	damageReduction=0.24
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:nano_boots",
	recipe={
		{"industrialtest:carbon_plate","","industrialtest:carbon_plate"},
		{"industrialtest:carbon_plate","industrialtest:energy_crystal","industrialtest:carbon_plate"}
	}
})

minetest.register_on_player_hpchange(function(player,hpChange)
	if hpChange>0 or not player:is_player() then
		return hpChange
	end

	local inv
	if industrialtest.mtgAvailable then
		_,inv=armor:get_valid_player(player,"")
		if not inv then
			return hpChange
		end
	elseif industrialtest.mclAvailable then
		inv=player:get_inventory()
	end

	local armorList=inv:get_list("armor")
	assert(armorList)
	local result=hpChange
	for i=1,#armorList do
		local stack=armorList[i]
		local def=stack:get_definition()
		if def.groups and def.groups._industrialtest_nanoSuit then
			local meta=stack:get_meta()
			local targetReducedDamage=math.floor(math.abs(hpChange)*def._industrialtest_damageReduction)
			local requiredPower=targetReducedDamage*def._industrialtest_powerPerDamage
			local availablePower=math.min(meta:get_int("industrialtest.powerAmount"),requiredPower)
			local reducedDamage=math.floor(availablePower/def._industrialtest_powerPerDamage)
			if reducedDamage>0 then
				result=result+reducedDamage
				industrialtest.api.addPowerToItem(stack,-reducedDamage*def._industrialtest_powerPerDamage)
				inv:set_stack("armor",i,stack)
			end
		end
	end

	return result
end,true)
