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

industrialtest.api={}
industrialtest.api.maceratorRecipes={}
industrialtest.api.compressorRecipes={}
industrialtest.api.extractorRecipes={}
industrialtest.api.cableFormerRecipes={}
industrialtest.api.geothermalGeneratorFuels={}
industrialtest.api.waterMillFuels={}
industrialtest.api.rotaryMaceratorModifiers={}
industrialtest.api.storageCells={}

industrialtest.api.lvPowerFlow=600
industrialtest.api.mvPowerFlow=2400
industrialtest.api.hvPowerFlow=10200
industrialtest.api.evPowerFlow=40800
industrialtest.api.ivPowerFlow=163800

industrialtest.internal.clamp=function(num,min,max)
	return math.max(math.min(num,max),min)
end

-- \brief Adds power storage to metadata
-- \param capacity How much EU item/node can store
-- \param flow How much EU can flow in or out item/node per industrialtest.updateDelay
-- \param ioConfig Input/Output configuration in following side order: -X, +X, -Y, +Y, -Z, +Z
--                 a - bidirectional, i - input, o - output
-- \returns nil
industrialtest.api.addPowerStorage=function(meta,capacity,flow,ioConfig)
	meta:set_int("industrialtest.powerCapacity",capacity)
	meta:set_int("industrialtest.powerFlow",flow)
	meta:set_int("industrialtest.powerAmount",0)
	meta:set_string("industrialtest.ioConfig",ioConfig)
end
-- \brief Takes rotated node and side and outputs normalized side that can be used for ioConfig lookups
-- \param pos Vector with node position
-- \param side Node side. See industrialtest.api.addPowerStorage for possible values
-- \returns Normalized side or in case of failure side argument back
industrialtest.api.normalizeSide=function(pos,side)
	local node=minetest.get_node(pos)
	-- FIXME: improve code quality there
	local translation={
		[0]={
			1,2,3,4,5,6
		},
		[1]={
			5,6,3,4,2,1
		},
		[2]={
			2,1,3,4,6,5
		},
		[3]={
			6,5,3,4,1,2
		}
	}
	if node.param2>3 then
		return side
	end
	return translation[node.param2][side]
end
-- \brief Checks if metadata contains power storage
-- \param meta MetaDataRef which should be checked
-- \returns true if metadata contains power storage, false otherwise
industrialtest.api.hasPowerStorage=function(meta)
	local values={"industrialtest.powerCapacity","industrialtest.powerFlow","industrialtest.powerAmount","industrialtest.ioConfig"}
	for _,value in ipairs(values) do
		if not meta:contains(value) then
			return false
		end
	end
	return true
end
-- \brief Updates itemstack description to show current power storage information, additionally updates item wear bar.
--        Function doesn't check if itemstack contains power storage so you should be sure that it does before calling this function
-- \param itemstack ItemStack which should be updated
-- \returns nil
industrialtest.api.updateItemPowerText=function(itemstack)
	local meta=itemstack:get_meta()
	local def=minetest.registered_tools[itemstack:get_name()]
	local desc=meta:contains("industrialtest.descriptionOverride") and meta:get_string("industrialtest.descriptionOverride") or def.description
	meta:set_string("description",S("@1\n@2 / @3 EU",desc,meta:get_int("industrialtest.powerAmount"),meta:get_int("industrialtest.powerCapacity")))
	itemstack:set_wear(65535-meta:get_int("industrialtest.powerAmount")/meta:get_int("industrialtest.powerCapacity")*65534)
end
-- \brief Adds power storage to item depending on it's definition
-- \param itemstack ItemStack to which item storage should be added
-- \returns true if power storage was successfully added, false otherwise
industrialtest.api.preparePowerStorageItem=function(itemstack)
	local meta=itemstack:get_meta()
	local def=minetest.registered_tools[itemstack:get_name()]
	if industrialtest.api.hasPowerStorage(meta) or not def or not def._industrialtest_powerStorage or not def._industrialtest_powerCapacity or not def._industrialtest_powerFlow then
		return false
	end
	industrialtest.api.addPowerStorage(meta,def._industrialtest_powerCapacity,def._industrialtest_powerFlow,"n/a")
	industrialtest.api.updateItemPowerText(itemstack)
	return true
