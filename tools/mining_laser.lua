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

local beam={}

beam.onActivate=function(self,staticdata)
	local data=minetest.deserialize(staticdata)
	self.direction=data.direction
	self.energy=data.energy
	self.distance=data.distance
	self.startPos=self.object:get_pos()
	self.mode=data.mode
	self.user=data.user
end

beam.onPunch=function()
	return true
end

beam.onNodeBreak=function(pos,node,user)
	if industrialtest.mclAvailable then
		local drops=minetest.get_node_drops(node.name,"")
		for _, val in ipairs(drops) do
			if type(val)~="string" then
				val=val:get_name()..val:get_count()
			end
			minetest.add_item(pos,val)
		end
	end
	minetest.node_dig(pos,node,user)
end

beam.onStep=function(self,dtime,moveresult)
	local pos=self.object:get_pos()
	if vector.distance(self.startPos,pos)>=self.distance or self.energy<=0 then
		self.object:remove()
		return
	end
	local speed=400*dtime
	self.object:set_velocity(vector.multiply(self.direction,vector.new(speed,speed,speed)))
	if moveresult.collides then
		for _,val in ipairs(moveresult.collisions) do
			if val.type=="node" then
				if self.mode>=1 and self.mode<=3 then
					local nodeUnbreakable=false
					local node=minetest.get_node(val.node_pos)
					local def=minetest.registered_nodes[node.name]
					if industrialtest.mclAvailable then
						nodeUnbreakable=def._mcl_hardness==-1
					end
					if nodeUnbreakable then
						self.object:remove()
						return
					else
						beam.onNodeBreak(val.node_pos,node,minetest.get_player_by_name(self.user))
						self.energy=self.energy-1
					end
				elseif self.mode==4 then
					industrialtest.internal.explode(pos,4,1)
					self.object:remove()
					return
				end
			end
		end
	end
end

minetest.register_entity("industrialtest:mining_laser_beam",{
	initial_properties={
		physical=true,
		collide_with_objects=false,
		collisionbox={
			-0.25,-0.25,-0.25,
			0.25,0.25,0.25
		},
		pointable=false,
		visual="cube",
		visual_size={x=0.25,y=0.25,z=0.25},
		textures={
			"industrialtest_mining_laser_beam.png",
			"industrialtest_mining_laser_beam.png",
			"industrialtest_mining_laser_beam.png",
			"industrialtest_mining_laser_beam.png",
			"industrialtest_mining_laser_beam.png",
			"industrialtest_mining_laser_beam.png"
		},
		glow=-1,
		static_save=false,
		shaded=false,
	},
	on_activate=beam.onActivate,
	on_punch=beam.onPunch,
	on_step=beam.onStep
})

local miningLaser={}
miningLaser.mode1OpPower=1250
miningLaser.mode2OpPower=100
miningLaser.mode4OpPower=5000
miningLaser.modeCount=4

miningLaser.getMode=function(itemstack)
	local meta=itemstack:get_meta()
	if not meta:contains("mode") then
		meta:set_int("mode",1)
		return 1
	end
	return meta:get_int("mode")
end

miningLaser.setMode=function(itemstack,mode)
	local meta=itemstack:get_meta()
	meta:set_int("mode",mode)
	meta:set_string("industrialtest.descriptionOverride",S("Mining Laser (Mode @1)",mode))
	industrialtest.api.updateItemPowerText(itemstack)
end

miningLaser.spawnBeam=function(itemstack,user,pos,dir,opPower,energy,distance)
	local meta=itemstack:get_meta()
	if meta:get_int("industrialtest.powerAmount")<opPower then
		return false
	end
	minetest.add_entity(pos+vector.new(0,1.5,0),"industrialtest:mining_laser_beam",minetest.serialize({
		direction=dir,
		energy=energy,
		distance=distance,
		mode=miningLaser.getMode(itemstack),
		user=user:get_player_name()
	}))
	industrialtest.api.addPowerToItem(itemstack,-opPower)
	return true
end

miningLaser.onUse=function(itemstack,user)
	if not user:is_player() then
		return nil
	end
	local mode=miningLaser.getMode(itemstack)
	local control=user:get_player_control()
	if control.sneak then
		mode=mode+1
		if mode>=miningLaser.modeCount+1 then
			mode=1
		end
		miningLaser.setMode(itemstack,mode)
		return itemstack
	end
	local meta=itemstack:get_meta()
	if mode==1 then
		if not miningLaser.spawnBeam(itemstack,user,user:get_pos(),user:get_look_dir(),miningLaser.mode1OpPower,10,64) then
			return nil
		end
	elseif mode==2 then
		if not miningLaser.spawnBeam(itemstack,user,user:get_pos(),user:get_look_dir(),miningLaser.mode2OpPower,3,2) then
			return nil
		end
	elseif mode==3 then
		local yaw=user:get_look_horizontal()
		local dir=vector.new(-math.sin(yaw),0,math.cos(yaw))
		if not miningLaser.spawnBeam(itemstack,user,user:get_pos(),dir,miningLaser.mode1OpPower,10,64) then
			return nil
		end
	elseif mode==4 then
		if not miningLaser.spawnBeam(itemstack,user,user:get_pos(),user:get_look_dir(),miningLaser.mode4OpPower,1,64) then
			return nil
		end
	end
	return itemstack
end

minetest.register_tool("industrialtest:mining_laser",{
	description=S("Mining Laser (Mode 1)"),
	inventory_image="industrialtest_mining_laser.png",
	on_use=miningLaser.onUse,
	_industrialtest_powerStorage=true,
	_industrialtest_powerCapacity=300000,
	_industrialtest_powerFlow=industrialtest.api.hvPowerFlow
})
minetest.register_craft({
	type="shaped",
	output="industrialtest:mining_laser",
	recipe={
		{industrialtest.elementKeys.powerCarrier,industrialtest.elementKeys.powerCarrier,"industrialtest:energy_crystal"},
		{"industrialtest:advanced_alloy","industrialtest:advanced_alloy","industrialtest:advanced_electronic_circuit"},
		{"","industrialtest:advanced_alloy","industrialtest:advanced_alloy"}
	}
})
