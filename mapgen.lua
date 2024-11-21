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

minetest.register_on_generated(function(minp,maxp,seed)
	if industrialtest.mods.mclRubber or industrialtest.random:next(1,100)>40 then
		return
	end
	local center=vector.new((maxp.x-minp.x)/2+ minp.x,(maxp.y-minp.y)/2+minp.y,(maxp.z-minp.z)/2+minp.z)
	local pos=minetest.find_node_near(center,maxp.x-minp.x,{industrialtest.elementKeys.grassBlock})
	if pos then
		industrialtest.internal.makeRubberTree(pos)
	end
end)