end
-- \brief Sets uses metadata value depending on item's definition
-- \param itemstack ItemStack which should be altered
-- \returns true if value was successfully added, false otherwise
industrialtest.api.prepareToolItem=function(itemstack)
	local def=minetest.registered_tools[itemstack:get_name()]
	if not def then
		return false
	end
	if def._industrialtest_tool and def.tool_capabilities and def.tool_capabilities.uses then
		local meta=itemstack:get_meta()
		meta:set_int("industrialtest.uses",def.tool_capabilities.uses)
		return true
	elseif def.groups and def.groups._industrialtest_emptyOnConstruct and itemstack:get_wear()==0 then
		itemstack:set_wear(65534)
		return true
	end
	return false
end
-- \brief Adds wear to item after it's use
-- \param itemstack ItemStack to which wear should be added
-- \returns nil
industrialtest.api.afterToolUse=function(itemstack)
	local meta=itemstack:get_meta()
	local def=minetest.registered_tools[itemstack:get_name()]
	if not def or not def._industrialtest_tool or not def.tool_capabilities or not def.tool_capabilities.uses then
		return
	end
	if not meta:contains("industrialtest.uses") then
		industrialtest.prepareToolItem(itemstack)
	end
	local uses=meta:get_int("industrialtest.uses")-1
	if uses==0 then
		itemstack:set_count(0)
		minetest.sound_play({name="default_tool_breaks"},{
			gain=1,
			fade=0,
			pitch=1
		},true)
		return
	end
	meta:set_int("industrialtest.uses",uses)
	itemstack:set_wear(65535-uses/def.tool_capabilities.uses*65535)
end

-- \brief Check if itemstack contains fluid storage
-- \param itemstack ItemStack
-- \returns bool
industrialtest.api.itemHasFluidStorage=function(itemstack)
	local values={"industrialtest.fluidAmount","industrialtest.fluidCapacity"}
	local meta=itemstack:get_meta()
	for _,value in ipairs(values) do
		if not meta:contains(value) then
			return false
		end
	end
	return true
end

-- \brief Updates itemstack description and wear depending on contained fluid
-- \param itemstack ItemStack
-- \returns nil
industrialtest.api.updateItemFluidText=function(itemstack)
	local meta=itemstack:get_meta()
	local def=itemstack:get_definition()
	meta:set_string("description",S("@1\n@2 / @3 mB",def.description,meta:get_int("industrialtest.fluidAmount"),meta:get_int("industrialtest.fluidCapacity")))
	itemstack:set_wear(65535-meta:get_int("industrialtest.fluidAmount")/meta:get_int("industrialtest.fluidCapacity")*65534)
end

-- \brief Prepares itemstack containing fluid storage
-- \param itemstack ItemStack
-- \returns bool
industrialtest.api.prepareFluidStorageItem=function(itemstack)
	local meta=itemstack:get_meta()
	local def=itemstack:get_definition()
	if industrialtest.api.itemHasFluidStorage(itemstack) or not def.groups or not def.groups._industrialtest_fluidStorage or not def._industrialtest_fluidCapacity then
		return false
	end
	meta:set_int("industrialtest.fluidAmount",0)
	meta:set_int("industrialtest.fluidCapacity",def._industrialtest_fluidCapacity)
	industrialtest.api.updateItemFluidText(itemstack)
	return true
end

-- \brief Adds fluid amount to item fluid storage
-- \param itemstack ItemStack
-- \param amount number
-- \returns number
industrialtest.api.addFluidToItem=function(itemstack,amount)
	local meta=itemstack:get_meta()
	if not industrialtest.api.itemHasFluidStorage(itemstack) then
		return 0
	end
	local fluidAmount=meta:get_int("industrialtest.fluidAmount")
	local fluidCapacity=meta:get_int("industrialtest.fluidCapacity")
	local prevFluidAmount=fluidAmount
	fluidAmount=industrialtest.internal.clamp(fluidAmount+amount,0,fluidCapacity)
	meta:set_int("industrialtest.fluidAmount",fluidAmount)
	industrialtest.api.updateItemFluidText(itemstack)
	return fluidAmount-prevFluidAmount
end

-- \brief Adds fluid to destination itemstack while subtracting it from source itemstack's metadata
-- \param srcItemstack ItemStack
-- \param itemstack ItemStack
-- \param amount number
-- \returns number
industrialtest.api.transferFluidToItem=function(srcItemstack,itemstack,amount)
	local meta=srcItemstack:get_meta()
	local flow=math.min(meta:get_int("industrialtest.fluidAmount"),amount)
	if flow==0 then
		return 0
	end
	local actualFlow=industrialtest.api.addFluidToItem(itemstack,flow)
	meta:set_int("industrialtest.fluidAmount",meta:get_int("industrialtest.fluidAmount")-actualFlow)
	industrialtest.api.updateItemFluidText(srcItemstack)
	return actualFlow
