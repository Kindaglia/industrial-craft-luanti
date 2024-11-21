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

local function getListnameBySide(sides,direction)
	local listname
	for _,side in ipairs(sides) do
		if (not side.x or side.x==direction.x) and (not side.y or side.y==direction.y) and (not side.z or side.z==direction.z) then
			listname=side.listname
			break
		end
	end
	return listname
end

local function addPipeworksCompatibility(name,sides,inputInventory)
	local groups=table.copy(minetest.registered_nodes[name].groups)
	groups.tubedevice=1
	groups.tubedevice_receiver=1

	local override={
		groups=groups,
		tube={
			insert_object=function(pos,node,stack,direction)
				local meta=minetest.get_meta(pos)
				local inv=meta:get_inventory()
				local listname=getListnameBySide(sides,direction)
				if (listname=="charged" or listname=="discharged" or listname=="powerStorage") and not industrialtest.api.hasPowerStorage(stack:get_meta()) then
					return nil
				end
				local result=inv:add_item(listname,stack)
				minetest.get_node_timer(pos):start(industrialtest.updateDelay)
				return result
			end,
			can_insert=function(pos,node,stack,direction)
				local meta=minetest.get_meta(pos)
				local inv=meta:get_inventory()
				local listname=getListnameBySide(sides,direction)
				if (listname=="charged" or listname=="discharged" or listname=="powerStorage") and not industrialtest.api.hasPowerStorage(stack:get_meta()) then
					return false
				end
				return inv:room_for_item(listname,stack)
			end,
			input_inventory=inputInventory,
			connect_sides={
				left=1,
				right=1,
				back=1,
				front=1,
				bottom=1,
				top=1
			}
		},
		after_place_node=pipeworks.after_place,
		after_dig_node=pipeworks.after_dig,
		on_rotate=pipeworks.on_rotate
	}

	minetest.override_item(name,override)
	local activeName=name.."_active"
	if minetest.registered_nodes[activeName] then
		minetest.override_item(activeName,override)
	end
end

-- Iron Furnace
addPipeworksCompatibility("industrialtest:iron_furnace",{
	{
		y=1,
		listname="fuel"
	},
	{listname="src"}
},"dst")

-- Generator
addPipeworksCompatibility("industrialtest:generator",{
	{
		y=1,
		listname="fuel",
	},
	{listname="charged"}
},"charged")

-- Geothermal Generator
addPipeworksCompatibility("industrialtest:geothermal_generator",{
	{
		y=1,
		listname="leftover",
	},
	{
		y=-1,
		listname="fluid"
	},
	{listname="charged"}
},"leftover")

-- Water Mill
addPipeworksCompatibility("industrialtest:water_mill",{
	{
		y=1,
		listname="leftover",
	},
	{
		y=-1,
		listname="fluid"
	},
	{listname="charged"}
},"leftover")

-- Wind Mill
addPipeworksCompatibility("industrialtest:wind_mill",{
	{listname="charged"}
},"charged")

-- Solar Panel
addPipeworksCompatibility("industrialtest:solar_panel",{
	{listname="charged"}
},"charged")
addPipeworksCompatibility("industrialtest:lv_solar_array",{
	{listname="charged"}
},"charged")
addPipeworksCompatibility("industrialtest:mv_solar_array",{
	{listname="charged"}
},"charged")
addPipeworksCompatibility("industrialtest:hv_solar_array",{
	{listname="charged"}
},"charged")

-- Nuclear Reactor
local def=table.copy(minetest.registered_nodes["industrialtest:nuclear_reactor"])

def.groups.tubedevice=1
def.groups.tubedevice_receiver=1

local override={
	groups=def.groups,
	tube={
		insert_object=function(pos,node,stack,direction)
			local listname=direction.y==0 and "charged" or "fuel"
			local def=stack:get_definition()
			if (listname=="charged" and not industrialtest.api.hasPowerStorage(stack:get_meta())) or
				(listname=="fuel" and (not def.groups or not def.groups._industrialtest_placedInNuclearReactor)) then
				return nil
			end
			local meta=minetest.get_meta(pos)
			local inv=meta:get_inventory()
			local result=inv:add_item(listname,stack)
			minetest.registered_nodes["industrialtest:nuclear_reactor"].on_metadata_inventory_put(pos)
			return result
		end,
		can_insert=function(pos,node,stack,direction)
			local listname=direction.y==0 and "charged" or "fuel"
			local def=stack:get_definition()
			if (listname=="charged" and not industrialtest.api.hasPowerStorage(stack:get_meta())) or
				(listname=="fuel" and (not def.groups or not def.groups._industrialtest_placedInNuclearReactor)) then
				return false
			end
			local meta=minetest.get_meta(pos)
			local inv=meta:get_inventory()
			return inv:room_for_item(listname,stack)
		end,
		input_inventory="fuel",
		connect_sides={
			left=1,
			right=1,
			back=1,
			front=1,
			bottom=1,
			top=1
		}
	},
	after_place_node=pipeworks.after_place,
	after_dig_node=pipeworks.after_dig,
	on_rotate=pipeworks.on_rotate
}

