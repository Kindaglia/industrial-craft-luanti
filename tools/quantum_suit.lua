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

local quantumSuit={}
quantumSuit.helmetBreathRefillOpPower=1000
quantumSuit.leggingsSpeedOpPower=125
quantumSuit.leggingsSpeedMaxVel=4
quantumSuit.bootsJumpOpPower=50
quantumSuit.bootsFallDamageReductionOpPower=900

local playerPositions={}
local playerLeggingsSpeedEnabled={}
local playerBootsJumpEnabled={}

local function registerQuantumSuitPart(config)
	config.groups=config.groups or {}
	config.groups._industrialtest_nanoSuit=1
	if config.element=="head" then
		config.groups.armor_head=1
	elseif config.element=="torso" then
		config.groups.armor_torso=1
	elseif config.element=="legs" then
		config.groups.armor_legs=1
	elseif config.element=="feet" then
		config.groups.armor_feet=1
	end
	local definition={
		description=config.displayName,
		inventory_image="industrialtest_"..config.name.."_inv.png",
		groups=config.groups,
		_industrialtest_powerStorage=true,
		_industrialtest_powerCapacity=10000000,
		_industrialtest_powerFlow=industrialtest.api.ivPowerFlow,
		_industrialtest_damageReduction=config.damageReduction,
		_industrialtest_powerPerDamage=30
	}
	if config.customKeys then
		for k,v in pairs(config.customKeys) do
			definition[k]=v
		end
	end
	if industrialtest.mtgAvailable then
		definition.groups.armor_heal=0
		armor:register_armor("industrialtest:"..config.name,definition)
	elseif industrialtest.mclAvailable then
		definition.groups.armor=1
		definition.groups.non_combat_armor=1
		definition.sounds={
			_mcl_armor_equip="mcl_armor_equip_iron",
			_mcl_armor_unequip="mcl_armor_unequip_iron"
		}
		definition.on_place=mcl_armor.equip_on_use
		definition.on_secondary_use=mcl_armor.equip_on_use
		definition._mcl_armor_element=config.element
		definition._mcl_armor_texture=(config.element=="feet" and "industrialtest_mcl_" or "industrialtest_")..config.name..".png"
		minetest.register_tool("industrialtest:"..config.name,definition)
	end
end

local function findInPlayerArmorList(player,itemname)
	local inv
	if industrialtest.mclAvailable then
		inv=player:get_inventory()
	elseif industrialtest.mtgAvailable then
		_,inv=armor:get_valid_player(player,"")
	end
	local armorList=inv:get_list("armor")
	for i,stack in ipairs(armorList) do
		if stack:get_name()==itemname then
			return i,stack,inv
		end
	end
end

quantumSuit.tryFly=function(itemstack)
	local meta=itemstack:get_meta()
	if meta:get_int("industrialtest.powerAmount")<10 then
		return false
	end
	industrialtest.api.addPowerToItem(itemstack,-10)
	return true
end


registerQuantumSuitPart({
	name="quantum_helmet",
	displayName=S("Quantum Helmet"),
	element="head",
	damageReduction=0.15
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:quantum_helmet",
	recipe={
		{"industrialtest:reinforced_glass","industrialtest:nano_helmet","industrialtest:reinforced_glass"},
		{"industrialtest:iridium_plate","industrialtest:lapotron_crystal","industrialtest:iridium_plate"},
		{"industrialtest:advanced_electronic_circuit","industrialtest:empty_cell","industrialtest:advanced_electronic_circuit"}
	}
})

registerQuantumSuitPart({
	name="quantum_bodyarmor",
	displayName=S("Quantum Bodyarmor"),
	element="torso",
	damageReduction=0.4,
	groups={
		_industrialtest_jetpack=1
	},
	customKeys={
		_industrialtest_tryFly=quantumSuit.tryFly
	}
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:quantum_bodyarmor",
	recipe={
		{"industrialtest:advanced_alloy","industrialtest:nano_bodyarmor","industrialtest:advanced_alloy"},
		{"industrialtest:iridium_plate","industrialtest:lapotron_crystal","industrialtest:iridium_plate"},
		{"industrialtest:iridium_plate","industrialtest:electric_jetpack","industrialtest:iridium_plate"}
	}
})

registerQuantumSuitPart({
	name="quantum_leggings",
	displayName=S("Quantum Leggings"),
	element="legs",
	damageReduction=0.30
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:quantum_leggings",
	recipe={
		{"industrialtest:machine_block","industrialtest:lapotron_crystal","industrialtest:machine_block"},
		{"industrialtest:iridium_plate","industrialtest:nano_leggings","industrialtest:iridium_plate"},
		{industrialtest.elementKeys.yellowDust,"",industrialtest.elementKeys.yellowDust}
	}
})