end

-- \brief Checks if power storage is fully charged
-- \param meta MetaDataRef which should be checked
-- \returns true if power storage is fully charged, false otherwise
industrialtest.api.isFullyCharged=function(meta)
	return meta:get_int("industrialtest.powerAmount")>=meta:get_int("industrialtest.powerCapacity")
end
-- \brief Adds power to power storage. Function doesn't check if meta contains power storage so you must be sure that it does.
-- \param meta MetaDataRef to which power should be added
-- \param amount Amount of power to add
-- \returns How much of power was actually added
industrialtest.api.addPower=function(meta,amount)
	local powerAmount=meta:get_int("industrialtest.powerAmount")
	local powerCapacity=meta:get_int("industrialtest.powerCapacity")
	local prevPowerAmount=powerAmount
	powerAmount=industrialtest.internal.clamp(powerAmount+amount,0,powerCapacity)
	meta:set_int("industrialtest.powerAmount",powerAmount)
	return powerAmount-prevPowerAmount
end
-- \brief Adds power to itemstack. Function checks if itemstack has power storage.
-- \param itemstack ItemStack to which add power
-- \param amount How much power to add
-- \returns Amount of power added
industrialtest.api.addPowerToItem=function(itemstack,amount)
	local meta=itemstack:get_meta()
	if not industrialtest.api.hasPowerStorage(meta) then
		return 0
	end
	local added=industrialtest.api.addPower(meta,amount)
	industrialtest.api.updateItemPowerText(itemstack)
	return added
end
-- \brief Adds power to destination metadata while subtracting it from source metadata
-- \Param srcMeta MetaDataRef from which take power
-- \param destMeta MetaDataRef to which add power
-- \returns How much of power was actually transferred
industrialtest.api.transferPower=function(srcMeta,destMeta,amount)
	local currentFlow=math.min(srcMeta:get_int("industrialtest.powerAmount"),amount)
	if currentFlow==0 then
		return 0
	end
	local actualFlow=industrialtest.api.addPower(destMeta,currentFlow)
	srcMeta:set_int("industrialtest.powerAmount",srcMeta:get_int("industrialtest.powerAmount")-actualFlow)
	return actualFlow
end
-- \brief Adds power to destination itemstack while subtracting it from source metadata
-- \param srcMeta MetaDataRef from which take power
-- \param itemstack ItemStack to which add power
-- \param amount number
-- \returns How much of power was actually transferred
industrialtest.api.transferPowerToItem=function(srcMeta,itemstack,amount)
	local currentFlow=math.min(srcMeta:get_int("industrialtest.powerAmount"),amount)
	if currentFlow==0 then
		return 0
	end
	local actualFlow=industrialtest.api.addPowerToItem(itemstack,currentFlow)
	srcMeta:set_int("industrialtest.powerAmount",srcMeta:get_int("industrialtest.powerAmount")-actualFlow)
	return actualFlow
end
-- \brief Adds power to destination metadata while subtracting it from source itemstack
-- \param srcItemstack ItemStack from which subtract power
-- \param meta MetaDataRef to which add power
-- \param amount How much power should be transferred
-- \returns How much of power was actually transferred
industrialtest.api.transferPowerFromItem=function(srcItemstack,meta,amount)
	local srcMeta=srcItemstack:get_meta()
	local currentFlow=math.min(srcMeta:get_int("industrialtest.powerAmount"),amount)
	if currentFlow==0 then
		return 0
	end
	local actualFlow=industrialtest.api.addPower(meta,currentFlow)
	industrialtest.api.addPowerToItem(srcItemstack,-actualFlow)
	return actualFlow
end

