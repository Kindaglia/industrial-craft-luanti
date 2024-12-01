-- industrial-craft-luanti/nodes.lua

local S = minetest.get_translator("industrial-craft-luanti")

minetest.register_node("industrialtest:drying_rack", {
    description = S("Drying Rack"),
    tiles = {"drying_rack_top.png", "drying_rack_bottom.png", "drying_rack_side.png"},
    paramtype2 = "facedir",
    groups = {choppy = 2, oddly_breakable_by_hand = 2},
    sounds = mcl_sounds.node_sound_wood_defaults(),
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        local player_name = clicker:get_player_name()
        local meta = minetest.get_meta(pos)
        local current_item = meta:get_string("current_item")
        local dried_item = meta:get_string("dried_item")

        if current_item and current_item ~= "" then
            minetest.chat_send_player(player_name, S("The drying rack is already in use."))
            return itemstack
        end

        local item_name = itemstack:get_name()
        if item_name == "mcl_mobitems:rotten_flesh" then
            meta:set_string("current_item", "mcl_mobitems:rotten_flesh")
            meta:set_float("start_time", minetest.get_gametime())
            meta:set_string("dried_item", "")
            minetest.chat_send_player(player_name, S("Rotten flesh placed on the drying rack. It will dry in 1 minute."))
            itemstack:take_item(1)
            node.name = "industrialtest:drying_rack_drying"
            minetest.swap_node(pos, node)
            return itemstack
        else
            minetest.chat_send_player(player_name, S("You can only place rotten flesh on the drying rack."))
            return itemstack
        end
    end,
    on_punch = function(pos, node, puncher, pointed_thing)
        local meta = minetest.get_meta(pos)
        local dried_item = meta:get_string("dried_item")
        if dried_item and dried_item ~= "" then
            local itemstack = ItemStack(dried_item)
            local player_inv = puncher:get_inventory()
            if player_inv:room_for_item("main", itemstack) then
                player_inv:add_item("main", itemstack)
                meta:set_string("dried_item", "")
                meta:set_string("current_item", "")
                node.name = "industrialtest:drying_rack"
                minetest.swap_node(pos, node)
                minetest.chat_send_player(puncher:get_player_name(), S("Leather taken from the drying rack."))
            else
                minetest.chat_send_player(puncher:get_player_name(), S("Your inventory is full."))
            end
        else
            minetest.chat_send_player(puncher:get_player_name(), S("There is no dried item on the drying rack."))
        end
    end,
})

minetest.register_node("industrialtest:drying_rack_drying", {
    description = S("Drying Rack (Drying)"),
    tiles = {"drying_rack_top_drying.png", "drying_rack_bottom.png", "drying_rack_side.png"},
    paramtype2 = "facedir",
    groups = {choppy = 2, oddly_breakable_by_hand = 2, not_in_creative_inventory = 1},
    drop = "industrialtest:drying_rack",
    sounds = mcl_sounds.node_sound_wood_defaults(),
    on_punch = function(pos, node, puncher, pointed_thing)
        local meta = minetest.get_meta(pos)
        local dried_item = meta:get_string("dried_item")
        if dried_item and dried_item ~= "" then
            local itemstack = ItemStack(dried_item)
            local player_inv = puncher:get_inventory()
            if player_inv:room_for_item("main", itemstack) then
                player_inv:add_item("main", itemstack)
                meta:set_string("dried_item", "")
                meta:set_string("current_item", "")
                node.name = "industrialtest:drying_rack"
                minetest.swap_node(pos, node)
                minetest.chat_send_player(puncher:get_player_name(), S("Leather taken from the drying rack."))
            else
                minetest.chat_send_player(puncher:get_player_name(), S("Your inventory is full."))
            end
        else
            minetest.chat_send_player(puncher:get_player_name(), S("The flesh is still drying."))
        end
    end,
})

minetest.register_node("industrialtest:drying_rack_dried", {
    description = S("Drying Rack (Dried)"),
    tiles = {"drying_rack_top_dried.png", "drying_rack_bottom.png", "drying_rack_side.png"},
    paramtype2 = "facedir",
    groups = {choppy = 2, oddly_breakable_by_hand = 2, not_in_creative_inventory = 1},
    drop = "industrialtest:drying_rack",
    sounds = mcl_sounds.node_sound_wood_defaults(),
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        local meta = minetest.get_meta(pos)
        local dried_item = meta:get_string("dried_item")
        if dried_item and dried_item ~= "" then
            local itemstack = ItemStack(dried_item)
            local player_inv = clicker:get_inventory()
            if player_inv:room_for_item("main", itemstack) then
                player_inv:add_item("main", itemstack)
                meta:set_string("dried_item", "")
                meta:set_string("current_item", "")
                node.name = "industrialtest:drying_rack"
                minetest.swap_node(pos, node)
                minetest.chat_send_player(clicker:get_player_name(), S("Leather taken from the drying rack."))
            else
                minetest.chat_send_player(clicker:get_player_name(), S("Your inventory is full."))
            end
        else
            minetest.chat_send_player(clicker:get_player_name(), S("There is no dried item on the drying rack."))
        end
    end,
})

minetest.register_abm({
    nodenames = {"industrialtest:drying_rack_drying"},
    interval = 1,
    chance = 1,
    action = function(pos, node, active_object_count, active_object_count_wider)
        local meta = minetest.get_meta(pos)
        local start_time = meta:get_float("start_time")
        local current_time = minetest.get_gametime()
        local elapsed_time = current_time - start_time

        if elapsed_time >= 60 then  -- 60 seconds = 1 minute
            meta:set_string("dried_item", "mcl_mobitems:leather")
            minetest.chat_send_all(S("Rotten flesh has dried into leather on the drying rack."))
            node.name = "industrialtest:drying_rack_dried"
            minetest.swap_node(pos, node)
        else
            minetest.log("action", "Time elapsed on drying rack at " .. minetest.pos_to_string(pos) .. ": " .. elapsed_time .. " seconds")
        end
    end,
})