minetest.override_item("industrialtest:nuclear_reactor",override)
minetest.override_item("industrialtest:nuclear_reactor_active",override)

-- Nuclear Reactor Chamber
override=table.copy(override)
def=table.copy(minetest.registered_nodes["industrialtest:nuclear_reactor_chamber"])

override.groups=def.groups
override.groups.tubedevice=1
override.groups.tubedevice_receiver=1

override.tube.insert_object=function(pos,node,stack,direction)
	local listname=direction.y==0 and "charged" or "fuel"
	local def=stack:get_definition()
	if (listname=="charged" and not industrialtest.api.hasPowerStorage(stack:get_meta())) or
		(listname=="fuel" and (not def.groups or not def.groups._industrialtest_placedInNuclearReactor)) then
		return nil
	end
	local meta=minetest.get_meta(pos)
	local inv=meta:get_inventory()
	local result=inv:add_item(listname,stack)
	minetest.registered_nodes["industrialtest:nuclear_reactor_chamber"].on_metadata_inventory_put(pos)
	return result
end

override.after_place_node_old=def.after_place_node
override.after_place_node=function(pos)
	minetest.registered_nodes["industrialtest:nuclear_reactor_chamber"].after_place_node_old(pos)
	pipeworks.after_place(pos)
end

minetest.override_item("industrialtest:nuclear_reactor_chamber",override)

-- BatBox
addPipeworksCompatibility("industrialtest:batbox",{
	{
		y=1,
		listname="discharged"
	},
	{listname="charged"}
},"charged")

-- CESU
addPipeworksCompatibility("industrialtest:cesu",{
	{
		y=1,
		listname="discharged"
	},
	{listname="charged"}
},"charged")

-- MFE
addPipeworksCompatibility("industrialtest:mfe",{
	{
		y=1,
		listname="discharged"
	},
	{listname="charged"}
},"charged")

-- MFSU
addPipeworksCompatibility("industrialtest:mfsu",{
	{
		y=1,
		listname="discharged"
	},
	{listname="charged"}
},"charged")

-- Canning Machine
def=table.copy(minetest.registered_nodes["industrialtest:canning_machine"])

def.groups.tubedevice=1
def.groups.tubedevice_receiver=1

override={
	groups=def.groups,
	tube={
		insert_object=function(pos,node,stack,direction)
			local listname
			if direction.y==1 then
				listname="powerStorage"
			elseif direction.y==-1 then
				listname="fuel"
			else
				listname="target"
			end
			local def=stack:get_definition()
			if (listname=="powerStorage" and not industrialtest.api.hasPowerStorage(stack:get_meta())) or
				(listname=="fuel" and (not def.groups or not def.groups._industrialtest_fuel)) or
				(listname=="target" and (not def.groups or not def.groups._industrialtest_fueled)) then
				return nil
			end
			local meta=minetest.get_meta(pos)
			local inv=meta:get_inventory()
			local result=inv:add_item(listname,stack)
			minetest.get_node_timer(pos):start(industrialtest.updateDelay)
			return result
		end,
		can_insert=function(pos,node,stack,direction)
			local listname
			if direction.y==1 then
				listname="powerStorage"
			elseif direction.y==-1 then
				listname="fuel"
			else
				listname="target"
			end
			local def=stack:get_definition()
			if (listname=="powerStorage" and not industrialtest.api.hasPowerStorage(stack:get_meta())) or
				(listname=="fuel" and (not def.groups or not def.groups._industrialtest_fuel)) or
				(listname=="target" and (not def.groups or not def.groups._industrialtest_fueled)) then
				return false
			end
			local meta=minetest.get_meta(pos)
			local inv=meta:get_inventory()
			return inv:room_for_item(listname,stack)
		end,
		input_inventory="target",
		connect_sides={
			left=1,
			right=1,
			back=1,
			bottom=1,
			top=1
		}
	},
	after_place_node=pipeworks.after_place,
	after_dig_node=pipeworks.after_dig,
	on_rotate=pipeworks.on_rotate
}

minetest.override_item("industrialtest:canning_machine",override)
minetest.override_item("industrialtest:canning_machine_active",override)

-- Rotary Macerator
addPipeworksCompatibility("industrialtest:rotary_macerator",{
	{
		y=1,
		listname="powerStorage"
	},
	{
		y=-1,
		listname="src"
	},
	{listname="modifier"}
},"dst")

-- Induction Furnace
addPipeworksCompatibility("industrialtest:induction_furnace",{
	{
		y=1,
		listname="powerStorage"
	},
	{listname="src"}
},"dst")

-- Simple electric item processors
for _,name in ipairs(industrialtest.internal.simpleElectricItemProcessors) do
	addPipeworksCompatibility(name,{
		{
			y=1,
			listname="powerStorage"
		},
		{listname="src"}
	},"dst")
end

for _,name in ipairs(industrialtest.internal.chargepads) do
	addPipeworksCompatibility(name,{
		{
			y=1,
			listname="discharged"
		},
		{listname="charged"}
	},"charged")
end