-- \brief Transfers power from source node to it's network, if sides is set then power will be only transfered to network connected to that sides
-- \param pos Vector with position of source node
-- \param (optional) sides table with Vectors
-- \param (optional) flowOverride number
-- \returns two values: true if any neighbouring node has room for more power, false otherwise
--                      true if any power was transferred, false otherwise
industrialtest.api.powerFlow=function(pos,sides,flowOverride)
	local meta=minetest.get_meta(pos)
	-- if machine doesn't have network map then it's not capable of transferring power
	local network=industrialtest.api.getNetwork(meta)
	if not network or #network==0 then
		return false,false
	end
	local endpointCount=0
	for _,endpoint in ipairs(network) do
		local endpointMeta=minetest.get_meta(endpoint.position)
		if not industrialtest.api.isFullyCharged(endpointMeta) and (not sides or sides[endpoint.sourceSide]) then
			endpointCount=endpointCount+1
		end
	end
	if endpointCount==0 then
		return false,false
	end
	local powerDistribution=math.floor((flowOverride and flowOverride or meta:get_int("industrialtest.powerFlow"))/endpointCount)
	local transferred=false
	local roomAvailable=false
	for _,endpoint in ipairs(network) do
		if not sides or sides[endpoint.sourceSide] then
			local endpointMeta=minetest.get_meta(endpoint.position)
			if powerDistribution<=endpoint.flow then
				local transferredPower=industrialtest.api.transferPower(meta,endpointMeta,powerDistribution)
				if transferredPower>0 then
					transferred=true
				end
				local def=minetest.registered_nodes[minetest.get_node(endpoint.position).name]
				if def then
					local updateFormspec=def._industrialtest_updateFormspec
					if updateFormspec then
						updateFormspec(endpoint.position)
					end
					local onPowerFlow=def._industrialtest_onPowerFlow
					if onPowerFlow and transferredPower>0 then
						onPowerFlow(endpoint.position,industrialtest.api.getOppositeSide(endpoint.side),transferredPower)
					end
				end
				minetest.get_node_timer(endpoint.position):start(industrialtest.updateDelay)
				if not industrialtest.api.isFullyCharged(endpointMeta) then
					roomAvailable=true
				end
			else
				minetest.remove_node(endpoint.position)
				industrialtest.internal.explode(endpoint.position,2)
			end
		end
	end
	return roomAvailable,transferred
end

local function addNodeToNetwork(pos,networkMasterPos)
	local meta=minetest.get_meta(pos)
	local networks={}
	if meta:contains("industrialtest.networks") then
		networks=minetest.deserialize(meta:get_string("industrialtest.networks"))
	end
	for _,network in ipairs(networks) do
		if network.x==networkMasterPos.x and network.y==networkMasterPos.y and network.z==networkMasterPos.z then
			return
		end
	end
	table.insert(networks,networkMasterPos)
	meta:set_string("industrialtest.networks",minetest.serialize(networks))
end

local function clampFlow(pos,flow)
	local def=minetest.registered_nodes[minetest.get_node(pos).name]
	local newFlow
	if def.groups and def.groups._industrialtest_cable then
		newFlow=def._industrialtest_cableFlow
	else
		local meta=minetest.get_meta(pos)
		newFlow=meta:get_int("industrialtest.powerFlow")
	end
	return math.min(flow,newFlow)
end

