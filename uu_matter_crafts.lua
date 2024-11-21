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

minetest.register_craft({
	type="shapeless",
	output=industrialtest.elementKeys.stone.." 16",
	recipe={"industrialtest:uu_matter"}
})

minetest.register_craft({
	type="shaped",
	output=industrialtest.elementKeys.grassBlock.." 16",
	recipe={
		{"industrialtest:uu_matter"},
		{"industrialtest:uu_matter"}
	}
})

minetest.register_craft({
	type="shaped",
	output=industrialtest.elementKeys.wood.." 16",
	recipe={
		{"","industrialtest:uu_matter",""},
		{"","",""},
		{"industrialtest:uu_matter","",""}
	}
})

minetest.register_craft({
	type="shaped",
	output=industrialtest.elementKeys.glass.." 32",
	recipe={
		{"","industrialtest:uu_matter",""},
		{"industrialtest:uu_matter","","industrialtest:uu_matter"},
		{"","industrialtest:uu_matter",""}
	}
})

minetest.register_craft({
	type="shaped",
	output=industrialtest.elementKeys.mossCobble.." 16",
	recipe={
		{"","industrialtest:uu_matter",""},
		{"industrialtest:uu_matter","","industrialtest:uu_matter"}
	}
})

if industrialtest.mclAvailable then
	minetest.register_craft({
		type="shaped",
		output="mcl_core:stonebrickcarved 48",
		recipe={
			{"industrialtest:uu_matter","industrialtest:uu_matter"},
			{"industrialtest:uu_matter","industrialtest:uu_matter"},
			{"industrialtest:uu_matter",""}
		}
	})
end