registerQuantumSuitPart({
	name="quantum_boots",
	displayName=S("Quantum Boots"),
	element="feet",
	damageReduction=0.15
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:quantum_boots",
	recipe={
		{"industrialtest:iridium_plate","industrialtest:nano_boots","industrialtest:iridium_plate"},
		{industrialtest.elementKeys.ironBoots,"industrialtest:lapotron_crystal",industrialtest.elementKeys.ironBoots}
	}
})

minetest.register_globalstep(function(dtime)
	local players=minetest.get_connected_players()
	for _,player in ipairs(players) do
		local control=player:get_player_control()
		local playerName=player:get_player_name()
		if playerLeggingsSpeedEnabled[playerName] then
			local shouldStopSpeed=true
			if control.up and control.aux1 then
				local index,stack,inv=findInPlayerArmorList(player,"industrialtest:quantum_leggings")
				if index and stack and inv then
					local meta=stack:get_meta()
					local requiredPower=vector.distance(player:get_pos(),playerPositions[playerName])*quantumSuit.leggingsSpeedOpPower
					if meta:get_int("industrialtest.powerAmount")>=requiredPower then
						industrialtest.api.addPowerToItem(stack,-requiredPower)
						inv:set_stack("armor",index,stack)
						shouldStopSpeed=false
					end
				end
			end
			if shouldStopSpeed then
				player:set_physics_override({
					speed=1
				})
				playerLeggingsSpeedEnabled[playerName]=false
			end
		elseif control.up and control.aux1 then
			local index,stack,inv=findInPlayerArmorList(player,"industrialtest:quantum_leggings")
			if index and stack and inv then
				local meta=stack:get_meta()
				local requiredPower=vector.distance(player:get_pos(),playerPositions[playerName])*quantumSuit.leggingsSpeedOpPower
				if meta:get_int("industrialtest.powerAmount")>=requiredPower then
					player:set_physics_override({
						speed=quantumSuit.leggingsSpeedMaxVel
					})
					playerLeggingsSpeedEnabled[playerName]=true
				end
			end
		end

		if playerBootsJumpEnabled[playerName] then
			local shouldStopJump=not control.aux1
			if control.jump and control.aux1 then
				local index,stack,inv=findInPlayerArmorList(player,"industrialtest:quantum_boots")
				if index and stack and inv then
					local meta=stack:get_meta()
					if meta:get_int("industrialtest.powerAmount")>=quantumSuit.bootsJumpOpPower then
						industrialtest.api.addPowerToItem(stack,-quantumSuit.bootsJumpOpPower)
						inv:set_stack("armor",index,stack)
						shouldStopJump=false
					end
				end
			end
			if shouldStopJump then
				player:set_physics_override({
					jump=1
				})
				playerBootsJumpEnabled[playerName]=false
			end
		elseif control.aux1 then
			local index,stack,inv=findInPlayerArmorList(player,"industrialtest:quantum_boots")
			if index and stack and inv then
				local meta=stack:get_meta()
				local requiredPower=vector.distance(player:get_pos(),playerPositions[playerName])*quantumSuit.leggingsSpeedOpPower
				if meta:get_int("industrialtest.powerAmount")>=quantumSuit.bootsJumpOpPower then
					player:set_physics_override({
						jump=2
					})
					playerBootsJumpEnabled[playerName]=true
				end
			end
		end

		if player:get_breath()<10 then
			local index,stack,inv=findInPlayerArmorList(player,"industrialtest:quantum_helmet")
			if index and stack and inv then
				local meta=stack:get_meta()
				local refilled=math.min(9-player:get_breath(),math.floor(meta:get_int("industrialtest.powerAmount")/quantumSuit.helmetBreathRefillOpPower))
				if refilled>0 then
					player:set_breath(player:get_breath()+refilled)
					industrialtest.api.addPowerToItem(stack,-refilled*quantumSuit.helmetBreathRefillOpPower)
					inv:set_stack("armor",index,stack)
				end
			end
		end
		
		playerPositions[playerName]=player:get_pos()
	end
end)

minetest.register_on_player_hpchange(function(player,hpChange,reason)
	if reason.type~="fall" then
		return hpChange
	end

	local index,stack,inv=findInPlayerArmorList(player,"industrialtest:quantum_boots")
	if not index or not stack or not inv then
		return hpChange
	end

	local damage=math.abs(hpChange)
	local meta=stack:get_meta()
	local reducedDamage=math.min(damage,math.floor(meta:get_int("industrialtest.powerAmount")/(damage*quantumSuit.bootsFallDamageReductionOpPower)))
	industrialtest.api.addPowerToItem(stack,-reducedDamage*quantumSuit.bootsFallDamageReductionOpPower)
	inv:set_stack("armor",index,stack)

	return hpChange+reducedDamage
end,true)
