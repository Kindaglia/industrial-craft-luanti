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

local function onGlobalStep(player,inv,stack)
	if stack:get_name()~="industrialtest:solar_helmet" then
		return false
	end
	local amount=math.floor((minetest.get_node_light(player:get_pos()) or 0)/2)
	if amount==0 then
		return true
	end
	local armorList=inv:get_list("armor")
	for i=1,#armorList do
		local meta=armorList[i]:get_meta()
		if industrialtest.api.hasPowerStorage(meta) and not industrialtest.api.isFullyCharged(meta) then
			industrialtest.api.addPowerToItem(armorList[i],amount)
			inv:set_stack("armor",i,armorList[i])
			break
		end
	end
	return true
end

if industrialtest.mtgAvailable then
	armor:register_armor("industrialtest:solar_helmet",{
		description=S("Solar Helmet"),
		inventory_image="industrialtest_solar_helmet_inv.png",
		groups={
			armor_head=1,
			armor_heal=0
		}
	})
elseif industrialtest.mclAvailable then
	minetest.register_tool("industrialtest:solar_helmet",{
		description=S("Solar Helmet"),
		inventory_image="industrialtest_solar_helmet_inv.png",
		groups={
			armor=1,
			non_combat_armor=1,
			armor_head=1,
			non_combat_feet=1
		},
		sounds={
			_mcl_armor_equip="mcl_armor_equip_iron",
			_mcl_armor_unequip="mcl_armor_unequip_iron"
		},
		on_place=mcl_armor.equip_on_use,
		on_secondary_use=mcl_armor.equip_on_use,
		_mcl_armor_element="head",
		_mcl_armor_texture="industrialtest_solar_helmet.png"
	})
end
minetest.register_craft({
	type="shaped",
	output="industrialtest:solar_helmet",
	recipe={
		{industrialtest.elementKeys.ironIngot,industrialtest.elementKeys.ironIngot,industrialtest.elementKeys.ironIngot},
		{industrialtest.elementKeys.ironIngot,"industrialtest:solar_panel",industrialtest.elementKeys.ironIngot},
		{"industrialtest:insulated_copper_cable","industrialtest:insulated_copper_cable","industrialtest:insulated_copper_cable"}
	}
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:solar_helmet",
	recipe={
		{"",industrialtest.elementKeys.ironHelmet,""},
		{"","industrialtest:solar_panel",""},
		{"industrialtest:insulated_copper_cable","industrialtest:insulated_copper_cable","industrialtest:insulated_copper_cable"}
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
					if onGlobalStep(player,inv,stack) then
						break
					end
				end
			end
		elseif industrialtest.mclAvailable then
			local inv=player:get_inventory()
			local stack=inv:get_stack("armor",1)
			onGlobalStep(player,inv,stack)
		end
	end
end)
