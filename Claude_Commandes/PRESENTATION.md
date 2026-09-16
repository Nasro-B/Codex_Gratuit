# CX-FREE : agents Codex Home depuis Claude Code

## Principe

Les commandes /cx-free-* de Claude deleguent le travail a Codex CLI en mode headless. Le flux utilise exclusivement le profil .codex-openai, le lanceur codex-home.ps1 en mode Headless et les ports dedies 4100 et 4101.

Le profil original .codex n est pas modifie. L application graphique Codex n est pas lancee par les commandes Claude.

## Commandes disponibles

| Commande | Fonction |
| --- | --- |
| /cx-free-review | Revue de code en lecture seule. |
| /cx-free-critique | Revue adversariale en lecture seule. |
| /cx-free-task | Demande libre, avec --write optionnel. |
| /cx-free-agent | Mission explicite deleguee a un agent Codex. |
| /cx-free-plan | Plan technique en lecture seule. |
| /cx-free-models | Modeles et contextes reels du catalogue. |
| /cx-free-health | Test du pont local sans completion LLM. |
| /cx-free-status | Etat local sans demarrage. |

## Modeles

- Kimi K2.6 : kimi-k2.6, contexte 262144
- Kimi K2.7 Code : kimi-k2.7-code, contexte 262144
- Kimi K2.7 Code HighSpeed : kimi-k2.7-code-highspeed, contexte 262144
- Kimi K3 : kimi-k3, contexte 1048576
- DeepSeek V4 Pro : deepseek-v4-pro, contexte 1048576
- DeepSeek V4 Flash legacy : deepseek-v4-flash, contexte 1048576
- DeepSeek V4.1 Flash : deepseek-flash, contexte 1048576
- Mina Flash CloudZIR : mina-flash, contexte 64000
- Mina Low CloudZIR : mina-low, contexte 128000
- Mina Full CloudZIR : mina-full, contexte 256000

Aliases conserves pour compatibilite : deepseek, ds, deepseek-pro, kimi, kimi-2.6 et deepseek-v4.1-flash.

## Exemples

    /cx-free-review
    /cx-free-review kimi-k2.7-code main
    /cx-free-critique deepseek-v4-pro
    /cx-free-task mina-flash explique ce module
    /cx-free-task kimi-k2.7-code-highspeed --write implemente la correction
    /cx-free-agent kimi-k2.7-code analyse puis corrige ce bug
    /cx-free-plan deepseek-v4-pro prepare le plan de migration
    /cx-free-models
    /cx-free-health mina-full
    /cx-free-status

## Delegation d agents

/cx-free-agent execute une invocation independante de codex exec avec une mission structuree. L ecriture est interdite par defaut et n est activee qu avec --write.

Pour plusieurs agents, plusieurs invocations peuvent etre lancees avec des missions distinctes. Les agents en ecriture doivent avoir des worktrees distincts pour eviter les conflits. Plusieurs agents en lecture seule peuvent verifier le meme depot.

## Flux technique

    Claude Code
        |
        | /cx-free-agent
        v
    ~/.claude/scripts/cx-free.ps1
        |
        | codex-home.ps1 -Headless
        | CODEX_HOME=.codex-openai
        v
    127.0.0.1:4101
        |
        v
    LiteLLM 127.0.0.1:4100
        |
        v
    Kimi, DeepSeek ou CloudZIR

/cx-free-models et /cx-free-status ne demarrent aucun processus. /cx-free-health peut demarrer le proxy et le pont headless, puis verifie la liste /v1/models. Les commandes review, critique, plan, task et agent lancent ensuite codex exec selon leur mission.

Le proxy Codex Home est dedie aux ports 4100 et 4101. Son demarrage est idempotent et protege contre deux demarrages concurrents. Un processus externe occupant ces ports est refuse, jamais tue.

## Installation

    pwsh -NoProfile -File "C:\Serveurs\Codex Gratuit\Claude_Commandes\install.ps1"

L installation copie les commandes dans ~/.claude/commands, le helper dans ~/.claude/scripts et les prompts Codex Home dans ~/.codex-openai/prompts. Elle ne modifie pas ~/.codex.

## Limite assumee

La commande lance des agents Codex CLI headless. Elle ne lance pas automatiquement plusieurs agents en parallele dans un meme depot et ne lance pas la fenetre graphique Codex. Pour l execution parallele, il faut des invocations separees et des worktrees isoles si elles ecrivent.
