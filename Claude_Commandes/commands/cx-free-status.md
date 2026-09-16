---
description: Etat de Codex Home, de son home dedie et de ses ports
allowed-tools: Bash(pwsh:*)
---
Affiche l etat du raccordement Claude vers Codex Home, sans demarrer de proxy et sans lancer d application.

Lance :

       pwsh -NoProfile -File "$env:USERPROFILE\.claude\scripts\cx-free.ps1" -Mode status

Restitue la sortie, notamment :

- le chemin .codex-home utilise par les commandes cx-free ;
- l etat du proxy LiteLLM 4100 et du pont API 4101 ;
- la liste des modeles Codex Home.

Le home original .codex et le proxy historique 4000 ne sont pas utilises par cette commande.
