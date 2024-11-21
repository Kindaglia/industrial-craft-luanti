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
local windMill={}

windMill.getFormspec=function(pos)
	local meta=minetest.get_meta(pos)
	local charging=meta:get_int("charging")
	local formspec={
		"list[context;charged;4.7,1.8;1,1]",
		industrialtest.internal.getItemSlotBg(4.7,1.8,1,1),
		(charging>0 and "image[4.7,3;1,1;industrialtest_gui_wind_bg.png^[lowpart:"..charging..":industrialtest_gui_wind_fg.png]"
		 or "image[4.7,3;1,1;industrialtest_gui_wind_bg.png]"),
		"listring[context;charged]"
	}
	return table.concat(formspec,"")
end

windMill.onConstruct=function(pos,meta,inv)
	inv:set_size("charged",1)
	meta:set_int("prevCharging",0)
	meta:set_int("charging",0)
end

windMill.onTimer=function(pos,elapsed,meta,inv)
	local chargedSlot=inv:get_stack("charged",1)
	local shouldUpdateFormspec=false
	local charging
	if industrialtest.mtgAvailable then
		charging=math.min(math.max(pos.y,0)/150,1.0)
	elseif industrialtest.mclAvailable then
		local dimMax=31000
		local dim=mcl_worlds.pos_to_dimension(pos)
		if dim=="overworld" then
			dimMax=mcl_vars.mg_overworld_max
		elseif dim=="nether" then
			dimMax=mcl_vars.mg_nether_max
		elseif dim=="end" then
			dimMax=mcl_vars.mg_end_max
		end
		charging=math.max(mcl_worlds.layer_to_y(pos.y,dim),0)/dimMax
	end
	local neighbourPositions={
		vector.offset(pos,-1,0,0),
		vector.offset(pos,1,0,0),
		vector.offset(pos,0,0,-1),
		vector.offset(pos,0,0,1)
	}
	for _,value in ipairs(neighbourPositions) do
		local node=minetest.get_node_or_nil(value)
		if node and node.name~="air" then
			charging=0
			break
		end
	end
	industrialtest.api.addPower(meta,math.ceil(charging*elapsed*industrialtest.api.lvPowerFlow))
	if meta:get_int("prevCharging")~=charging then
		shouldUpdateFormspec=true
	end
	if chargedSlot:get_count()>0 and meta:get_int("industrialtest.powerAmount")>0 then
		if industrialtest.api.transferPowerToItem(meta,chargedSlot,industrialtest.api.lvPowerFlow)>0 then
			inv:set_stack("charged",1,chargedSlot)
		end
	end
	industrialtest.api.powerFlow(pos)
	meta:set_int("charging",charging*100)
	return true,shouldUpdateFormspec
end

industrialtest.internal.registerMachine({
	name="wind_mill",
	displayName=S("Wind Mill"),
	getFormspec=windMill.getFormspec,
	capacity=7000,
	flow=industrialtest.api.lvPowerFlow,
	ioConfig="oooooo",
	requiresWrench=true,
	registerActiveVariant=false,
	powerSlots={"charged"},
	storageSlots={"charged"},
	sounds="metal",
	groups={
		_industrialtest_hasPowerOutput=1
	},
	customKeys={
		tiles={
			"industrialtest_machine_block.png",
			"industrialtest_machine_block.png",
			"industrialtest_machine_block.png^industrialtest_wind_mill_side.png",
			"industrialtest_machine_block.png^industrialtest_wind_mill_side.png",
			"industrialtest_machine_block.png^industrialtest_wind_mill_side.png",
			"industrialtest_machine_block.png^industrialtest_wind_mill_side.png"
		}
	},
	onConstruct=windMill.onConstruct,
	onTimer=windMill.onTimer
})

minetest.register_craft({
	type="shaped",
	output="industrialtest:wind_mill",
	recipe={
		{"","industrialtest:refined_iron_ingot",""},
		{"industrialtest:refined_iron_ingot","industrialtest:generator","industrialtest:refined_iron_ingot"},
		{"","industrialtest:refined_iron_ingot",""}
	}
})
