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

-- Rotary Macerator
local override={
	mesecons={
		effector={
			action_on=function(pos,node)
				if node.name~="industrialtest:rotary_macerator" then
					return
				end

				local meta=minetest.get_meta(pos)
				meta:set_int("maintainSpeed",1)

				local def=minetest.registered_nodes[node.name]
				def._industrialtest_updateFormspec(pos)

				minetest.get_node_timer(pos):start(industrialtest.updateDelay)
			end,
			action_off=function(pos,node)
				local meta=minetest.get_meta(pos)
				meta:set_int("maintainSpeed",0)

				local def=minetest.registered_nodes[node.name]
				def._industrialtest_updateFormspec(pos)
			end
		}
	}
}

minetest.override_item("industrialtest:rotary_macerator",override)
minetest.override_item("industrialtest:rotary_macerator_active",override)

-- Nuclear Reactor
override={
	mesecons={
		effector={
			action_on=function(pos,node)
				local isChamber=node.name=="industrialtest:nuclear_reactor_chamber"
				if node.name~="industrialtest:nuclear_reactor" and not isChamber then
					return
				end

				local originalPos
				local meta=minetest.get_meta(pos)
				meta:set_int("meseconPowered",1)
				if isChamber then
					originalPos=pos
					pos=minetest.deserialize(meta:get_string("reactor"))
					node=minetest.get_node(pos)
					meta=minetest.get_meta(pos)
				end

				meta:set_int("enabled",1)
				meta:set_int("stateChanged",1)

				local def=minetest.registered_nodes[node.name]
				def._industrialtest_updateFormspec(pos)

				if isChamber then
					def._industrialtest_synchronizeToChamber(originalPos)
				end

				minetest.get_node_timer(pos):start(industrialtest.updateDelay)
			end,
			action_off=function(pos,node)
				local isChamber=node.name=="industrialtest:nuclear_reactor_chamber"

				local originalPos
				local meta=minetest.get_meta(pos)
				meta:set_int("meseconPowered",0)
				if isChamber then
					originalPos=pos
					pos=minetest.deserialize(meta:get_string("reactor"))
					node=minetest.get_node(pos)
					meta=minetest.get_meta(pos)
				end

				if meta:get_int("meseconPowered")==1 then
					return
				end
				if meta:contains("chambers") then
					local chambers=minetest.deserialize(meta:get_string("chambers"))
					for _,chamber in ipairs(chambers) do
						local chamberMeta=minetest.get_meta(chamber)
						if chamberMeta:get_int("meseconPowered")==1 then
							return
						end
					end
				end

				meta:set_int("enabled",0)
				meta:set_int("stateChanged",1)

				local def=minetest.registered_nodes[node.name]
				def._industrialtest_updateFormspec(pos)

				if isChamber then
					def._industrialtest_synchronizeToChamber(originalPos)
				end
			end
		}
	}
}

minetest.override_item("industrialtest:nuclear_reactor",override)
minetest.override_item("industrialtest:nuclear_reactor_active",override)

-- Nuclear Reactor Chamber
minetest.override_item("industrialtest:nuclear_reactor_chamber",override)
