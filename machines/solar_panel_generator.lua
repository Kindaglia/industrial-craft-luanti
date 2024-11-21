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
local solarPanel={}

solarPanel.getFormspec=function(pos)
	local amount=minetest.get_natural_light(vector.offset(pos,0,1,0))/15.0
	local charging=amount>0.5
	local formspec={
		"list[context;charged;4.7,1.8;1,1]",
		industrialtest.internal.getItemSlotBg(4.7,1.8,1,1),
		(charging and "image[4.7,2.8;1,1;industrialtest_gui_sun_fg.png]"
		 or "image[4.7,2.8;1,1;industrialtest_gui_sun_bg.png]"),
		"listring[context;charged]"
	}
	return table.concat(formspec,"")
end

solarPanel.onConstruct=function(pos,meta,inv)
	inv:set_size("charged",1)
	meta:set_float("prevAmount",0)
end

solarPanel.onTimer=function(pos,elapsed,meta,inv,config)
	local chargedSlot=inv:get_stack("charged",1)
	local shouldUpdateFormspec=false
	local amount=minetest.get_natural_light(vector.offset(pos,0,1,0))/15.0
	local charging=amount>0.5
	if charging then
		industrialtest.api.addPower(meta,math.ceil(amount*config.flow*elapsed))
	end
	if meta:get_int("industrialtest.powerAmount")>0 then
		if chargedSlot:get_count()>0 and not industrialtest.api.isFullyCharged(chargedSlot:get_meta()) then
			industrialtest.api.transferPowerToItem(meta,chargedSlot,math.ceil(config.flow*elapsed))
			inv:set_stack("charged",1,chargedSlot)
		end
		industrialtest.api.powerFlow(pos)
	end
	if amount~=meta:get_float("prevAmount") then
		shouldUpdateFormspec=true
		meta:set_float("prevAmount",amount)
	end
	return true,shouldUpdateFormspec
end

local function registerSolarPanelGenerator(config)
	industrialtest.internal.registerMachine({
		name=config.name,
		displayName=config.displayName,
		getFormspec=solarPanel.getFormspec,
		capacity=config.capacity,
		flow=config.flow,
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
				"industrialtest_machine_block.png^industrialtest_"..config.name.."_top.png",
				"industrialtest_machine_block.png"
			}
		},
		onConstruct=solarPanel.onConstruct,
		onTimer=function(pos,elapsed,meta,inv)
			return solarPanel.onTimer(pos,elapsed,meta,inv,config)
		end
	})
end

registerSolarPanelGenerator({
	name="solar_panel",
	displayName=S("Solar Panel"),
	capacity=industrialtest.api.lvPowerFlow*2,
	flow=industrialtest.api.lvPowerFlow
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:solar_panel",
	recipe={
		{"industrialtest:coal_dust",industrialtest.elementKeys.glass,"industrialtest:coal_dust"},
		{industrialtest.elementKeys.glass,"industrialtest:coal_dust",industrialtest.elementKeys.glass},
		{"industrialtest:insulated_copper_cable","industrialtest:generator","industrialtest:insulated_copper_cable"}
	}
})

registerSolarPanelGenerator({
	name="lv_solar_array",
	displayName=S("LV Solar Array"),
	capacity=industrialtest.api.lvPowerFlow*4,
	flow=industrialtest.api.lvPowerFlow*2
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:lv_solar_array",
	recipe={
		{"industrialtest:solar_panel","industrialtest:solar_panel","industrialtest:solar_panel"},
		{"industrialtest:solar_panel","industrialtest:lv_transformer","industrialtest:solar_panel"},
		{"industrialtest:solar_panel","industrialtest:solar_panel","industrialtest:solar_panel"}
	}
})

registerSolarPanelGenerator({
	name="mv_solar_array",
	displayName=S("MV Solar Array"),
	capacity=industrialtest.api.mvPowerFlow*2,
	flow=industrialtest.api.mvPowerFlow
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:mv_solar_array",
	recipe={
		{"industrialtest:lv_solar_array","industrialtest:lv_solar_array","industrialtest:lv_solar_array"},
		{"industrialtest:lv_solar_array","industrialtest:mv_transformer","industrialtest:lv_solar_array"},
		{"industrialtest:lv_solar_array","industrialtest:lv_solar_array","industrialtest:lv_solar_array"}
	}
})

registerSolarPanelGenerator({
	name="hv_solar_array",
	displayName=S("HV Solar Array"),
	capacity=industrialtest.api.hvPowerFlow*2,
	flow=industrialtest.api.hvPowerFlow
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:hv_solar_array",
	recipe={
		{"industrialtest:mv_solar_array","industrialtest:mv_solar_array","industrialtest:mv_solar_array"},
		{"industrialtest:mv_solar_array","industrialtest:hv_transformer","industrialtest:mv_solar_array"},
		{"industrialtest:mv_solar_array","industrialtest:mv_solar_array","industrialtest:mv_solar_array"}
	}
})
