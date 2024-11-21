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
local ironFurnace={}

ironFurnace.getFormspec=function(fuelPercent,srcPercent)
	local formspec
	if industrialtest.mtgAvailable then
		formspec={
			"formspec_version[4]",
			"size[10.8,12]",
			"label[0.5,0.5;"..S("Iron Furnace").."]",
			"list[context;src;3.4,1.8;1,1]",
			(fuelPercent>0 and "image[3.4,2.8;1,1;default_furnace_fire_bg.png^[lowpart:"..fuelPercent..":default_furnace_fire_fg.png]"
			 or "image[3.4,2.8;1,1;default_furnace_fire_bg.png]"),
			"list[context;fuel;3.4,3.9;1,1]",
			(srcPercent>0 and "image[4.9,2.8;1,1;gui_furnace_arrow_bg.png^[lowpart:"..srcPercent..":gui_furnace_arrow_fg.png^[transformR270]"
			 or "image[4.9,2.8;1,1;gui_furnace_arrow_bg.png^[transformR270]"),
			"list[context;dst;6.4,2.8;1,1]",
			"list[current_player;main;0.5,6.25;8,1]",
			"list[current_player;main;0.5,7.5;8,3;8]",
			"listring[current_player;main]",
			"listring[context;src]",
			"listring[context;dst]"
		}
	elseif industrialtest.mclAvailable then
		formspec={
			"size[10.04,12]",
			"label[0.25,0.25;"..S("Iron Furnace").."]",
			"list[context;src;3.4,1.8;1,1]",
			mcl_formspec.get_itemslot_bg(3.4,1.8,1,1),
			(fuelPercent>0 and "image[3.4,2.8;1,1;default_furnace_fire_bg.png^[lowpart:"..fuelPercent..":default_furnace_fire_fg.png]"
			 or "image[3.4,2.8;1,1;default_furnace_fire_bg.png]"),
			"list[context;fuel;3.4,3.9;1,1]",
			mcl_formspec.get_itemslot_bg(3.4,3.9,1,1),
			(srcPercent>0 and "image[4.9,2.8;1,1;gui_furnace_arrow_bg.png^[lowpart:"..srcPercent..":gui_furnace_arrow_fg.png^[transformR270]"
			 or "image[4.9,2.8;1,1;gui_furnace_arrow_bg.png^[transformR270]"),
			"list[context;dst;6.4,2.8;1,1]",
			mcl_formspec.get_itemslot_bg(6.4,2.8,1,1),
			"list[current_player;main;0.5,7;9,3;9]",
			mcl_formspec.get_itemslot_bg(0.5,7,9,3),
			"list[current_player;main;0.5,10.24;9,1]",
			mcl_formspec.get_itemslot_bg(0.5,10.24,9,1),
			"listring[current_player;main]",
			"listring[context;src]",
			"listring[context;dst]"
		}
	end
	return table.concat(formspec,"")
end

ironFurnace.onConstruct=function(pos)
	local meta=minetest.get_meta(pos)
	local inv=meta:get_inventory()
	inv:set_size("src",1)
	inv:set_size("dst",1)
	inv:set_size("fuel",1)
	meta:set_string("formspec",ironFurnace.getFormspec(0,0))
	meta:set_float("fuelTime",0)
	meta:set_float("maxFuelTime",1)
	meta:set_float("srcTime",-1)
	meta:set_float("maxSrcTime",0)
	minetest.get_node_timer(pos):start(industrialtest.updateDelay)
end

ironFurnace.onTimer=function(pos,elapsed)
	local meta=minetest.get_meta(pos)
	local inv=meta:get_inventory()
	local srcSlot=inv:get_stack("src",1)
	local fuelSlot=inv:get_stack("fuel",1)
	local shouldUpdateFormspec=false
	local shouldRerunTimer=false

	if fuelSlot:get_count()>0 and meta:get_float("fuelTime")<=0 then
		local output,after=minetest.get_craft_result({
			method="cooking",
			width=1,
			items={srcSlot}
		})
		if output.time>0 and inv:room_for_item("dst",output.item) then
			output,after=minetest.get_craft_result({
				method="fuel",
				width=1,
				items={fuelSlot}
			})
			if output.time>0 then
				meta:set_float("fuelTime",output.time)
				meta:set_float("maxFuelTime",output.time)
				inv:set_stack("fuel",1,after.items[1])
				minetest.swap_node(pos,{
					name="industrialtest:iron_furnace_active",
					param2=minetest.get_node(pos).param2
				})
				minetest.get_node_timer(pos):start(industrialtest.updateDelay)
			end
		end
	end

	if shouldUpdateFormspec then
		meta:set_string("formspec",ironFurnace.getFormspec(meta:get_float("fuelTime")/meta:get_float("maxFuelTime")*100,meta:get_float("srcTime")/meta:get_float("maxSrcTime")*100))
	end

	return shouldRerunTimer