-- \brief Creates network map starting from node at pos, optionally omitting node at omit
-- \param pos vector
-- \param (optional) addCables bool
-- \param (optional) omit Vector
-- \returns table with network map
industrialtest.api.createNetworkMap=function(pos,addCables,omit)
	local workers={}
	local map={}
	local connections=industrialtest.api.getConnections(pos,"i")
	if #connections==0 then
		return map
	end
	local sides={
		["-1,0,0"]=1,
		["1,0,0"]=2,
		["0,-1,0"]=3,
		["0,1,0"]=4,
		["0,0,-1"]=5,
		["0,0,1"]=6
	}
	local serializedSourcePos=pos.x..","..pos.y..","..pos.z
	local visitedNodes={[serializedSourcePos]=true}
	for _,conn in ipairs(connections) do
		if not omit or conn.x~=omit.x or conn.y~=omit.y or conn.z~=omit.z then
			visitedNodes[conn.x..","..conn.y..","..conn.z]=true
			addNodeToNetwork(conn,pos)
			local sideVector=vector.subtract(conn,pos)
			local serializedSideVector=sideVector.x..","..sideVector.y..","..sideVector.z
			local def=minetest.registered_nodes[minetest.get_node(conn).name]
			if def.groups._industrialtest_cable then
				table.insert(workers,{
					position=conn,
					targetPosition=conn,
					distance=1,
					flow=def._industrialtest_cableFlow,
					targetFlow=0,
					sourceSide=industrialtest.api.normalizeSide(pos,sides[serializedSideVector])
				})
				if addCables then
					table.insert(map,{
						position=conn,
						distance=0
					})
				end
			else
				local meta=minetest.get_meta(conn)
				table.insert(map,{
					position=conn,
					distance=0,
					flow=meta:get_int("industrialtest.powerFlow"),
					side=sides[serializedSideVector],
					sourceSide=industrialtest.api.normalizeSide(pos,sides[serializedSideVector])
				})
			end
		end
	end
	while #workers>0 do
		for i=1,#workers do
			local worker=workers[i]
			connections=industrialtest.api.getConnections(worker.position,"i")
			if #connections==0 then
				table.remove(workers,i)
				break
			else
				local directionAssigned=false
				local foundNewNode=false
				for _,conn in ipairs(connections) do
					if not omit or conn.x~=omit.x or conn.y~=omit.y or conn.z~=omit.z then
						local serializedPos=conn.x..","..conn.y..","..conn.z
						if not visitedNodes[serializedPos] then
							local def=minetest.registered_nodes[minetest.get_node(conn).name]
							visitedNodes[serializedPos]=true
							foundNewNode=true
							addNodeToNetwork(conn,pos)
							if def.groups._industrialtest_cable then
								if directionAssigned then
									table.insert(workers,{
										position=conn,
										targetPosition=conn,
										distance=worker.distance+1,
										flow=clampFlow(conn,worker.flow),
										targetFlow=0,
										sourceSide=worker.sourceSide
									})
								else
									worker.targetPosition=conn
									worker.distance=worker.distance+1
									worker.targetFlow=clampFlow(conn,worker.flow)
									directionAssigned=true
								end
								if addCables then
									table.insert(map,{
										position=conn,
										distance=worker.distance+1,
									})
								end
							else
								local sideVector=vector.subtract(conn,worker.position)
								table.insert(map,{
									position=conn,
									distance=worker.distance,
									flow=clampFlow(conn,worker.flow),
									side=sides[sideVector.x..","..sideVector.y..","..sideVector.z],
									sourceSide=worker.sourceSide
								})
								if #connections==1 then
									foundNewNode=false
									break
								end
							end
						end
					end
				end
				if not foundNewNode then
					table.remove(workers,i)
					break
				end
				worker.position=worker.targetPosition
				worker.flow=worker.targetFlow
			end
		end
	end
	return map
end

industrialtest.api.removeNodeFromNetwork=function(pos,nodePos)
	local meta=minetest.get_meta(pos)
	if not meta:contains("industrialtest.network") then
		return
	end
	local network=minetest.deserialize(meta:get_string("industrialtest.network"))
	local removed=false
	for key,node in ipairs(network) do
		if node.position.x==nodePos.x and node.position.y==nodePos.y and node.position.z==nodePos.z then
			table.remove(network,key)
			removed=true
			break
		end
	end
	if removed then
		meta:set_string("industrialtest.network",minetest.serialize(network))
	end
end

-- \brief Creates network map and writes it to node metadata at pos, optionally omitting node at omit
-- \param pos Vector
-- \param (optional) omit Vector
-- \returns nil
industrialtest.api.createNetworkMapForNode=function(pos,omit)
	local meta=minetest.get_meta(pos)
	local network=industrialtest.api.createNetworkMap(pos,false,omit)
	meta:set_string("industrialtest.network",minetest.serialize(network))
end

-- \brief Returns true if meta contains network map, false otherwise
-- \param meta MetaDataRef
-- \returns bool
industrialtest.api.isNetworkMaster=function(meta)
	return meta:contains("industrialtest.network")
end

-- \brief Returns network table if node containing meta belongs to any networks, false otherwise
-- \param meta MetaDataRef
-- \returns bool or table
industrialtest.api.isAttachedToNetwork=function(meta)
	if not meta:contains("industrialtest.networks") then
		return false
	end
	local networks=minetest.deserialize(meta:get_string("industrialtest.networks"))
	if #networks==0 then
		return false
	end
	return networks
end

-- \brief Returns network master network from it's meta, if meta doesn't contain network map then function returns false
-- \param meta MetaDataRef
-- \returns table or bool
industrialtest.api.getNetwork=function(meta)
	if not meta:contains("industrialtest.network") then
		return false
	end
	return minetest.deserialize(meta:get_string("industrialtest.network"))
end

