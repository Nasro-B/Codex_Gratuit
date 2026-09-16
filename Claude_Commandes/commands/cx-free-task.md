---
description: Envoie une tache a Codex Home avec un modele DeepSeek, Kimi ou Mina
argument-hint: "[modele] [--write] <demande>"
allowed-tools: Bash(pwsh:*), Read, Glob, Grep
---
Envoie une demande a Codex Home en mode headless, avec le home dedie .codex-openai.

Arguments bruts : $ARGUMENTS

Modeles disponibles :

- kimi-k2.6
- kimi-k2.7-code
- kimi-k2.7-code-highspeed
- kimi-k3
- deepseek-v4-pro
- deepseek-v4-flash
- deepseek-flash (DeepSeek V4.1 Flash)
- mina-flash
- mina-low
- mina-full

Aliases de compatibilite : deepseek, ds, deepseek-pro, kimi, kimi-2.6 et deepseek-v4.1-flash.
Les anciens noms hf, nvidia et glm ne sont plus des modeles cx-free.

Marche a suivre :

1. Si le premier token est un modele ou un alias reconnu, utilise-le. Sinon le modele est deepseek-flash et tout l argument reste la demande.
2. Le flag --write autorise les modifications dans le depot avec le sandbox workspace-write. Sans ce flag, reste en lecture seule.
3. Lance le helper en remplacant les valeurs entre chevrons :

       pwsh -NoProfile -File "$env:USERPROFILE\.claude\scripts\cx-free.ps1" -Mode task -Model "<modele>" -Repo "<cwd>" [-Write] -Prompt "<demande>"

   Le helper configure .codex-openai, appelle le lanceur racine codex-home.ps1 -Headless et utilise le pont 4101 vers LiteLLM 4100. Il ne lance pas la fenetre graphique Codex.
4. Restitue le rapport final affiche apres le titre RAPPORT CODEX-HOME.
5. En cas d erreur, restitue le message exact et indique si le blocage vient du CLI, des dependances, des variables de l environnement ou des ports 4100/4101.