end

ironFurnace.activeOnTimer=function(pos,elapsed)
	local meta=minetest.get_meta(pos)
	local inv=meta:get_inventory()
	local srcSlot=inv:get_stack("src",1)
	local fuelSlot=inv:get_stack("fuel",1)
	local shouldUpdateFormspec=false
	local shouldRerunTimer=false

	if fuelSlot:get_count()>0 and meta:get_float("fuelTime")<=0 then
		local output,after=minetest.get_craft_result({
			method="cooking",
			width=1,
			items={srcSlot}
		})
		if output.time>0 and inv:room_for_item("dst",output.item) then
			output,after=minetest.get_craft_result({
				method="fuel",
				width=1,
				items={fuelSlot}
			})
			if output.time>0 then
				meta:set_float("fuelTime",output.time)
				meta:set_float("maxFuelTime",output.time)
				inv:set_stack("fuel",1,after.items[1])
			end
		end
	end
	if srcSlot:get_count()>0 and meta:get_float("maxSrcTime")<=0 and meta:get_float("fuelTime")>0 then
		local output,after=minetest.get_craft_result({
				method="cooking",
				width=1,
				items={srcSlot}
		})
		if output.time>0 and inv:room_for_item("dst",output.item) then
			meta:set_float("srcTime",0)
			meta:set_float("maxSrcTime",output.time*0.7)
		end
	end
	if meta:get_float("maxSrcTime")>0 then
		if meta:get_float("fuelTime")>0 then
			meta:set_float("srcTime",meta:get_float("srcTime")+elapsed)
		else
			meta:set_float("srcTime",0)
			minetest.swap_node(pos,{
				name="industrialtest:iron_furnace",
				param2=minetest.get_node(pos).param2
			})
			minetest.get_node_timer(pos):start(industrialtest.updateDelay)
		end
		shouldUpdateFormspec=true
		shouldRerunTimer=true
	elseif meta:get_float("fuelTime")<=0 then
		minetest.swap_node(pos,{
			name="industrialtest:iron_furnace",
			param2=minetest.get_node(pos).param2
		})
		minetest.get_node_timer(pos):start(industrialtest.updateDelay)
	end
	if meta:get_float("fuelTime")>0 then
		meta:set_float("fuelTime",meta:get_float("fuelTime")-elapsed)
		shouldUpdateFormspec=true
		shouldRerunTimer=true
	end
	if meta:get_float("srcTime")>=meta:get_float("maxSrcTime") then
		local output,after=minetest.get_craft_result({
				method="cooking",
				width=1,
				items={srcSlot}
		})
		if output.item:get_count()>0 then
			inv:set_stack("src",1,after.items[1])
			inv:add_item("dst",output.item)
			meta:set_float("srcTime",-1)
			meta:set_float("maxSrcTime",0)
		end
	end

	if shouldUpdateFormspec then
		meta:set_string("formspec",ironFurnace.getFormspec(meta:get_float("fuelTime")/meta:get_float("maxFuelTime")*100,meta:get_float("srcTime")/meta:get_float("maxSrcTime")*100))
	end

	return shouldRerunTimer
end

ironFurnace.allowMetadataInventoryMove=function(pos,fromList,fromIndex,toList,toIndex,count)
	if toList=="dst" then
		return 0
	end
	return count
end

ironFurnace.allowMetadataInventoryPut=function(pos,listname,index,stack)
	if listname=="dst" then
		return 0
	elseif listname=="src" then
		local meta=minetest.get_meta(pos)
		local inv=meta:get_inventory()
		local srcSlot=inv:get_stack("src",1)
		if srcSlot:get_name()~=stack:get_name() then
			meta:set_float("srcTime",-1)
			meta:set_float("maxSrcTime",0)
		end
	end
	return stack:get_count()
end

ironFurnace.allowMetadataInventoryTake=function(pos,listname,index,stack)
	local meta=minetest.get_meta(pos)
	local inv=meta:get_inventory()
	local srcSlot=inv:get_stack("src",1)
	local dstSlot=inv:get_stack("dst",1)
	if listname=="src" and stack:get_count()==srcSlot:get_count() then
		meta:set_float("srcTime",-1)
		meta:set_float("maxSrcTime",0)
		if meta:get_float("maxFuelTime")>0 then
			meta:set_string("formspec",ironFurnace.getFormspec(meta:get_float("fuelTime")/meta:get_float("maxFuelTime")*100,0))
		end
	elseif listname=="dst" and dstSlot:get_free_space()==0 then
		minetest.get_node_timer(pos):start(industrialtest.updateDelay)
	end
	return stack:get_count()
end

