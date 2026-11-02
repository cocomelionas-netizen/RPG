-- Icons: Google's Noto Emoji 3D set (Apache License 2.0) uploaded to Roblox as images.
-- The UI shows these pictures wherever a label holds just one of these emoji (see UI.luau iconize).
local Icons = {}

local IDS = {
	["🌱"] = 126305692812534, -- emoji_u1f331
	["🌲"] = 136704310787855, -- emoji_u1f332
	["🌽"] = 113539201145039, -- emoji_u1f33d
	["🌾"] = 85088395666895, -- emoji_u1f33e
	["🌿"] = 120556383977657, -- emoji_u1f33f
	["🍅"] = 77495516300811, -- emoji_u1f345
	["🍉"] = 75304714140220, -- emoji_u1f349
	["🍓"] = 79345305908172, -- emoji_u1f353
	["🍳"] = 139832253944778, -- emoji_u1f373
	["🍽"] = 88869186551456, -- emoji_u1f37d
	["🎒"] = 91580889701763, -- emoji_u1f392
	["🎣"] = 130518948008087, -- emoji_u1f3a3
	["🎯"] = 95780318353179, -- emoji_u1f3af
	["🏃"] = 93886616604228, -- emoji_u1f3c3
	["🏗"] = 119253419096897, -- emoji_u1f3d7
	["🏠"] = 76006356823846, -- emoji_u1f3e0
	["🏡"] = 119741041572636, -- emoji_u1f3e1
	["🏦"] = 115697995083628, -- emoji_u1f3e6
	["🏹"] = 84844345658714, -- emoji_u1f3f9
	["🐟"] = 114993880340979, -- emoji_u1f41f
	["🐺"] = 120793763458105, -- emoji_u1f43a
	["👻"] = 78599011442172, -- emoji_u1f47b
	["💀"] = 91981127840462, -- emoji_u1f480
	["💤"] = 110078869878382, -- emoji_u1f4a4
	["💪"] = 116676335844868, -- emoji_u1f4aa
	["💰"] = 135245628883154, -- emoji_u1f4b0
	["📊"] = 111565404031310, -- emoji_u1f4ca
	["📌"] = 114838162278112, -- emoji_u1f4cc
	["🔒"] = 135118836823424, -- emoji_u1f512
	["🔥"] = 90682483607925, -- emoji_u1f525
	["🔨"] = 126323178214794, -- emoji_u1f528
	["🔮"] = 78279793247558, -- emoji_u1f52e
	["🔶"] = 76008828693542, -- emoji_u1f536
	["🗡"] = 99383454094555, -- emoji_u1f5e1
	["🙏"] = 71511183847595, -- emoji_u1f64f
	["🛏"] = 127314314666363, -- emoji_u1f6cf
	["🛠"] = 106906791960657, -- emoji_u1f6e0
	["🛡"] = 80489685329072, -- emoji_u1f6e1
	["🟫"] = 133610689050167, -- emoji_u1f7eb
	["🥔"] = 118747664869434, -- emoji_u1f954
	["🥬"] = 87179270332214, -- emoji_u1f96c
	["🥷"] = 133339780256506, -- emoji_u1f977
	["🧅"] = 76209931166799, -- emoji_u1f9c5
	["🧪"] = 78118401873946, -- emoji_u1f9ea
	["🪓"] = 133428750145061, -- emoji_u1fa93
	["🪶"] = 111097324246190, -- emoji_u1fab6
	["☠"] = 125083431080517, -- emoji_u2620
	["⚔"] = 73443974659374, -- emoji_u2694
	["⚖"] = 91201351443060, -- emoji_u2696
	["⚫"] = 80498268178608, -- emoji_u26ab
	["⛏"] = 73300789204933, -- emoji_u26cf
	["⛲"] = 82042158204569, -- emoji_u26f2
	["✔"] = 104060085615628, -- emoji_u2714
	["✨"] = 81172178711601, -- emoji_u2728
	["❤"] = 133685012037866, -- emoji_u2764
	["➕"] = 118169300523170, -- emoji_u2795
	["➡"] = 104482346439452, -- emoji_u27a1
	["⬅"] = 75484125919313, -- emoji_u2b05
	["⬆"] = 115256740723282, -- emoji_u2b06
	["⬇"] = 77096378676869, -- emoji_u2b07
	["⭐"] = 129898766787214, -- emoji_u2b50
}

-- the rbxassetid for a label text that is a single emoji (the variation selector U+FE0F is ignored), or nil
function Icons.get(text: string): string?
	local id = IDS[(text:gsub("\u{FE0F}", ""))]
	return id and ("rbxassetid://" .. id) or nil
end

return Icons
