# Module config.lua

Statut : à extraire depuis la version v33.

Fonctions prévues :

- Initialiser SaveManager dans l'onglet Sauvegarde.
- Initialiser InterfaceManager dans l'onglet Apparence.
- Charger la configuration autoload si disponible.

Dépendances ctx prévues :

```text
ctx.Fluent
ctx.SaveManager
ctx.InterfaceManager
ctx.Tabs.Config
ctx.Tabs.Interface
ctx.Log
```

Ce module doit remplacer le bloc de fin de fichier qui initialise SaveManager et InterfaceManager.
