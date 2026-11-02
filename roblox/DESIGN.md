# Endless Road (Roblox) – dizainas

Dvi pagrindinės žaidimo esmės: **savas namas** (statai, gyveni, tobulini) ir **PvP Wraith Caves**.
Visa kita (renkimas, amatai, kova) maitina šias dvi.

## Kryptis

- Žanras kaip OSRS: įgūdžiai 1–99, ta pati XP kreivė, resursų lygiai, idle renkimas, Wilderness tipo PvP.
  Bet **savas žaidimas**: savi pavadinimai (Cobalt, Verdite, Skyrite, Wraith Caves...), sava grafika ir taisyklės.
  OSRS pavadinimų, grafikos ir turinio nekopijuojam (Jagex autorių teisės, ir Roblox tokius žaidimus šalina).
- Roblox stilius kaip didžiųjų žaidimų (Pet Simulator, Bee Swarm, Fisch, Grow a Garden): ryškios spalvos,
  dideli aiškūs užrašai, viena retumo spalvų skalė visur, „juice“ (iššokimai, blizgučiai), telefonas pirmiausia.

## Vizualinės taisyklės

- **Retumo skalė** (`Tiers.luau`): pilka → žalia → mėlyna → violetinė → oranžinė → raudona → žydra.
  Ta pati spalva: žiedas ant žemės, lentelės rėmelis, daikto rėmelis krepšyje.
- **Niekada tik spalva:** kiekvienas lygis skiriasi forma (beržas su dryžiais, platus ąžuolas, oranžinis klevas su
  krentančiais lapais, kūgio formos kukmedis, švytintis Elder; rūda: gumulai → kubeliai → anglis → švytintys kristalai).
- **Lentelė virš kiekvieno taško:** ikona + pavadinimas + „Lv 15“ (žalia – gali, raudona su 🔒 – dar negali).
- Emoji tik iki Unicode 12 (naujesni Roblox šriftuose rodomi kaip kvadratėliai).

## Statymo tvarka

1. ✅ Kelias, renkimas, krepšys, išsaugojimas, offline progresas.
2. **Namas** – Construction įgūdis, Hometown su sklypais, kambariai su bonusais.
3. **Kova + Wraith Caves PvP** – ginklai, šarvai, priešai, PvP urvai (combat 40+).
4. **Robux parduotuvė** – gamepass'ai, boost'ai, kosmetika, augintiniai, enchantai.
5. Vėliau: questai, agility, klanai, kiti amatai.

## 2 dalis: namas

**Ciklas:** rąstai → lentos, rūda → vinys (prie Workbench, laikui bėgant, veikia ir offline)
→ statai kambarius → kambariai pagreitina renkimą → greičiau renki → statai toliau.

- **Hometown** – miestelis už starto (X < 0) su 12 sklypų. Įėjus žaidėjui duodamas laisvas sklypas su jo vardu.
  Kiti žaidėjai gali užeiti pasižiūrėti (lankymas be jokios papildomos sistemos).
- **Workbench** kiekviename sklype: pasirenki receptą, herojus dirba pats.
  - Lentos: Birch/Oak/Maple/Yew/Elder Planks iš atitinkamų rąstų (Construction 1/10/25/40/60).
  - Vinys: Copper Ore + Tin Ore → 10 Nails (Lv 1), Iron Ore → 15 Nails (Lv 15).
- **Kambariai** (po 5 lygius, kaina pagal web žaidimo formulę: lentos + vinys + auksas):
  | Kambarys | Bonusas | Construction |
  | --- | --- | --- |
  | 🪓 Woodshed | Woodcutting +5/10/15/20/25 % greičio | 1/20/40/60/80 |
  | 🔨 Workshop | Workbench +5/10/15/20/25 % greičio | 2/22/42/62/82 |
  | ⛏️ Ore Cellar | Mining +5…25 % | 4/24/44/64/84 |
  | 🎣 Fish Pond | Fishing +5…25 % | 7/27/47/67/87 |
  | 🛏️ Bedroom | Offline limitas +2/4/6/9/12 h | 10/30/50/70/90 |
  | 🏦 Treasury | Pardavimas +3/6/10/13/16 % aukso | 15/35/55/75/95 |
