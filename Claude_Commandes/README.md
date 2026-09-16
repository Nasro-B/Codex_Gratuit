# Claude_Commandes - Pont Claude vers Codex Home

Ces commandes slash font executer une revue, une tache ou un plan par Codex CLI en utilisant exclusivement le home dedie .codex-openai et le proxy Codex Home. Le home original .codex n est ni lu ni modifie par ce raccordement.

## Commandes

| Commande | Usage |
| --- | --- |
| /cx-free-review [modele] [base-ref] | Revue de code en lecture seule. |
| /cx-free-critique [modele] [base-ref] | Revue adversariale en lecture seule. |
| /cx-free-task [modele] [--write] demande | Tache libre. --write autorise l ecriture dans le depot. |
| /cx-free-agent [modele] [--write] mission | Lance un agent Codex delegue depuis Claude. |
| /cx-free-plan [modele] demande | Plan d implementation en lecture seule. |
| /cx-free-models | Catalogue des modeles et fenetres de contexte. |
| /cx-free-health [modele] | Test du proxy et du pont headless, sans appel LLM. |
| /cx-free-status | Etat local, sans demarrage de processus. |

## Modeles Codex Home

Les fenetres ci-dessous sont celles du catalogue utilise par Codex Home :

| Identifiant | Libelle | Fenetre de contexte |
| --- | --- | ---: |
| kimi-k2.6 | Kimi K2.6 | 262144 tokens |
| kimi-k2.7-code | Kimi K2.7 Code | 262144 tokens |
| kimi-k2.7-code-highspeed | Kimi K2.7 Code HighSpeed | 262144 tokens |
| kimi-k3 | Kimi K3 | 1048576 tokens |
| deepseek-v4-pro | DeepSeek V4 Pro | 1048576 tokens |
| deepseek-v4-flash | DeepSeek V4 Flash, identifiant legacy | 1048576 tokens |
| deepseek-flash | DeepSeek V4.1 Flash | 1048576 tokens |
| mina-flash | Mina Flash, CloudZIR | 64000 tokens |
| mina-low | Mina Low, CloudZIR | 128000 tokens |
| mina-full | Mina Full, CloudZIR | 256000 tokens |

Aliases de compatibilite : deepseek, ds, deepseek-pro, kimi, kimi-2.6 et deepseek-v4.1-flash. Les routes historiques hf, nvidia et glm ne sont plus utilisees par /cx-free.

## Exemples

    /cx-free-review
    /cx-free-review kimi-k2.7-code main
    /cx-free-critique deepseek-v4-pro
    /cx-free-task mina-flash explique ce module
    /cx-free-task kimi-k2.7-code-highspeed --write implemente la correction demandee
    /cx-free-agent kimi-k2.7-code analyse ce depot et corrige le bug indique
    /cx-free-plan deepseek-v4-pro prepare la migration
    /cx-free-models
    /cx-free-health mina-full
    /cx-free-status

## Architecture d isolation

Le chemin d execution est :

    Claude /cx-free-* -> ~/.claude/scripts/cx-free.ps1
                         -> codex-home.ps1 -Headless
                         -> CODEX_HOME=.codex-openai
                         -> pont 127.0.0.1:4101
                         -> LiteLLM 127.0.0.1:4100
                         -> fournisseur selectionne

/cx-free-agent est le mode explicite pour deleguer une mission complete a un agent Codex. Il reprend les memes controles que /cx-free-task : lecture seule par defaut et ecriture uniquement avec --write. Plusieurs agents peuvent etre lances par plusieurs invocations, mais les agents en ecriture doivent travailler dans des worktrees distincts.

La variable CODEX_HOME est definie uniquement dans le processus du helper et ses enfants. L application graphique Codex n est jamais lancee par les commandes Claude. Le lanceur graphique codex-home.ps1 reste disponible separement pour ouvrir le clone.

Les ports 4100 et 4101 sont dedies a Codex Home. Le proxy historique 4000 et le home .codex original restent hors de ce flux. Le proxy Codex Home doit etre idempotent : une nouvelle commande cx-free ne doit pas arreter un proxy Codex Home deja actif.

## Installation

    pwsh -NoProfile -File "C:\Serveurs\Codex Gratuit\Claude_Commandes\install.ps1"

L installeur copie :

- commands/*.md vers ~/.claude/commands/
- scripts/cx-free.ps1 vers ~/.claude/scripts/
- prompts/*.md vers ~/.codex-openai/prompts/

L installeur ne modifie pas ~/.codex. Recharge Claude Code apres installation pour afficher les nouvelles commandes.

## Prerequis

- Codex CLI disponible dans le PATH.
- Node.js et LiteLLM disponibles dans le PATH.
- C:\Serveurs\Codex Gratuit\codex-home.ps1 present.
- ~/.codex-openai/config.toml present.
- Les variables fournisseurs sont conservees dans C:\Serveurs\Codex Gratuit\litellm-codex\.env, qui ne doit jamais etre commite.
- Les dependances et les variables doivent etre presentes avant le premier /cx-free-health, /cx-free-review, /cx-free-critique, /cx-free-plan, /cx-free-task ou /cx-free-agent.

## Verification rapide

    pwsh -NoProfile -File "$env:USERPROFILE\.claude\scripts\cx-free.ps1" -Mode models
    pwsh -NoProfile -File "$env:USERPROFILE\.claude\scripts\cx-free.ps1" -Mode status
    pwsh -NoProfile -File "$env:USERPROFILE\.claude\scripts\cx-free.ps1" -Mode health -Model deepseek-flash

/cx-free-models et /cx-free-status sont sans demarrage. /cx-free-health peut demarrer uniquement le proxy et le pont headless, puis verifie que le modele demande apparait dans /v1/models. Aucun test de completion n est effectue par cette commande.

## Depannage

- Si le status indique DOWN, c est normal tant qu aucune commande qui necessite le proxy n a ete lancee.
- Si health echoue, verifier Node.js, LiteLLM, le fichier .env, le fichier ~/.codex-openai/config.toml et la disponibilite des ports 4100 et 4101.
- Un port occupe par un autre programme est refuse explicitement. Le script ne tue pas un processus dont la ligne de commande ne correspond pas a ce projet.
- Les erreurs d un appel LLM restent distinctes du test health : health verifie le branchement local et la visibilite du modele, pas la validite distante de chaque fournisseur.

## Contenu

    Claude_Commandes/
    |-- README.md
    |-- PRESENTATION.md
    |-- install.ps1
    |-- commands/
    |   |-- cx-free-review.md
    |   |-- cx-free-critique.md
    |   |-- cx-free-task.md
    |   |-- cx-free-agent.md
    |   |-- cx-free-plan.md
    |   |-- cx-free-models.md
    |   |-- cx-free-health.md
    |   |-- cx-free-status.md
    |-- scripts/
    |   |-- cx-free.ps1
    |-- prompts/
        |-- relire.md
        |-- relire-critique.md
