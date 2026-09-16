---
description: Revue de code read-only par Codex Home avec DeepSeek, Kimi ou Mina
argument-hint: "[modele] [base-ref]"
allowed-tools: Bash(pwsh:*), Read, Glob, Grep
---
Fais relire les changements du depot par Codex Home en lecture seule.

Arguments bruts : $ARGUMENTS

Modeles disponibles :

- kimi-k2.6
- kimi-k2.7-code
- kimi-k2.7-code-highspeed
- kimi-k3
- deepseek-v4-pro
- deepseek-v4-flash
- deepseek-flash (DeepSeek V4.1 Flash, modele par defaut)
- mina-flash
- mina-low
- mina-full

Aliases : deepseek, ds, deepseek-pro, kimi, kimi-2.6 et deepseek-v4.1-flash.

Marche a suivre :

1. Si le premier token est un modele ou un alias, utilise-le. Sinon utilise deepseek-flash et considere le premier token comme la reference git de base.
2. Le second token restant est une reference git optionnelle, par exemple main. Sans reference, demande la revue du travail non commite.
3. Lance le helper avec le chemin absolu du depot courant :

       pwsh -NoProfile -File "$env:USERPROFILE\.claude\scripts\cx-free.ps1" -Mode review -Model "<modele>" -Repo "<cwd>" [-Base "<base-ref>"]

   Le helper fixe CODEX_HOME uniquement dans son processus vers le home personnel .codex-home, prepare le proxy 4100/4101 et n ouvre jamais l application graphique.
4. Restitue le rapport final affiche apres le titre RAPPORT CODEX-HOME. N ajoute pas une seconde relecture.
5. Un modele hors de cette liste doit etre signale comme indisponible dans Codex Home.
