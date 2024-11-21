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

local jetpack={}
local electricJetpack={}

local function registerJetpack(config)
	if industrialtest.mclAvailable then
		local groups={
			armor=1,
			non_combat_armor=1,
			armor_torso=1,
			non_combat_torso=1,
			_industrialtest_jetpack=1
		}
		if config.groups then
			for key,value in pairs(config.groups) do
				groups[key]=value
			end
		end
		local definition={
			description=config.displayName,
			inventory_image="industrialtest_"..config.name.."_inv.png",
			groups=groups,
			sounds={
				_mcl_armor_equip="mcl_armor_equip_iron",
				_mcl_armor_unequip="mcl_armor_unequip_iron"
			},
			on_place=mcl_armor.equip_on_use,
			on_secondary_use=mcl_armor.equip_on_use,
			_mcl_armor_element="torso",
			_mcl_armor_texture="industrialtest_"..config.name..".png",
			_industrialtest_tryFly=config.tryFly
		}
		if config.customKeys then
			for key,value in pairs(config.customKeys) do
				definition[key]=value
			end
		end
		minetest.register_tool("industrialtest:"..config.name,definition)
	elseif industrialtest.mtgAvailable then
		local groups={
			armor_torso=1,
			armor_heal=0,
			_industrialtest_jetpack=1
		}
		if config.groups then
			for key,value in pairs(config.groups) do
				groups[key]=value
			end
		end
		local definition={
			description=config.displayName,
			inventory_image="industrialtest_"..config.name.."_inv.png",
			groups=groups,
			_industrialtest_tryFly=config.tryFly
		}
		if config.customKeys then
			for key,value in pairs(config.customKeys) do
				definition[key]=value
			end
		end
		armor:register_armor("industrialtest:"..config.name,definition)
	end
end

local function addYVelocityClamped(player,vel,max)
	local playerVel=player:get_velocity()
	if playerVel.y+vel>max then
		player:add_velocity(vector.new(0,math.max(max-playerVel.y,0),0))
	else
		player:add_velocity(vector.new(0,vel,0))
	end
end

local function onGlobalStep(player,inv,itemstack,index,def)
	if def.groups and def.groups._industrialtest_jetpack then
		if def._industrialtest_tryFly(itemstack) then
			addYVelocityClamped(player,1,10)
			inv:set_stack("armor",index,itemstack)
		end
		return true
	end
	return false
end

jetpack.tryFly=function(itemstack)
	local meta=itemstack:get_meta()
	if meta:get_int("industrialtest.fluidAmount")==0 then
		return false
	end
	industrialtest.api.addFluidToItem(itemstack,-1)
	return true
end

-- _v is hack to suppress "Registered armor doesn't have material at the end of registration name" warning from 3D Armor.
registerJetpack({
	name="jetpack_v",
	displayName=S("Jetpack"),
	groups={
		_industrialtest_fueled=1,
		_industrialtest_fluidStorage=1
	},
	tryFly=jetpack.tryFly,
	customKeys={
		_industrialtest_fluidCapacity=5000
	}
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:jetpack_v",
	recipe={
		{"industrialtest:refined_iron_ingot","industrialtest:electronic_circuit","industrialtest:refined_iron_ingot"},
		{"industrialtest:refined_iron_ingot","industrialtest:fuel_can","industrialtest:refined_iron_ingot"},
		{industrialtest.elementKeys.powerCarrier,"",industrialtest.elementKeys.powerCarrier}
	}
})

electricJetpack.tryFly=function(itemstack)
	local meta=itemstack:get_meta()
	if meta:get_int("industrialtest.powerAmount")<10 then
		return false
	end
	industrialtest.api.addPowerToItem(itemstack,-10)
	return true
end

registerJetpack({
	name="electric_jetpack",
	displayName=S("Electric Jetpack"),
	tryFly=electricJetpack.tryFly,
	customKeys={
		_industrialtest_powerStorage=true,
		_industrialtest_powerCapacity=30000,
		_industrialtest_powerFlow=industrialtest.api.lvPowerFlow
	}
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:electric_jetpack",
	recipe={
		{"industrialtest:refined_iron_ingot","industrialtest:advanced_electronic_circuit","industrialtest:refined_iron_ingot"},
		{"industrialtest:refined_iron_ingot","industrialtest:batbox","industrialtest:refined_iron_ingot"},
		{industrialtest.elementKeys.yellowDust,"",industrialtest.elementKeys.yellowDust}
	}
})

minetest.register_globalstep(function(dtime)
	-- FIXME: Maybe this can be optimized?
	local players=minetest.get_connected_players()
	for _,player in ipairs(players) do
		local control=player:get_player_control()
		if control.jump then
			if industrialtest.mclAvailable then
				local inv=player:get_inventory()
				local stack=inv:get_stack("armor",3)
				local def=stack:get_definition()
				onGlobalStep(player,inv,stack,3,def)
			elseif industrialtest.mtgAvailable then
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
			end
		end
	end
end)
