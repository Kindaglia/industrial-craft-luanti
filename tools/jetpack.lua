local S = minetest.get_translator("industrialtest")

local jetpack = {}
local electricJetpack = {}

local sound_handles = {}

local function vectorToString(v)
    return "(" .. v.x .. ", " .. v.y .. ", " .. v.z .. ")"
end

local function registerJetpack(config)
    minetest.debug("[IndustrialTest] Registering jetpack: " .. config.name)
    if industrialtest.mclAvailable then
        local groups = {
            armor = 1,
            non_combat_armor = 1,
            armor_torso = 1,
            non_combat_torso = 1,
            _industrialtest_jetpack = 1
        }
        if config.groups then
            for key, value in pairs(config.groups) do
                groups[key] = value
            end
        end
        local definition = {
            description = config.displayName,
            inventory_image = "industrialtest_" .. config.name .. "_inv.png",
            groups = groups,
            sounds = {
                _mcl_armor_equip = "mcl_armor_equip_iron",
                _mcl_armor_unequip = "mcl_armor_unequip_iron"
            },
            on_place = mcl_armor.equip_on_use,
            on_secondary_use = mcl_armor.equip_on_use,
            _mcl_armor_element = "torso",
            _mcl_armor_texture = "industrialtest_" .. config.name .. ".png",
            _industrialtest_tryFly = config.tryFly
        }
        if config.customKeys then
            for key, value in pairs(config.customKeys) do
                definition[key] = value
            end
        end
        minetest.register_tool("industrialtest:" .. config.name, definition)
    elseif industrialtest.mtgAvailable then
        local groups = {
            armor_torso = 1,
            armor_heal = 0,
            _industrialtest_jetpack = 1
        }
        if config.groups then
            for key, value in pairs(config.groups) do
                groups[key] = value
            end
        end
        local definition = {
            description = config.displayName,
            inventory_image = "industrialtest_" .. config.name .. "_inv.png",
            groups = groups,
            _industrialtest_tryFly = config.tryFly
        }
        if config.customKeys then
            for key, value in pairs(config.customKeys) do
                definition[key] = value
            end
        end
        armor:register_armor("industrialtest:" .. config.name, definition)
    end
end

local function addYVelocityClamped(player, vel, max)
    local player_name = player:get_player_name()
    local playerVel = player:get_velocity()
    
    minetest.debug("[IndustrialTest] addYVelocityClamped called for player: " .. player_name)
    minetest.debug("[IndustrialTest] Player: " .. tostring(player))
    minetest.debug("[IndustrialTest] Velocity to add (vel): " .. tostring(vel))
    minetest.debug("[IndustrialTest] Maximum velocity (max): " .. tostring(max))
    minetest.debug("[IndustrialTest] Current player velocity (playerVel): " .. vectorToString(playerVel))
    
    if playerVel.y + vel > max then
        local new_y_vel = math.max(max - playerVel.y, 0)
        player:add_velocity(vector.new(0, new_y_vel, 0))
        minetest.debug("[IndustrialTest] New Y velocity added: " .. tostring(new_y_vel))
    else
        player:add_velocity(vector.new(0, vel, 0))
        minetest.debug("[IndustrialTest] Full Y velocity added: " .. tostring(vel))
    end
end

local function onGlobalStep(player, inv, itemstack, index, def)
    local player_name = player:get_player_name()
    minetest.debug("[IndustrialTest] Checking global step for player: " .. player_name)
    if def.groups and def.groups._industrialtest_jetpack then
        minetest.debug("[IndustrialTest] Player has jetpack equipped.")
        if def._industrialtest_tryFly(itemstack) then
            minetest.debug("[IndustrialTest] Jetpack is active.")
            addYVelocityClamped(player, 1, 10)
            inv:set_stack("armor", index, itemstack)
            
            -- Riproduci il suono del jetpack se non è già in esecuzione
            if not sound_handles[player_name] then
                local pos = player:get_pos()
                local handle = minetest.sound_play("JetpackLoop", {
                    pos = pos,
                    gain = 1.0,  -- Volume adjustment
                    max_hear_distance = 16,  -- Maximum distance the sound can be heard
                    object = player,
                    loop = true,
                })
                sound_handles[player_name] = handle
                minetest.debug("[IndustrialTest] Jetpack sound started for player: " .. player_name)
            end
            
            return true
        else
            -- Ferma il suono del jetpack se non sta volando
            if sound_handles[player_name] then
                minetest.sound_stop(sound_handles[player_name])
                sound_handles[player_name] = nil
                minetest.debug("[IndustrialTest] Jetpack sound stopped for player: " .. player_name)
            end
        end
    end
    return false
