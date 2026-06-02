# Source map v33

Fichier reçu : `Texte collé.txt`.

Taille : 4451 lignes.

Version indiquée dans la fenêtre : `v33 Index Order Fixed`.

## Repères principaux

```text
0001-0156  Boot, services Roblox, chargement Fluent/SaveManager/InterfaceManager, variables globales
0157-0317  Fonctions core : destroy, SafeFullName, SafeNumber, StatusDot, SetParagraph, Log, Notify
0318-0410  Remotes : RefreshRemotes, FireRemote, parsing stock, sélection packs
0411-0784  AutoBuy / stock / drain packs
0785-0856  AutoCollect
0857-1113  SpinWheel data / claim_free / spin / loops
1114-1336  Anti-AFK multi méthodes
1337-1569  Restock watcher PackShop
1572-3120  Tournament module : InitTournamentModule
3124-3949  Index global : cartes, mutations, trophées, classement custom
3951-4012  Création fenêtre Fluent + onglets
4014-4020  Initialisation accueil, tournament, index
4022-4082  UI AutoBuy
4084-4119  UI AutoCollect
4121-4186  UI SpinWheel
4188-4269  UI Settings Anti-AFK
4271-4295  Config + Interface managers
4297-4359  Console buttons/debug
4361-4451  Startup loops, logs init, autoload config
```

## Découpage cible sans perte

```text
main.lua
modules/core.lua
modules/remotes.lua
modules/autobuy.lua
modules/autocollect.lua
modules/spinwheel.lua
modules/antiafk.lua
modules/restock.lua
modules/tournament.lua
modules/index.lua
modules/ui_main.lua
modules/config.lua
modules/console.lua
legacy/Soccer hub backup.lua
```

## Étape 1 recommandée

Extraire `Index` uniquement :

```text
Source : lignes 3124-3949
Destination : modules/index.lua
Entrée module : return function(ctx) ... end
Dépendances ctx :
- ctx.Tabs.Index
- ctx.Log
- ctx.SetParagraph
- ctx.AddConnection
- ctx.ReplicatedStorage
- ctx.playerGui
```

## Étape 2

Extraire `Tournament` :

```text
Source : lignes 1572-3120
Destination : modules/tournament.lua
Entrée module : return function(ctx) ... end
Dépendances ctx :
- ctx.Tabs.Tournament
- ctx.Log
- ctx.Notify
- ctx.SetParagraph
- ctx.StatusDot
- ctx.SafeNumber
- ctx.SafeFullName
- ctx.AddConnection
- ctx.IsCurrentRun
- ctx.UpdateStatus
- ctx.ReplicatedStorage
- ctx.playerGui
```

## Règle de validation

Après chaque extraction, comparer avec le backup v33 :

```text
- mêmes onglets
- mêmes toggles
- mêmes dropdowns
- mêmes inputs
- mêmes logs
- même comportement en test Studio client-side
```
