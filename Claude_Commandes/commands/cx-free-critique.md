---
description: Revue adversariale read-only par Codex Home
argument-hint: "[modele] [base-ref]"
allowed-tools: Bash(pwsh:*), Read, Glob, Grep
---
Fais executer une revue adversariale des changements par Codex Home, en cherchant les regressions et les scenarii d exploitation reels.

Arguments bruts : $ARGUMENTS

Le modele par defaut est deepseek-flash, qui correspond a DeepSeek V4.1 Flash. Modeles acceptes :

- kimi-k2.6
- kimi-k2.7-code
- kimi-k2.7-code-highspeed
- kimi-k3
- deepseek-v4-pro
- deepseek-v4-flash
- deepseek-flash
- mina-flash
- mina-low
- mina-full

Aliases : deepseek, ds, deepseek-pro, kimi, kimi-2.6 et deepseek-v4.1-flash.

Marche a suivre :

1. Si le premier token est un modele ou un alias, utilise-le. Sinon utilise deepseek-flash et traite ce token comme la reference git de base.
2. Le second token est une reference git optionnelle, par exemple main. Sans reference, cible le travail non commite.
3. Lance :

       pwsh -NoProfile -File "$env:USERPROFILE\.claude\scripts\cx-free.ps1" -Mode critique -Model "<modele>" -Repo "<cwd>" [-Base "<base-ref>"]

   Le helper travaille uniquement avec .codex-openai et les ports dedies 4100/4101. Il ne lance pas la fenetre graphique Codex.
4. Restitue verbatim le rapport affiche apres le titre RAPPORT CODEX-HOME, sans ajouter ta propre analyse.
