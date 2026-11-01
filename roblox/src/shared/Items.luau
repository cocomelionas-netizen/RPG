-- Item definitions (same ids and values as the web game's defItem calls)
local G = require(script.Parent.Gathering)

local Items = {}
local ORDER = 0

local function defItem(id: string, o)
	ORDER += 1
	o.id = id
	o.order = ORDER
	Items[id] = o
end

local LOG_N = { [0] = "Birch Logs", "Oak Logs", "Maple Logs", "Yew Logs", "Elder Logs" }
local COOKED_N = { [0] = "Cooked Roach", "Cooked Perch", "Cooked Pike", "Cooked Salmon", "Cooked Eel" }
local RAW_VALUE = { [0] = 2, 5, 10, 20, 40 }
local COOKED_VALUE = { [0] = 5, 12, 25, 50, 100 }
local HEAL = { [0] = 20, 45, 80, 120, 170 }
local WOOD_COLOR = { [0] = "#e8d9b0", "#b08850", "#c0703a", "#7a5a30", "#8a5ab0" }
local FISH_COLOR = { [0] = "#a8b8c0", "#c0a050", "#6a8a5a", "#e08070", "#5a5a7a" }

for t = 0, 4 do
	defItem("log" .. t, { name = LOG_N[t], icon = "🌲", tier = t, value = RAW_VALUE[t], type = "Resources", color = WOOD_COLOR[t] })
end
for t = 0, 4 do
	defItem("fish" .. t, { name = "Raw " .. G.FISH_N[t], icon = "🐟", tier = t, value = RAW_VALUE[t], type = "Resources", color = FISH_COLOR[t] })
end
for t = 0, 6 do
	local o = G.ORES[t]
	defItem("ore_" .. o.id, { name = o.name, icon = o.id == "coal" and "⚫" or "🔶", tier = t, value = o.value, type = "Ores", color = o.color })
end
-- construction materials, made at the workbench
local PLANK_N = { [0] = "Birch Planks", "Oak Planks", "Maple Planks", "Yew Planks", "Elder Planks" }
local PLANK_VALUE = { [0] = 4, 9, 18, 34, 65 }
for t = 0, 4 do
	defItem("plank" .. t, { name = PLANK_N[t], icon = "🟫", tier = t, value = PLANK_VALUE[t], type = "Materials", color = WOOD_COLOR[t] })
end
defItem("nails", { name = "Nails", icon = "📌", tier = 0, value = 1, type = "Materials", color = "#9aa0a8" })
-- cooking arrives in part 3; defined now so saves stay compatible
for t = 0, 4 do
	defItem("cooked" .. t, { name = COOKED_N[t], icon = "🍽️", tier = t, value = COOKED_VALUE[t], heal = HEAL[t], type = "Food" })
end

return Items
