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

industrialtest.internal.registeredElectricChainsaws={}
industrialtest.internal.registeredElectricDrills={}
industrialtest.internal.registeredElectricHoes={}
industrialtest.internal.registeredElectricSabers={}

local function isActive(itemstack)
	return string.sub(itemstack:get_name(),-string.len("_active"),-1)=="_active"
end

local function beforeUse(user,itemstack,canDig)
	local meta=itemstack:get_meta()
	local def=itemstack:get_definition()
	if meta:get_int("industrialtest.powerAmount")>=20 and canDig then
		if not isActive(itemstack) then
			itemstack:set_name(itemstack:get_name().."_active")
		end
	else
		itemstack:set_name(def._industrialtest_inactiveName)
	end
	user:set_wielded_item(itemstack)
end

minetest.register_on_punchnode(function(pos,node,user,pointed)
	if not user then
		return
	end
	local itemstack=user:get_wielded_item()
	local meta=itemstack:get_meta()
	local def=minetest.registered_nodes[node.name]
	if industrialtest.internal.registeredElectricChainsaws[itemstack:get_name()] then
		beforeUse(user,itemstack,(industrialtest.mtgAvailable and def.groups and def.groups.choppy) or (industrialtest.mclAvailable and def.groups and def.groups.axey))
	elseif industrialtest.mclAvailable and industrialtest.internal.registeredElectricHoes[itemstack:get_name()] then
		beforeUse(user,itemstack,def.groups and def.groups.hoey)
	elseif industrialtest.internal.registeredElectricDrills[itemstack:get_name()] then
		beforeUse(user,itemstack,(industrialtest.mtgAvailable and def.groups and (def.groups.cracky or def.groups.crumbly)) or (industrialtest.mclAvailable and def.groups and (def.groups.pickaxey or def.groups.shovely)))
	elseif industrialtest.internal.registeredElectricSabers[itemstack:get_name()] then
		beforeUse(user,itemstack,(industrialtest.mtgAvailable and def.groups and def.groups.snappy) or (industrialtest.mclAvailable and def.groups and (def.groups.swordy or def.groups.swordy_cobweb)))
	end
end)