- **Žemėlapis kaip OSRS:** miestas Riverbend centre (fontanas, rodyklių stulpas), keliai į 4 puses su arkomis:
  pietūs – Green Meadow (startas), vakarai – Dark Forest, šiaurė – Ice Mountains ir Wraith Caves vartai,
  šiaurės vakarai – Shadow Caves, šiaurės rytai – Dragon's Lair, rytai – Hometown.
- **Sklypas 120×120** su 5×5 kambarių tinkleliu (20 studų langelis), 9 sklypai Hometown. Žaidėjas pats pasirenka, kur pradeda namą
  (Entrance Hall bet kur), o kiekvienas kitas kambarys turi liestis su namu šonu („durys į duris“) – `HouseGrid.luau`.
  Statoma ant žemės: sklype šviečia ➕ vietos (pradžioje – visur, vėliau – tik šalia namo). Užlipus ant vietos
  (arba „Build here“) atsidaro „What to build here?“ su kambariais, kuriuos gali statyti; pirmas įperkamas pažymėtas ⭐.
  Lygiai keliami House lange. Kambarys – namelis: akmens pamatas, sijos, langai, durys į visas puses, šlaitinis stogas
  kambario spalva; lygiai matosi (2 gėlių dėžutės, 3 kaminas su dūmais, 4 auksinis kraigas, 5 vėliava).
- **Balanso pastaba:** 4–5 kambario lygiai kainuoja iki ~1,9 mln. aukso (×10 / ×25), o rąstas – 2–40 aukso.
  Peržiūrėti, kai atsiras kova ir brangesni daiktai.
- **House Level** = visų kambarių lygių suma, kiekvienas lygis +1 % XP visiems įgūdžiams. Rodomas lentelėje prie vartų
  ir lyderių lentelėje (House).

## 3 dalis: kova ir Wraith Caves

- Wraith Caves – atskira zona kelio gale, combat 40+, wraith priešai (Wraith Imp, Goblin, Knight, Dragon).
- **PvP tik urvuose.** Mirus prarandi tik tai, ką surinkai urve šį kartą (urvo grobis), krepšys ir įranga saugūs.
  Grobis iškrenta žudikui. Išėjus iš urvo grobis tampa tavo.
- Robux urvuose galios neduoda: jokių pirktų ginklų, šarvų ar PvP bonusų.

## 4 dalis: Robux

Taisyklė: pirkiniai **greitina** arba **puošia**, bet niekada neleidžia praleisti renkimo/statymo ir neduoda PvP galios.
Jokių atsitiktinių mokamų daiktų (loot box) – visada aiškiai matai, ką perki.

- **Gamepass'ai (visam laikui):**
  - ⭐ 2x XP – dvigubas XP renkant ir amatuose (ne PvP).
  - 🌙 Long Rest – offline limitas 12 h → 24 h.
  - 🎒 Auto-Sell – parduoda pilną krepšį vienu paspaudimu bet kur.
  - 🏡 Extra Plot Styles – namo sklypo stiliai (sniegas, lava, sakura) – tik išvaizda.
- **Developer Products (vienkartiniai):**
  - ⚡ 30 min Boost: +50 % renkimo ir amatų greičio.
  - 💎 Gems (premium valiuta) paketai.
