# Endless Road – Roblox versija

Naujas Roblox žaidimas pagal web „Endless Road“ idėją ir skaičius (Luau, Rojo projektas).
Web žaidimas (`index.html` šakoje `main`) lieka atskiras.

## Struktūra

```
roblox/
  default.project.json   Rojo: kas kur atsiduria Studio
  aftman.toml / rokit.toml  Rojo versija (7.4.4)
  src/shared/   -> ReplicatedStorage.Shared   (duomenys: Skills, XP, Items, Gathering, Zones, Remotes)
  src/server/   -> ServerScriptService.Server (Main, DataService, WorldBuilder, GatherService, ShopService, ToolFactory)
  src/client/   -> StarterPlayerScripts.Client (Main, UI)
```

Pasaulis (kelias, 5 zonos, medžiai, uolos, tvenkiniai) sukuriamas kodu paleidus žaidimą – Studio lange prieš Play jo nematysi.

## 1 dalis: kas jau yra

- Kelias per 5 zonas: Green Meadow → Dark Forest → Shadow Caves → Ice Mountains → Dragon's Lair (kiekviena su savo dangumi/apšvietimu).
- Woodcutting, Mining, Fishing: priėjus prie medžio/uolos/žvejybos vietos spausk **E** (telefone – paliesk). Herojus dirba pats, kol nueini.
- Inventorius (🎒 Bag), pardavimas už auksą, įrankių patobulinimai (🛠️ Tools, kiekvienas +12 % greičio).
- 22 įgūdžiai, XP kreivė kaip web žaidime (dabar treniruojami 3).
- Išsaugojimas: DataStore + session lock (UpdateAsync), autosave kas 60 s, BindToClose.
- Offline progresas: išeik **kol renki** – grįžus gausi tai, ką herojus būtų surinkęs (iki 12 val.).

## 2 dalis: namas (pradžia)

- **Hometown** už starto (X < 0): 12 sklypų, įėjus gauni savo (lentelė su tavo vardu). Mygtukas 🏡 Go home / 🛣️ To road.
- **Workbench** sklype: lentos iš rąstų, vinys iš rūdos. Herojus dirba pats, veikia ir offline, kol užtenka žaliavų.
- **Construction** įgūdis ir 6 kambariai po 5 lygius (🏠 House langas): greitesnis renkimas, ilgesnis offline, daugiau aukso pardavus.
- Visas planas (kova, Wraith Caves PvP, Robux) – `DESIGN.md`.
- Emoji: naudok tik senesnius (iki Unicode 12). 🪙 🪵 🪨 ✕ Roblox šriftuose rodomi kaip kvadratėliai.

## Modeliai iš Creator Store

- `ServerStorage.AssetPacks.SyntyNature` – oficialus Roblox „Synty Nature Pack“ (asset 6933438443, nemokamas, licencijuotas
  visiems Roblox žaidimams). Jis yra **place faile, ne git'e** (Rojo jo neliečia). Įkeltas per Studio MCP `insert_asset`.
- `WorldBuilder.prop()` klonuoja modelius, **ištrina visus skriptus** ir pastato; jei paketo nėra, lieka paprastos detalės.
- `ServerStorage.AssetPacks.Monsters` – monstrų modeliai (taip pat place faile): vilkas iš Roblox (asset 1989724206),
  kiti sugeneruoti Roblox mesh generatoriumi. `CombatService.monsterModel()` juos klonuoja, ištrina skriptus ir Humanoid,
  pritaiko dydį; Wraith Caves monstrai – tie patys modeliai, permatomi. Jei modelio nėra (pvz. Will-o'-Wisp), lieka detalės.
- UI ikonos – Google „Noto Emoji“ 3D paveikslėliai (Apache License 2.0), įkelti į Roblox; ID sąrašas `src/shared/Icons.luau`.
  `UI.luau` `iconize()` pakeičia etiketę su vienu emoji tokiu paveikslėliu.
- `ServerStorage.AssetPacks.Tools` – įrankiai iš Creator Store (place faile), kiekvienas jau įdėtas į atpalaiduotą ranką:
  Sword – „Untextured Basic Sword“ (FroggyDevss, 88096120558971), Axe – „Axe Tool Woodcutting“ (ChloeVenom359728,
  102359949817086), Pick – „Low Poly Pickaxe“ (ChloeVenom359728, 114009203693489), Rod – „Fishing Rod Tool“
  (94950231294184), Saw – iš detalių. Skriptai ištrinti. Kiekvienas turi du laikymus: `Tool.Grip` (ranka nuleista) ir
  atributą `ActGrip` (įrankis tiesiai iš dilbio – smūgio animacijoms). Detalės su atributu `Metal` (atspalvis 0–1)
  nusidažo pagal metalą. Laikymai apskaičiuoti Studio pagal R15 idle rankos padėtį.
- Roblox'o „toolnone“ poza (ranka ištiesta į priekį) pakeista tuščia animacija `Anims.TOOL_NONE` (HeroMotion), todėl
  ranka su įrankiu kabo ir mojuoja kaip be jo.
- `ServerStorage.Animations` – mūsų animacijų šaltiniai (KeyframeSequence), kuriuos sukuria `src/server/AnimBuilder.luau`
  (Studio komandų juostoje: `require(game.ServerScriptService.Server.AnimBuilder)()`). Pakeitus pozą: perstatyti,
  dešiniu klavišu > Save / Export > Save to Roblox, naują ID įrašyti į `src/shared/Anims.luau`. Animacijas groti gali tik
  jų savininkas, todėl jos įkeltos žaidimo savininko vardu.
- Naujus modelius imti tik iš patvirtintų kūrėjų (geriausia „Roblox“), botų keliamuose dažnai būna kenkėjiškų skriptų.