end

jetpack.tryFly = function(itemstack)
    local meta = itemstack:get_meta()
    local fluidAmount = meta:get_int("industrialtest.fluidAmount")
    minetest.debug("[IndustrialTest] Jetpack fluid amount: " .. fluidAmount)
    if fluidAmount == 0 then
        minetest.debug("[IndustrialTest] Jetpack out of fuel.")
        return false
    end
    industrialtest.api.addFluidToItem(itemstack, -1)
    minetest.debug("[IndustrialTest] Jetpack consumed 1 unit of fuel.")
    return true
end

-- _v is hack to suppress "Registered armor doesn't have material at the end of registration name" warning from 3D Armor.
registerJetpack({
    name = "jetpack_v",
    displayName = S("Jetpack"),
    groups = {
        _industrialtest_fueled = 1,
        _industrialtest_fluidStorage = 1
    },
    tryFly = jetpack.tryFly,
    customKeys = {
        _industrialtest_fluidCapacity = 5000
    }
})
minetest.register_craft({
    type = "shaped",
    output = "industrialtest:jetpack_v",
    recipe = {
        {"industrialtest:refined_iron_ingot", "industrialtest:electronic_circuit", "industrialtest:refined_iron_ingot"},
        {"industrialtest:refined_iron_ingot", "industrialtest:fuel_can", "industrialtest:refined_iron_ingot"},
        {industrialtest.elementKeys.powerCarrier, "", industrialtest.elementKeys.powerCarrier}
    }
})

electricJetpack.tryFly = function(itemstack)
    local meta = itemstack:get_meta()
    local powerAmount = meta:get_int("industrialtest.powerAmount")
    minetest.debug("[IndustrialTest] Electric Jetpack power amount: " .. powerAmount)
    if powerAmount < 10 then
        minetest.debug("[IndustrialTest] Electric Jetpack out of power.")
        return false
    end
    industrialtest.api.addPowerToItem(itemstack, -10)
    minetest.debug("[IndustrialTest] Electric Jetpack consumed 10 units of power.")
    return true
end

registerJetpack({
    name = "electric_jetpack",
    displayName = S("Electric Jetpack"),
    tryFly = electricJetpack.tryFly,
    customKeys = {
        _industrialtest_powerStorage = true,
        _industrialtest_powerCapacity = 30000,
        _industrialtest_powerFlow = industrialtest.api.lvPowerFlow
    }
})
minetest.register_craft({
    type = "shaped",
    output = "industrialtest:electric_jetpack",
    recipe = {
        {"industrialtest:refined_iron_ingot", "industrialtest:advanced_electronic_circuit", "industrialtest:refined_iron_ingot"},
        {"industrialtest:refined_iron_ingot", "industrialtest:batbox", "industrialtest:refined_iron_ingot"},
        {industrialtest.elementKeys.yellowDust, "", industrialtest.elementKeys.yellowDust}
    }
})

minetest.register_globalstep(function(dtime)
    -- FIXME: Maybe this can be optimized?
    local players = minetest.get_connected_players()
    for _, player in ipairs(players) do
        local control = player:get_player_control()
        local player_name = player:get_player_name()
        
        if control.jump then
            minetest.debug("[IndustrialTest] Player is jumping.")
            if industrialtest.mclAvailable then
                local inv = player:get_inventory()
                local stack = inv:get_stack("armor", 3)
                local def = stack:get_definition()
                onGlobalStep(player, inv, stack, 3, def)
            elseif industrialtest.mtgAvailable then
                local _, inv = armor:get_valid_player(player, "")
                if inv then
                    local armorList = inv:get_list("armor")
                    assert(armorList)
                    for i = 1, #armorList do
                        local stack = armorList[i]
                        local def = stack:get_definition()
                        if onGlobalStep(player, inv, stack, i, def) then
                            break
                        end
                    end
                end
            end
        else
            -- Ferma il suono del jetpack se il giocatore non sta saltando
            if sound_handles[player_name] then
                minetest.sound_stop(sound_handles[player_name])
                sound_handles[player_name] = nil
                minetest.debug("[IndustrialTest] Jetpack sound stopped for player: " .. player_name .. " because they are not jumping.")
            end
        end
    end
end)