- **💎 Gems** – premium valiuta. Mažai jų gauni ir žaisdamas (lygio kilimai, kasdienis prisijungimas),
  daug – už Robux. Už Gems:
  - **Augintiniai** – perki konkretų (ne atsitiktinį), seka paskui, duoda mažą renkimo bonusą (+3–8 %),
    retesnius gali gauti ir žaisdamas (labai retas drop'as renkant).
  - **Enchantai įrankiams** – pvz. „Lucky“ (šansas gauti 2 vnt.), „Swift“ (+greitis).
    Žaidžiant gaunami per Enchant Scrolls (retas drop'as), už Gems – iškart.
  - Namo kosmetika: ypatingi baldai, šviesos, stogai.
- Visur rodoma aiški kaina ir ką gausi, pirkinius gali atšaukti prieš patvirtinant.

### Veikla namuose (kaip OSRS namas)

| Kambarys | Ką veikti |
| --- | --- |
| 🏡 Entrance Hall | House plans – atidaro House langą |
| 🪓 Woodshed | Kirtimo kaladė: Birch → Elder pagal kambario lygį |
| ⛏️ Ore Cellar | Rūdos gysla: Copper, Iron, Coal, Cobalt, Verdite pagal lygį |
| 🎣 Fish Pond | Žvejybos vieta: Roach → Eel pagal lygį |
| 🔨 Workshop | Dar vienas Workbench |
| 🏦 Treasury | Sell all |
| 🛏️ Bedroom | Rest – parodo offline laiką |

## Farming (padaryta)

- Kiekvieno sklypo pietinėje pusėje 6 lysvės: 3 daržai (bulvės → arbūzai), 2 žolelių (Greenleaf → Starbloom), 1 medžio (Farming 15).
- Auga realiu laiku (5 min – 4 h), todėl ir kai neprisijungęs. Derlius nepūva (advisor: reward > punishment).
- Sėklos: 🌱 Seed Stall Riverbend aikštėje ir 4 % šansas rasti sėklą renkant (geresni taškai – retesnės sėklos).
- Advisor: tai trumpasis „30 sekundžių“ ciklas (užeik, nuimk, pasodink) šalia ilgojo (renkimas, statymas).

## Toliau (ko dar trūksta)

1. **Cooking** – žuvis ir daržovės → maistas (reikės kovai).
2. **Kova + Wraith Caves PvP** (3 dalis).
3. **Herblore** – žolelės → eliksyrai (boost'ai, tinka ir Robux parduotuvės „ne pay-to-win“ taisyklei).
4. **Garden kambarys** – daugiau lysvių (kaip web žaidime PATCH_N pagal lygį).
5. **Robux parduotuvė**.

## Kova ir Wraith Caves (padaryta, 3 dalis)

- Įgūdžiai Attack, Strength, Defence, Hitpoints (startas – 10 HP lygis). Kovos lygis = ((Att+Str)/2 + Def + HP) / 3.
- Formulės iš web žaidimo: HP = 40 + 10 × Hitpoints; smūgio tikimybė 0,5 + (tikslumas − gynyba) × 0,02;
  XP = 2,5 už žalos tašką (stiliaus įgūdžiui) + 0,83 Hitpoints.
- Stiliai: Accurate (Attack), Aggressive (Strength), Defensive (Defence), Balanced (žemiausiam).
- Priešai visose zonose (Slime, Rat → Dragon Knight), atsiranda po 12 s. Mūšis vyksta pats, maistas (daržovės) valgomas
  automatiškai, kai HP < 40 %.
- ⚔️ Smithy Riverbend aikštėje: kardai ir šarvai Bronze → Wyrmsteel (reikia Attack / Defence lygio).
- ☠️ Wraith Caves – šiaurėje už Ice Mountains, nuo kovos lygio 40. PvP: „Attack“ ant kitų žaidėjų, auto-atsakymas.
  Uždirbtas auksas ir Wraith Ether yra „urvo grobis“; išėjus – tavo, mirus – prarandi tik jį (žudikas pasiima).
  Išėjus iš žaidimo kovos metu (15 s) grobis atitenka užpuolikui.
- Balanso pastaba: Wraith Caves nuo 40 kovos lygio – ilgas kelias; jei per ilgas, mažinti `Combat.WILD_REQ`.

## Valdymas ir pasaulis (atnaujinta)

- **Paspausk ir veik (kaip OSRS):** paspaudus medį, uolą, monstrą, lysvę ar stotelę hero pats nueina ir pradeda;
  paspaudus žemę – eina ten. Telefone iššokantys E/F mygtukai paslėpti (advisor: aiškumas, mažiau triukšmo).
- **Haunted Swamp** (pietūs, 20+): Bog Horror, Will-o'-Wisp, žvejyba. Daugiau monstrų stovyklų visose zonose (`Combat.CAMPS`).
- Medžiai, uolos ir dekoracijos – Synty Nature Pack modeliai.