-- \brief Returns opposite side of provided one
-- \param side Side number. See industrialtest.api.addPowerStorage for order
-- \returns Opposite side
industrialtest.api.getOppositeSide=function(side)
	return (side%2==0 and side-1 or side+1)
end
-- \brief Returns connections of node with power storage. If direction is "i" only input connections will be returned, if direction is "o" only output connections
--        will be returned, if it's not provided all connections will be returned.
-- \param pos Vector
-- \param (optional) direction string
-- \returns table
industrialtest.api.getConnections=function(pos,direction)
	local result={}
	local neighbourPositions={
		vector.offset(pos,-1,0,0),
		vector.offset(pos,1,0,0),
		vector.offset(pos,0,-1,0),
		vector.offset(pos,0,1,0),
		vector.offset(pos,0,0,-1),
		vector.offset(pos,0,0,1)
	}
	local sourceMeta=minetest.get_meta(pos)
	local sourceDef=minetest.registered_nodes[minetest.get_node(pos).name]
	local directionOutput=(not direction or direction=="o")
	local directionInput=(not direction or direction=="i")
	for key,conn in ipairs(neighbourPositions) do
		local meta=minetest.get_meta(conn)
		local def=minetest.registered_nodes[minetest.get_node(conn).name]
		local normalizedKey=industrialtest.api.normalizeSide(pos,key)
		local powerOutput=(sourceDef.groups._industrialtest_cable or industrialtest.api.isPowerOutput(sourceMeta,normalizedKey))
		local powerInput=(sourceDef.groups._industrialtest_cable or industrialtest.api.isPowerInput(sourceMeta,normalizedKey))
		if def.groups._industrialtest_cable or industrialtest.api.hasPowerStorage(meta) then
			local side=industrialtest.api.normalizeSide(conn,industrialtest.api.getOppositeSide(normalizedKey))
			if (powerOutput and directionInput and (def.groups._industrialtest_cable or industrialtest.api.isPowerInput(meta,side))) or ((def.groups._industrialtest_cable or industrialtest.api.isPowerOutput(meta,side)) and powerInput and directionOutput) then
				table.insert(result,conn)
			end
		end
	end
	return result
end
-- \brief Changes node's power IO config. Function doesn't check if meta actually contains power storage.
-- \param meta MetaDataRef of node which power IO config should be changed
-- \param side Side number. See industrialtest.api.addPowerStorage to check order.
-- \param mode Side mode. See industrialtest.api.addPowerStorage for possible values.
-- \returns nil
industrialtest.api.changeIoConfig=function(meta,side,mode)
	local ioConfig=meta:get_string("industrialtest.ioConfig")
	ioConfig=string.sub(ioConfig,1,side-1)..mode..string.sub(ioConfig,side+1)
	meta:set_string("industrialtest.ioConfig",ioConfig)
end
-- \brief Checks if provided side is power input
-- \param meta MetaDataRef of node
-- \param side Side number. See industrialtest.api.addPowerStorage to check order.
-- \returns true if provided side is power input, false otherwise
industrialtest.api.isPowerInput=function(meta,side)
	local ioConfig=meta:get_string("industrialtest.ioConfig")
	local mode=string.sub(ioConfig,side,side)
	return (mode=="i" or mode=="a")
end
-- \brief Checks if provided side is power output
-- \param meta MetaDataRef of node
-- \param side Side number. See industrialtest.api.addPowerStorage to check order.
-- \returns true if provided side is power output, false otherwise
industrialtest.api.isPowerOutput=function(meta,side)
	local ioConfig=meta:get_string("industrialtest.ioConfig")
	local mode=string.sub(ioConfig,side,side)
	return (mode=="o" or mode=="a")
end
-- \brief Registers dust of certain resource
-- \param name Technical name of resource
-- \param displayName Display name of resource
-- \param resources List of tables with following keys: <output>, <recipe>, [count(1)]
--                                                      <> - required, [] - optional, () - default value
-- \param color HTML color of dust
-- \param registerMaceratorRecipe If true macerator recipe for dust will be registered
-- \returns nil
industrialtest.api.registerResourceDust=function(name,displayName,resources,color,registerMaceratorRecipe)
	minetest.register_craftitem("industrialtest:"..name.."_dust",{
		description=S(displayName.." Dust"),
		inventory_image="industrialtest_dust.png",
		color=color
	})
	if registerMaceratorRecipe then
		for _,value in ipairs(resources) do
			industrialtest.api.registerMaceratorRecipe({
				output="industrialtest:"..name.."_dust "..(value.count or 1),
				recipe=value.resource
			})
		end
	end
