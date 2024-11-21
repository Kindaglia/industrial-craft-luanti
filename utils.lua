-- IndustrialTest
-- Copyright (C) 2023 mrkubax10

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

local powerStorageInspectorContext={}
local function inspectNode(pos,playerName)
	local meta=minetest.get_meta(pos)
	local powerCapacity=meta:get_int("industrialtest.powerCapacity")
	local powerFlow=meta:get_int("industrialtest.powerFlow")
	local powerAmount=meta:get_int("industrialtest.powerAmount")
	local powerIOConfig=meta:get_string("industrialtest.ioConfig")
	local formspec={
		"formspec_version[4]",
		"size[8,8]",
		"label[0.5,0.5;"..S("Power Storage Inspector").."]",
		"label[0.5,1.5;"..S("Power Capacity: @1",powerCapacity).."]",
		"label[0.5,1.9;"..S("Power Flow: @1",powerFlow).."]",
		"label[0.5,2.3;"..S("Power Amount: @1",powerAmount).."]",
		"label[0.5,2.7;"..S("Power IO Config: @1",powerIOConfig).."]",
		"field[0.5,3.7;2,0.5;powerCapacity;"..S("Power Capacity")..";"..powerCapacity.."]",
		"field[0.5,4.5;2,0.5;powerFlow;"..S("Power Flow")..";"..powerFlow.."]",
		"field[0.5,5.4;2,0.5;powerAmount;"..S("Power Amount")..";"..powerAmount.."]",
		"field[0.5,6.2;2,0.5;powerIOConfig;"..S("Power IO Config")..";"..powerIOConfig.."]",
		"button[0.5,6.8;2,0.5;update;"..S("Update").."]",
		"label[4.2,2.25;"..S("Connections:").."]"
	}
	local connections=industrialtest.api.getConnections(pos)
	local sides={"X-","X+","Y-","Y+","Z-","Z+"}
	local sideString=""
	for _,value in ipairs(connections) do
		sideString=sideString.."("..value.x..", "..value.y..", "..value.z..")\n"
	end
	table.insert(formspec,"label[4.2,2.65;"..sideString.."]")
	powerStorageInspectorContext[playerName]=pos
	minetest.show_formspec(playerName,"industrialtest:power_storage_inspector_formspec",table.concat(formspec,""))
end
minetest.register_craftitem("industrialtest:power_storage_inspector",{
	description=S("Power Storage Inspector"),
	inventory_image="industrialtest_power_storage_inspector.png",
	on_place=function(itemstack,user,pointed)
		if pointed.type=="node" and user and user:is_player() then
			local meta=minetest.get_meta(pointed.under)
			if industrialtest.api.hasPowerStorage(meta) then
				inspectNode(pointed.under,user:get_player_name())
			end
		end
	end
})

minetest.register_on_player_receive_fields(function(player,formname,fields)
	if formname~="industrialtest:power_storage_inspector_formspec" then
		return false
	end
	local context=powerStorageInspectorContext[player:get_player_name()]
	if fields.update then
		local meta=minetest.get_meta(context)
		meta:set_int("industrialtest.powerCapacity",tonumber(fields.powerCapacity))
		meta:set_int("industrialtest.powerFlow",tonumber(fields.powerFlow))
		meta:set_int("industrialtest.powerAmount",tonumber(fields.powerAmount))
		meta:set_string("industrialtest.powerIOConfig",fields.powerIOConfig)
		local def=minetest.registered_nodes[minetest.get_node(context).name]
		if def and def._industrialtest_updateFormspec then
			def._industrialtest_updateFormspec(context)
		end
		minetest.close_formspec(player:get_player_name(),formname)
	end
	powerStorageInspectorContext[player:get_player_name()]=nil
	return true
end)
