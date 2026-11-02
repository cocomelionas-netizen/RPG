-- The house grid: each plot holds an 8x8 grid of room cells.
-- The player picks where the house starts (the Entrance Hall goes on any cell); after that every room must touch
-- the house side by side, through a doorway, so the house always stays in one piece.
-- Shared so the client can show green/red while placing and the server checks the same rules.
local HouseGrid = {}

HouseGrid.SIZE = 8 -- cells per side
HouseGrid.CELL = 16 -- studs per cell
HouseGrid.PLOT = 160 -- studs per plot side (grid plus a garden margin)
HouseGrid.START = "entrance" -- the first room, free, placed anywhere

local function key(x, z)
	return x .. "," .. z
end

-- occupied cells of a layout ({ [roomId] = { x, z } }), optionally leaving one room out
function HouseGrid.occupied(layout, except: string?)
	local cells = {}
	for id, c in layout or {} do
		if id ~= except then
			cells[key(c.x, c.z)] = id
		end
	end
	return cells
end

function HouseGrid.inside(x: number, z: number): boolean
	return x >= 0 and z >= 0 and x < HouseGrid.SIZE and z < HouseGrid.SIZE and x == math.floor(x) and z == math.floor(z)
end

-- every room reachable from the Entrance Hall through side-by-side neighbours?
local function connected(cells, start): boolean
	local startKey = key(start.x, start.z)
	local seen, queue, total, reached = { [startKey] = true }, { start }, 0, 0
	for _ in cells do
		total += 1
	end
	while #queue > 0 do
		local c = table.remove(queue)
		reached += 1
		for _, d in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
			local nx, nz = c.x + d[1], c.z + d[2]
			local k = key(nx, nz)
			if cells[k] and not seen[k] then
				seen[k] = true
				table.insert(queue, { x = nx, z = nz })
			end
		end
	end
	return reached == total
end

function HouseGrid.started(layout): boolean
	return layout ~= nil and layout[HouseGrid.START] ~= nil
end

-- can roomId go to cell (x, z)? returns ok, reason
function HouseGrid.canPlace(layout, roomId: string, x: number, z: number): (boolean, string?)
	if not HouseGrid.inside(x, z) then
		return false, "That's outside your plot."
	end
	if roomId ~= HouseGrid.START and not HouseGrid.started(layout) then
		return false, "Choose where your house starts first (Entrance Hall)."
	end
	local cells = HouseGrid.occupied(layout, roomId)
	if cells[key(x, z)] then
		return false, "Another room is already there."
	end
	cells[key(x, z)] = roomId
	local start = roomId == HouseGrid.START and { x = x, z = z } or layout[HouseGrid.START]
	if not connected(cells, start) then
		return false, "Rooms must join the house side by side, door to door."
	end
	return true
end

-- local offset (studs, from the plot centre) of a cell's centre
function HouseGrid.cellOffset(x: number, z: number): Vector3
	local half = HouseGrid.SIZE * HouseGrid.CELL / 2
	return Vector3.new(-half + (x + 0.5) * HouseGrid.CELL, 0, -half + (z + 0.5) * HouseGrid.CELL)
end

-- the cell under a local offset from the plot centre (may be outside the grid)
function HouseGrid.cellAt(offset: Vector3): (number, number)
	local half = HouseGrid.SIZE * HouseGrid.CELL / 2
	return math.floor((offset.X + half) / HouseGrid.CELL), math.floor((offset.Z + half) / HouseGrid.CELL)
end

-- house level: every room level counts; each one gives +1% XP to every skill
function HouseGrid.houseLevel(rooms): number
	local n = 0
	for _, t in rooms or {} do
		n += t
	end
	return n
end

function HouseGrid.xpMultiplier(rooms): number
	return 1 + HouseGrid.houseLevel(rooms) / 100
end

return HouseGrid