end
-- \brief Registers plate of certain resource
-- \param name Technical name of resource
-- \param displayName Display name of resource
-- \param resources List of tables with following keys: <output>, <recipe>, [count(1)]
--                                                      <> - required, [] - optional, () - default value
-- \param color HTML color of plate
-- \param registerCompressorRecipe If true compressor recipe for plate will be registered
-- \returns nil
industrialtest.api.registerPlate=function(name,displayName,resources,color,registerCompressorRecipe)
	minetest.register_craftitem("industrialtest:"..name,{
		description=displayName,
		inventory_image="industrialtest_plate.png",
		inventory_overlay="industrialtest_plate_overlay.png",
		color=color
	})
	if registerCompressorRecipe then
		for _,value in ipairs(resources) do
			industrialtest.api.registerCompressorRecipe({
				output="industrialtest:"..name.." "..(value.count or 1),
				recipe=value.resource
			})
		end
	end
end
-- \brief Registers cell with certain fluid
-- \param name Technical name of cell
-- \param displayName Display name of cell
-- \param node Node which can be picked up with this cell
-- \returns nil
industrialtest.api.registerStorageCell=function(name,displayName,node,modname,color)
	color = color or "#ffffffff"
	if not modname then
		modname="industrialtest"
	end
	minetest.register_craftitem("industrialtest:"..name.."_cell",{
		description=S(displayName.." Cell"),
		inventory_image="industrialtest_cell_fluid.png",
		inventory_overlay="industrialtest_cell_casing.png",
		color=color,
		on_place=function(itemstack,user,pointed)
			if pointed.type~="node" or not user or not user:is_player() then
				return nil
			end
			local node=minetest.get_node_or_nil(pointed.above)
			local storage=industrialtest.api.getStorageCell("industrialtest:"..name.."_cell")
			if storage.node then
				if node.name~="air" and node.name~=storage.node then
					return nil
				end
				minetest.set_node(pointed.above,{name=storage.node})
				if itemstack:get_count()==1 then
					itemstack:set_name("industrialtest:empty_cell")
				else
					local inv=user:get_inventory()
					inv:add_item("main",ItemStack("industrialtest:empty_cell"))
					itemstack:take_item()
				end
				return itemstack
			end
			return nil
		end
	})
	industrialtest.api.storageCells["industrialtest:"..name.."_cell"]={
		name="industrialtest:"..name.."_cell",
		node=node
	}
end
-- \brief Returns registred storage cell by name
-- \param name Storage cell name
-- \returns Table with following keys: name, node or nil in case of failure
industrialtest.api.getStorageCell=function(name)
	return industrialtest.api.storageCells[name]
end
-- \brief Returns registered storage cells by node
-- \param node Node ID
-- \returns Table with following keys: name, node or nil in case of failure
industrialtest.api.getStorageCellByNode=function(node)
	for _,value in pairs(industrialtest.api.storageCells) do
		if value.node==node then
			return value
		end
	end
	return nil
end
-- \brief Registers macerator recipe
-- \param config Table with keys: <output>, <recipe>, [time(2)]
-- \returns nil
industrialtest.api.registerMaceratorRecipe=function(config)
	local definition={
		output=config.output or "",
		recipe=config.recipe or "",
		time=config.time or 2
	}
	industrialtest.api.maceratorRecipes[definition.recipe]=definition
end
-- \brief Returns macerator recipe result
-- \param recipe String ID of resulting conten
-- \returns Table with following keys: output, recipe, time
industrialtest.api.getMaceratorRecipeResult=function(recipe)
	return industrialtest.api.maceratorRecipes[recipe]
end
-- \brief Registers compressor recipe
-- \param config Table with following keys: <output>, <recipe>, [time(2)], [count(1)]
-- \returns nil
industrialtest.api.registerCompressorRecipe=function(config)
	local definition={
		output=config.output or "",
		recipe=config.recipe or "",
		time=config.time or 2,
		count=config.count or 1
	}
	industrialtest.api.compressorRecipes[definition.recipe]=definition
end
-- \brief Returns macerator recipe result
-- \param recipe String ID of resulting conten
-- \returns Table with following keys: output, recipe, time
industrialtest.api.getCompressorRecipeResult=function(recipe)
	return industrialtest.api.compressorRecipes[recipe]