ironFurnace.onMetadataInventoryMove=function(pos,fromList,fromIndex,toList,toIndex,count)
	local meta=minetest.get_meta(pos)
	local inv=meta:get_inventory()
	local srcSlot=inv:get_stack("src",1)
	local dstSlot=inv:get_stack("dst",1)
	if fromList=="src" and count==srcSlot:get_count() then
		meta:set_float("srcTime",-1)
		meta:set_float("maxSrcTime",0)
		if meta:get_float("maxFuelTime")>0 then
			meta:set_string("formspec",ironFurnaceFormspec(meta:get_float("fuelTime")/meta:get_float("maxFuelTime")*100,0))
		end
	elseif fromList=="dst" and dstSlot:get_free_space()==0 then
		minetest.get_node_timer(pos):start(industrialtest.updateDelay)
	end
end

ironFurnace.onMetadataInventoryPut=function(pos,listname,index,stack)
	minetest.get_node_timer(pos):start(industrialtest.updateDelay)
end

local definition={
	description=S("Iron Furnace"),
	tiles={
		"industrialtest_machine_block.png",
		"industrialtest_machine_block.png",
		"industrialtest_machine_block.png",
		"industrialtest_machine_block.png",
		"industrialtest_machine_block.png",
		"industrialtest_machine_block.png^industrialtest_iron_furnace_front.png",
		"industrialtest_machine_block.png"
	},
	paramtype2="facedir",
	legacy_facedir_simple=true,
	on_construct=ironFurnace.onConstruct,
	on_timer=ironFurnace.onTimer,
	allow_metadata_inventory_move=ironFurnace.allowMetadataInventoryMove,
	allow_metadata_inventory_put=ironFurnace.allowMetadataInventoryPut,
	allow_metadata_inventory_take=ironFurnace.allowMetadataInventoryTake,
	on_metadata_inventory_move=ironFurnace.onMetadataInventoryMove,
	on_metadata_inventory_put=ironFurnace.onMetadataInventoryPut
}
if industrialtest.mtgAvailable then
	definition.groups={
		cracky=1,
		level=2
	}
	definition.sounds=default.node_sound_metal_defaults()
	definition.can_dig=function(pos)
		local meta=minetest.get_meta(pos)
		local inv=meta:get_inventory()
		return not (inv:get_list("src")[1]:get_count()>0 or inv:get_list("fuel")[1]:get_count()>0 or inv:get_list("dst")[1]:get_count()>0)
	end
elseif industrialtest.mclAvailable then
	definition.groups={
		pickaxey=1,
		container=2
	}
	definition.after_dig_node=function(pos,oldnode,oldmeta)
		industrialtest.internal.mclAfterDigNode(pos,oldmeta,{"src","fuel","dst"})
	end
	definition.sounds=mcl_sounds.node_sound_metal_defaults()
	definition._mcl_blast_resistance=3
	definition._mcl_hardness=3.5
	definition._mcl_hoppers_on_try_pull = mcl_furnaces.hoppers_on_try_pull
	definition._mcl_hoppers_on_try_push = mcl_furnaces.hoppers_on_try_push
	definition._mcl_hoppers_on_after_push = function(pos)
		minetest.get_node_timer(pos):start(industrialtest.updateDelay)
	end
end
minetest.register_node("industrialtest:iron_furnace",definition)
definition=table.copy(definition)
definition.description=nil
definition.tiles={
	"industrialtest_machine_block.png",
	"industrialtest_machine_block.png",
	"industrialtest_machine_block.png",
	"industrialtest_machine_block.png",
	"industrialtest_machine_block.png",
	"industrialtest_machine_block.png^industrialtest_iron_furnace_front_active.png",
	"industrialtest_machine_block.png"
}
definition.light_source=8
definition.drop="industrialtest:iron_furnace"
definition.on_timer=ironFurnace.activeOnTimer
if industrialtest.mclAvailable then
	definition.groups={
		not_in_creative_inventory=1,
		pickaxey=1,
		container=2
	}
	definition._doc_items_create_entry=false
end
minetest.register_node("industrialtest:iron_furnace_active",definition)
minetest.register_craft({
	type="shaped",
	output="industrialtest:iron_furnace",
	recipe={
		{industrialtest.elementKeys.ironIngot,industrialtest.elementKeys.ironIngot,industrialtest.elementKeys.ironIngot},
		{industrialtest.elementKeys.ironIngot,"",industrialtest.elementKeys.ironIngot},
		{industrialtest.elementKeys.ironIngot,industrialtest.elementKeys.ironIngot,industrialtest.elementKeys.ironIngot}
	}
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:iron_furnace",
	recipe={
		{"",industrialtest.elementKeys.ironIngot,""},
		{industrialtest.elementKeys.ironIngot,"",industrialtest.elementKeys.ironIngot},
		{industrialtest.elementKeys.ironIngot,industrialtest.elementKeys.furnace,industrialtest.elementKeys.ironIngot}
	}
})
