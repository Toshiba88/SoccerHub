# Plan de découpage Soccer Hub

Version de référence locale : `soccer_hub_v33_index_order_fixed.lua`.

Objectif : présenter le projet sous forme modulaire sans perdre les fonctions existantes.

## Ordre conseillé

1. Garder le fichier complet en backup local.
2. Extraire `Index` en premier.
3. Tester que l'onglet Index charge toujours cartes, mutations, trophées et classement.
4. Extraire `Tournament`.
5. Tester auto-join, money check, lecture tokens, fermeture shop.
6. Extraire SpinWheel.
7. Extraire AutoBuy / AutoCollect.
8. Extraire Anti-AFK / Console / Config.

## Structure cible

```text
main.lua
modules/core.lua
modules/ui.lua
modules/remotes.lua
modules/index.lua
modules/tournament.lua
modules/spinwheel.lua
modules/autobuy.lua
modules/autocollect.lua
modules/antiafk.lua
modules/console.lua
modules/config.lua
legacy/Soccer hub backup.lua
```

## Règle de sécurité projet

Chaque extraction doit garder :

- mêmes onglets,
- mêmes options,
- mêmes valeurs par défaut,
- mêmes logs,
- mêmes comportements observés dans la version v33.

Si une extraction casse, revenir au backup local v33 puis corriger uniquement le module concerné.