end
industrialtest.api.registerExtractorRecipe=function(config)
	local definition={
		output=config.output or "",
		recipe=config.recipe or "",
		time=config.time or 2
	}
	industrialtest.api.extractorRecipes[definition.recipe]=definition
end
industrialtest.api.getExtractorRecipeResult=function(recipe)
	return industrialtest.api.extractorRecipes[recipe]
end

industrialtest.api.registerCableFormerRecipe=function(config)
	local definition={
		output=config.output or "",
		recipe=config.recipe or "",
		time=config.time or 2
	}
	industrialtest.api.cableFormerRecipes[definition.recipe]=definition
end

industrialtest.api.getCableFormerRecipeResult=function(recipe)
	return industrialtest.api.cableFormerRecipes[recipe]
end

-- \brief Registers fuel that can be used in geothermal generator
-- \param fuel Table with following keys: <name>, <calorificValue>, <storageItems>
--        which is a table containing items which are tables with following keys: <name>, <leftover>
-- \returns nil
industrialtest.api.registerGeothermalGeneratorFuel=function(config)
	local definition={
		name=config.name or "",
		calorificValue=config.calorificValue or 0,
		texture=config.texture or "industrialtest_gui_fluid_bg.png",
		storageItems=config.storageItems or {}
	}
	industrialtest.api.geothermalGeneratorFuels[definition.name]=definition
end
-- \brief Returns generator fuel information
-- \param name Name of fuel
-- \returns Table with following keys: name, calorificValue, storageItems
industrialtest.api.getGeothermalGeneratorFuel=function(name)
	return industrialtest.api.geothermalGeneratorFuels[name]
end
-- \brief Returns generator fuel information by item name
-- \param name ID of item
-- \returns Table with following keys: name, calorificValue, storageItems or nil in case of failure
industrialtest.api.getGeothermalGeneratorFuelByItem=function(name)
	for _,value in pairs(industrialtest.api.geothermalGeneratorFuels) do
		for _,item in ipairs(value.storageItems) do
			if item.name==name then
				return value
			end
		end
	end
	return nil
end
-- \brief Registers fuel that can be used in water mill
-- \param fuel Table with following keys: <name>, <calorificValue>, <storageItems>
--        which is a table containing items which are tables with following keys: <name>, <leftover>
-- \returns nil
industrialtest.api.registerWaterMillFuel=function(config)
	local definition={
		name=config.name or "",
		calorificValue=config.calorificValue or 0,
		texture=config.texture or "industrialtest_gui_fluid_bg.png",
		storageItems=config.storageItems or {}
	}
	industrialtest.api.waterMillFuels[definition.name]=definition
end
-- \brief Returns water mill fuel information
-- \param name Name of fuel
-- \returns Table with following keys: name, calorificValue, storageItems
industrialtest.api.getWaterMillFuel=function(name)
	return industrialtest.api.waterMillFuels[name]
end
-- \brief Returns water mill fuel information by item name
-- \param name ID of item
-- \returns Table with following keys: name, calorificValue, storageItems or nil in case of failure
industrialtest.api.getWaterMillFuelByItem=function(name)
	for _,value in pairs(industrialtest.api.waterMillFuels) do
		for _,item in ipairs(value.storageItems) do
			if item.name==name then
				return value
			end
		end
	end
	return nil
end

-- \brief Registers Rotary Macerator recipe modifier
-- \param config table
-- \returns nil
industrialtest.api.registerRotaryMaceratorModifier=function(config)
	local definition={
		name=config.name or "",
		modifier=config.modifier or "",
		output=config.output or "",
		time=config.time or 2,
		uses=config.uses or 1,
		modifierLeftover=config.modifierLeftover
	}
	industrialtest.api.rotaryMaceratorModifiers[definition.name.." "..config.modifier]=definition
end

-- \brief Returns modified Rotary Macerator recipe by item and modifier
-- \param name string
-- \param modifier string
-- \returns table
industrialtest.api.getRotaryMaceratorModifier=function(name,modifier)
	return industrialtest.api.rotaryMaceratorModifiers[name.." "..modifier]
end

-- \brief Returns machine speed in items per operation
-- \param meta MetaDataRef
-- \returns number
industrialtest.api.getMachineSpeed=function(meta)
	return meta:contains("industrialtest.speed") and meta:get_int("industrialtest.speed") or 1
end
