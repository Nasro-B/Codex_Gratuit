---
description: Teste le pont headless Codex Home et la visibilite d un modele
argument-hint: "[modele]"
allowed-tools: Bash(pwsh:*)
---
Teste le raccordement local Codex Home sans envoyer de demande a un modele.

Le modele par defaut est deepseek-flash. Si un modele est fourni, il doit faire partie de la liste de /cx-free-models.

Lance :

       pwsh -NoProfile -File "$env:USERPROFILE\.claude\scripts\cx-free.ps1" -Mode health -Model "<modele>"

Le test peut demarrer uniquement les processus headless du proxy LiteLLM 4100 et du pont 4101, puis verifie /v1/models. Il ne lance pas l application graphique Codex et ne touche pas au home original .codex.
