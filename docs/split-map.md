# SoccerHub real split

Cette archive contient un vrai découpage du fichier `soccer_hub_v33_index_order_fixed.lua`.

Important :
- `legacy/Soccer hub backup.lua` contient le script complet original.
- Les fichiers `modules/*.lua` contiennent des vrais blocs du script original, pas des placeholders.
- `main.lua` recompose les blocs dans l'ordre original puis exécute le résultat.
- Cette méthode évite de perdre des fonctions pendant la première étape du découpage.

## Structure

```text
SoccerHub/
├─ main.lua
├─ main_raw_template.lua
├─ modules/
│  ├─ core.lua
│  ├─ ui.lua
│  ├─ remotes.lua
│  ├─ index.lua
│  ├─ tournament.lua
│  ├─ spinwheel.lua
│  ├─ autobuy.lua
│  ├─ autocollect.lua
│  ├─ antiafk.lua
│  ├─ console.lua
│  └─ config.lua
└─ legacy/
   └─ Soccer hub backup.lua
```

## Taille des modules

```text
antiafk.lua            8652 bytes
autobuy.lua           18475 bytes
autocollect.lua        2376 bytes
config.lua             1065 bytes
console.lua            3393 bytes
core.lua              11182 bytes
index.lua             26163 bytes
remotes.lua            1286 bytes
spinwheel.lua         10009 bytes
tournament.lua        50859 bytes
ui.lua                 1746 bytes
```

## Découpage par lignes

```text
core.lua         lignes 0001-0376 + startup 4375-4451
remotes.lua      lignes 0377-0411
autobuy.lua      lignes 0412-0934 + restock 1464-1568 + UI 4022-4083
autocollect.lua  lignes 0935-0971 + UI 4084-4119
spinwheel.lua    lignes 0972-1250 + UI 4121-4186
antiafk.lua      lignes 1251-1463 + UI 4188-4271
tournament.lua   lignes 1569-3123
index.lua        lignes 3124-3950
ui.lua           lignes 3951-4021
config.lua       lignes 4272-4292
console.lua      lignes 4293-4374
```
