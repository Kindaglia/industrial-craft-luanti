local S = minetest.get_translator("industrialtest")

local electricSilkExtractor = {}

local sound_handles = {}

electricSilkExtractor.afterUse = function(itemstack, config)
    local meta = itemstack:get_meta()
    industrialtest.api.addPowerToItem(itemstack, -20)
    if meta:get_int("industrialtest.powerAmount") < 20 then
        itemstack:set_name("industrialtest:" .. config.name)
    end
    return itemstack
end

local function registerSilkExtractor(config)
    local definition = {
        description = config.displayName,
        inventory_image = "industrialtest_" .. config.name .. ".png",
        after_use = function()
            -- Hack to make sure that drill won't be destroyed when has 0 EU
            return nil
        end,
        _industrialtest_powerStorage = true,
        _industrialtest_powerCapacity = 10000,
        _industrialtest_powerFlow = industrialtest.api.lvPowerFlow,
        _industrialtest_inactiveName = "industrialtest:" .. config.name,
        _mcl_silk_touch = true -- Aggiunta della proprietà Silk Touch
    }

    definition.on_place = function(itemstack, placer, pointed_thing)
        local rc = mcl_util.call_on_rightclick(itemstack, placer, pointed_thing)
        if rc then return rc end
        if not mcl_offhand.place(placer, pointed_thing) and old_hand_op then
            return old_hand_op(itemstack, placer, pointed_thing)
        end
    end

    if industrialtest.mtgAvailable then
        definition.tool_capabilities = {
            full_punch_interval = 0.5,
            max_drop_level = config.maxDropLevel,
            groupcaps = {
                cracky = {
                    times = config.inactiveTimes,
                    maxlevel = config.maxLevel
                },
                crumbly = {
                    times = config.inactiveTimes,
                    maxlevel = config.maxLevel
                }
            }
        }
        definition.groups = {
            pickaxe = 1,
            shovel = 1
        }
    elseif industrialtest.mclAvailable then
        definition.tool_capabilities = {
            full_punch_interval = 0.5,
            max_drop_level = config.maxDropLevel
        }
        definition.groups = {
            tool = 1,
            dig_speed_class = config.digSpeedClass
        }
        definition._mcl_diggroups = {
            pickaxey = {
                speed = config.inactiveDigSpeed,
                level = config.digLevel,
                uses = -1
            },
            shovely = {
                speed = config.inactiveDigSpeed,
                level = config.digLevel,
                uses = -1
            }
        }
        definition._mcl_toollike_wield = true
    end
    minetest.register_tool("industrialtest:" .. config.name, definition)
    definition = table.copy(definition)
    if industrialtest.mtgAvailable then
        definition.tool_capabilities.groupcaps.cracky.times = config.activeTimes
        definition.tool_capabilities.groupcaps.crumbly.times = config.activeTimes
    elseif industrialtest.mclAvailable then
        definition._mcl_diggroups.pickaxey.speed = config.activeDigSpeed
        definition._mcl_diggroups.shovely.speed = config.activeDigSpeed
    end
    definition.groups.not_in_creative_inventory = 1
    definition.after_use = function(itemstack)
        return electricSilkExtractor.afterUse(itemstack, config)
    end
    minetest.register_tool("industrialtest:" .. config.name .. "_active", definition)
    industrialtest.internal.registeredElectricDrills["industrialtest:" .. config.name] = true
    industrialtest.internal.registeredElectricDrills["industrialtest:" .. config.name .. "_active"] = true
end

-- Modifica di minetest.handle_node_drops per supportare Silk Touch
local old_handle_node_drops = minetest.handle_node_drops

minetest.handle_node_drops = function(pos, drops, digger)
    if digger and digger:is_player() then
        local tool = digger:get_wielded_item()
        local tooldef = minetest.registered_items[tool:get_name()]
        local nodedef = minetest.registered_nodes[minetest.get_node(pos).name]

        if tooldef and nodedef and tooldef._mcl_silk_touch and nodedef._mcl_silk_touch_drop then
            if nodedef._mcl_silk_touch_drop == true then
                drops = { minetest.get_node(pos).name }
            else
                drops = nodedef._mcl_silk_touch_drop
            end
        end
    end
    old_handle_node_drops(pos, drops, digger)
end

local definition = {
    name = "electric_silk_extractor",
    displayName = S("Silk Extractor")
}
if industrialtest.mtgAvailable then
    definition.maxDropLevel = 1
    definition.inactiveTimes = { [1] = 10, [2] = 5.6, [3] = 4 }
    definition.maxLevel = 2
    definition.activeTimes = { [1] = 2.0, [2] = 0.8, [3] = 0.4 }
elseif industrialtest.mclAvailable then
    definition.digSpeedClass = 4
    definition.maxDropLevel = 4
    definition.inactiveDigSpeed = 1
    definition.digLevel = 4
    definition.activeDigSpeed = 7
end
registerSilkExtractor(definition)

minetest.register_craft({
    type = "shaped",
    output = "industrialtest:electric_silk_extractor",
    recipe = {
        { "industrialtest:refined_iron_ingot", "industrialtest:refined_iron_ingot", "industrialtest:refined_iron_ingot" },
        { "industrialtest:refined_iron_ingot", "industrialtest:electronic_circuit", "industrialtest:refined_iron_ingot" },
        { "industrialtest:refined_iron_ingot", "industrialtest:re_battery",         "industrialtest:refined_iron_ingot" }
    }
})
