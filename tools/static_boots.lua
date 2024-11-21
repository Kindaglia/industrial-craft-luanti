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
local playerPositions={}

local function onGlobalStep(player,inv,stack)
	if stack:get_name()~="industrialtest:static_boots" then
		return false
	end
	local playerPos=player:get_pos()
	playerPos.y=0
	if not playerPositions[player:get_player_name()] then
		playerPositions[player:get_player_name()]=playerPos
		return true
	end
	if vector.distance(playerPos,playerPositions[player:get_player_name()])<5 then
		return true
	end
	playerPositions[player:get_player_name()]=playerPos
	local armorList=inv:get_list("armor")
	for i=1,#armorList do
		local meta=armorList[i]:get_meta()
		if industrialtest.api.hasPowerStorage(meta) and not industrialtest.api.isFullyCharged(meta) then
			industrialtest.api.addPowerToItem(armorList[i],1)
			inv:set_stack("armor",i,armorList[i])
			break
		end
	end
	return true
end

if industrialtest.mtgAvailable then
	armor:register_armor("industrialtest:static_boots",{
		description=S("Static Boots"),
		inventory_image="industrialtest_static_boots_inv.png",
		groups={
			armor_feet=1,
			armor_heal=0
		}
	})
elseif industrialtest.mclAvailable then
	minetest.register_tool("industrialtest:static_boots",{
		description=S("Static Boots"),
		inventory_image="industrialtest_static_boots_inv.png",
		groups={
			armor=1,
			non_combat_armor=1,
			armor_feet=1,
			non_combat_feet=1
		},
		sounds={
			_mcl_armor_equip="mcl_armor_equip_iron",
			_mcl_armor_unequip="mcl_armor_unequip_iron"
		},
		on_place=mcl_armor.equip_on_use,
		on_secondary_use=mcl_armor.equip_on_use,
		_mcl_armor_element="feet",
		_mcl_armor_texture="industrialtest_mcl_static_boots.png"
	})
end
minetest.register_craft({
	type="shaped",
	output="industrialtest:static_boots",
	recipe={
		{industrialtest.elementKeys.ironIngot,"",industrialtest.elementKeys.ironIngot},
		{industrialtest.elementKeys.ironIngot,industrialtest.elementKeys.whiteWool,industrialtest.elementKeys.ironIngot},
		{"industrialtest:insulated_copper_cable","industrialtest:insulated_copper_cable","industrialtest:insulated_copper_cable"}
	}
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:static_boots",
	recipe={
		{"",industrialtest.elementKeys.ironBoots,""},
		{"",industrialtest.elementKeys.whiteWool,""},
		{"industrialtest:insulated_copper_cable","industrialtest:insulated_copper_cable","industrialtest:insulated_copper_cable"}
	}
})

minetest.register_on_leaveplayer(function(player)
	playerPositions[player:get_player_name()]=nil
end)

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
			local stack=inv:get_stack("armor",5)
			onGlobalStep(player,inv,stack)
		end
	end
end)
