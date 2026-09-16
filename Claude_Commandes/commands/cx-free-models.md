---
description: Liste les modeles Codex Home et leurs fenetres de contexte
allowed-tools: Bash(pwsh:*)
---
Affiche le catalogue reel des modeles disponibles dans Codex Home, avec la fenetre de contexte, les modalites et l etat de configuration.

Lance :

       pwsh -NoProfile -File "$env:USERPROFILE\.claude\scripts\cx-free.ps1" -Mode models

Cette commande est en lecture seule. Elle lit litellm-models.json et ne demarre ni LiteLLM, ni le pont API, ni l application graphique Codex.
