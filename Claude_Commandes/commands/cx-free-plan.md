---
description: Produit un plan read-only par Codex Home pour une demande technique
argument-hint: "[modele] <demande>"
allowed-tools: Bash(pwsh:*), Read, Glob, Grep
---
Demande a Codex Home d analyser le depot et de proposer un plan d implementation, sans modifier les fichiers.

Arguments bruts : $ARGUMENTS

Le modele par defaut est deepseek-flash. Les modeles et aliases sont ceux de /cx-free-models et /cx-free-review.

Marche a suivre :

1. Si le premier token est un modele ou un alias reconnu, utilise-le. Sinon utilise deepseek-flash et considere tous les tokens comme la demande.
2. Lance le helper avec le chemin absolu du depot courant :

       pwsh -NoProfile -File "$env:USERPROFILE\.claude\scripts\cx-free.ps1" -Mode plan -Model "<modele>" -Repo "<cwd>" -Prompt "<demande>"

3. Restitue le plan final et distingue les faits constates, les hypotheses, les fichiers concernes, les tests et les criteres d acceptation.

Le helper reste en lecture seule, utilise .codex-openai et ne lance pas la fenetre graphique Codex.

