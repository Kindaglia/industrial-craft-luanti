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

local updateDelta=0

local function registerBatpack(config)
	if industrialtest.mtgAvailable then
		armor:register_armor("industrialtest:"..config.name,{
			description=config.displayName,
			inventory_image="industrialtest_"..config.name.."_inv.png",
			groups={
				armor_torso=1,
				armor_heal=0,
				_industrialtest_batpack=1
			},
			_industrialtest_powerStorage=true,
			_industrialtest_powerCapacity=config.powerCapacity,
			_industrialtest_powerFlow=config.powerFlow
		})
	elseif industrialtest.mclAvailable then
		minetest.register_tool("industrialtest:"..config.name,{
			description=config.displayName,
			inventory_image="industrialtest_"..config.name.."_inv.png",
			groups={
				armor=1,
				non_combat_armor=1,
				armor_torso=1,
				non_combat_torso=1,
				_industrialtest_batpack=1
			},
			sounds={
				_mcl_armor_equip="mcl_armor_equip_iron",
				_mcl_armor_unequip="mcl_armor_unequip_iron"
			},
			on_place=mcl_armor.equip_on_use,
			on_secondary_use=mcl_armor.equip_on_use,
			_mcl_armor_element="torso",
			_mcl_armor_texture="industrialtest_"..config.name..".png",
			_industrialtest_powerStorage=true,
			_industrialtest_powerCapacity=config.powerCapacity,
			_industrialtest_powerFlow=config.powerFlow
		})
	end
end

local function onGlobalStep(player,inv,stack,index,def)
	if not def.groups or not def.groups._industrialtest_batpack then
		return false
	end
	local wielded=player:get_wielded_item()
	local wieldedMeta=wielded:get_meta()
	if not industrialtest.api.hasPowerStorage(wieldedMeta) or wieldedMeta:get_int("industrialtest.powerFlow")>def._industrialtest_powerFlow then
		return true
	end
	if industrialtest.api.transferPowerFromItem(stack,wieldedMeta,def._industrialtest_powerFlow)>0 then
		industrialtest.api.updateItemPowerText(wielded)
		player:set_wielded_item(wielded)
		inv:set_stack("armor",index,stack)
	end
	return true
end

registerBatpack({
	name="batpack_v",
	displayName=S("BatPack"),
	powerCapacity=60000,
	powerFlow=industrialtest.api.lvPowerFlow
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:batpack_v",
	recipe={
		{"industrialtest:re_battery","industrialtest:electronic_circuit","industrialtest:re_battery"},
		{"industrialtest:re_battery",industrialtest.elementKeys.tinIngot,"industrialtest:re_battery"},
		{"industrialtest:re_battery","","industrialtest:re_battery"}
	}
})

registerBatpack({
	name="lappack_v",
	displayName=S("LapPack"),
	powerCapacity=300000,
	powerFlow=industrialtest.api.hvPowerFlow
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:lappack_v",
	recipe={
		{industrialtest.elementKeys.powerCarrier,"industrialtest:electronic_circuit",industrialtest.elementKeys.powerCarrier},
		{industrialtest.elementKeys.powerCarrier,"industrialtest:batpack_v",industrialtest.elementKeys.powerCarrier},
		{industrialtest.elementKeys.powerCarrier,"",industrialtest.elementKeys.powerCarrier}
	}
})

minetest.register_globalstep(function(dtime)
	updateDelta=updateDelta+dtime
	if updateDelta<industrialtest.updateDelay then
		return
	end
	updateDelta=0
	local players=minetest.get_connected_players()
	for _,player in ipairs(players) do
		if industrialtest.mtgAvailable then
			local _,inv=armor:get_valid_player(player,"")
			if inv then
				local armorList=inv:get_list("armor")
				assert(armorList)
				for i=1,#armorList do
					local stack=armorList[i]
					local def=stack:get_definition()
					if onGlobalStep(player,inv,stack,i,def) then
						break
					end
				end
			end
		elseif industrialtest.mclAvailable then
			local inv=player:get_inventory()
			local stack=inv:get_stack("armor",3)
			local def=stack:get_definition()
			onGlobalStep(player,inv,stack,3,def)
		end
	end
end)
