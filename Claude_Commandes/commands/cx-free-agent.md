---
description: Lance un agent Codex Home delegue depuis Claude Code
argument-hint: "[modele] [--write] <mission>"
allowed-tools: Bash(pwsh:*), Read, Glob, Grep
---
Lance un agent Codex independant depuis Claude Code, dans le depot courant, via Codex Home headless.

Arguments bruts : $ARGUMENTS

Le modele par defaut est deepseek-flash. Les modeles et aliases sont ceux de /cx-free-models. Le flag --write est requis pour autoriser l agent a modifier le depot. Sans ce flag, le sandbox est read-only.

Marche a suivre :

1. Si le premier token est un modele ou un alias reconnu, utilise-le. Sinon utilise deepseek-flash et considere tous les tokens restants comme la mission.
2. Lance le helper en remplacant les valeurs entre chevrons :

       pwsh -NoProfile -File "$env:USERPROFILE\.claude\scripts\cx-free.ps1" -Mode agent -Model "<modele>" -Repo "<cwd>" [-Write] -Prompt "<mission>"

3. Restitue le compte rendu final affiche apres le titre RAPPORT CODEX-HOME.
4. Pour plusieurs agents, lance plusieurs invocations avec des missions distinctes. Evite plusieurs agents en ecriture dans le meme depot ou les memes fichiers ; utilise des worktrees separes pour le travail parallele.

Chaque invocation utilise .codex-openai, le proxy dedie 4100/4101 et le lanceur codex-home.ps1 -Headless. Elle ne lance pas la fenetre graphique Codex et ne touche pas au home original .codex.

