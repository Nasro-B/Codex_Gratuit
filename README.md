# 🚀 Codex Gratuit

![Codex Banner](assets/codex_banner.png)

**Utilise l'application [OpenAI Codex](https://openai.com/codex/) avec des LLM gratuits ou moins chers** - DeepSeek, Kimi, NVIDIA NIM, Hugging Face - via un proxy local transparent.

Kimi est intégré avec les modèles `kimi-k2.6`, `kimi-k2.7-code`, `kimi-k2.7-code-highspeed` et `kimi-k3`.

L'app Codex est un IDE IA puissant (terminal, navigateur, éditeur de fichiers, MCP, plugins), mais elle nécessite un abonnement OpenAI payant. **Codex Gratuit** te permet d'utiliser cette même application avec tes propres clés API gratuites ou low-cost, sans modifier l'app elle-même.

---

## 📋 Prérequis

> ⚠️ **IMPORTANT** : Tu dois d'abord installer l'application Codex et connecter ton compte OpenAI.
> Le lanceur ne remplace pas Codex - il redirige ses requêtes vers d'autres backends.

### 1. Installer l'application Codex

Télécharge et installe **OpenAI Codex** depuis le [Microsoft Store](https://apps.microsoft.com/detail/openai-codex) ou depuis [openai.com/codex](https://openai.com/codex/).

### 2. Connecter ton compte OpenAI

Au premier lancement de Codex :

- Connecte-toi avec ton **compte OpenAI** (même un compte gratuit suffit)
- L'app va créer son fichier de configuration `config.toml` dans `~\.codex\`
- Codex doit démarrer au moins une fois normalement pour initialiser ses fichiers

### 3. Installer les dépendances

```powershell
# Python 3.10+ requis
python --version

# Installer uv (gestionnaire de paquets Python moderne)
powershell -c "irm https://astral.sh/uv/install.ps1 | iex"

# Installer LiteLLM via uv
uv tool install litellm

# Vérifier l'installation
litellm --version
```

### 4. Obtenir tes clés API (gratuit)

| Fournisseur | Lien | Coût |
|------------|------|------|
| **DeepSeek** | [platform.deepseek.com](https://platform.deepseek.com/) | ~0.14$/M tokens (flash) |
| **Kimi / Moonshot AI** | [platform.kimi.ai](https://platform.kimi.ai/) | Selon le modèle et le compte |
| **CloudZIR** | [api.cloudzir.com](https://api.cloudzir.com/) | Selon le modèle et le compte |
| **NVIDIA NIM** | [build.nvidia.com](https://build.nvidia.com/) | Gratuit (1000 crédits offerts) |
| **Hugging Face** | [huggingface.co/settings/tokens](https://huggingface.co/settings/tokens) | Gratuit (Inference API) |

---

## ⚡ Installation rapide

```powershell
# 1. Clone ou copie le projet
git clone <repo-url> "C:\Serveurs\Codex Gratuit"

# 2. Copie le template et remplis tes clés API
cd "C:\Serveurs\Codex Gratuit\litellm-codex"
cp .env.example .env
notepad .env    # ← remplis tes clés ici

# 3. Double-clic sur le raccourci "Codex (menu).lnk" pour lancer !
```

---

## 🎯 Utilisation

### Lancer via le menu

Double-clique sur **`Codex (menu).lnk`** ou exécute directement :

```powershell
pwsh -File "C:\Serveurs\Codex Gratuit\codex-launch.ps1"
```

Le menu interactif s'affiche :

```
  ===== LANCEUR CODEX =====

   1) DeepSeek-V4-flash      rapide, pas cher          [outils]  <- recommande
   2) DeepSeek-V4-pro        plus fort (ton compte)    [outils]
   3) Kimi K2.6              256k, multimodal         [outils]
   4) Kimi K3                1M, flagship             [outils]
   5) NVIDIA DeepSeek-V4-pro indisponible via proxy    [desactive]
   6) NVIDIA GLM-5.1         EOL                       [desactive]
   7) HuggingFace Qwen3.6    gratuit                  [outils]
   8) Mon compte OpenAI      gpt-5.5                  [compte]
   9) Ollama cloud           minimax (ollama signin)  [cloud]

  Ton choix (1-9) :
```

Choisis un numéro → le lanceur :

1. Configure le modèle dans `config.toml`
2. Conserve les serveurs MCP activés (backup automatique dans `mcp-backup.toml`)
3. Démarre le proxy LiteLLM si nécessaire
4. Lance l'application Codex

### Lanceur isolé `codex-home`

Le clone personnel installé avec l'identité Windows `Nasro.Codex.Free` se lance avec :

```powershell
pwsh -File "G:\Serveurs\Codex-Free-Clone\codex-home.ps1"
```

Ce lanceur utilise le home personnel `C:\Users\<user>\.codex-home`, le runtime `G:\Serveurs\Codex-Free-Clone\runtime` et les ports `4100` et `4101`, puis démarre uniquement le clone. Le sélecteur de modèles de Codex reçoit directement les modèles Kimi, DeepSeek et Mina. Le Codex Gratuit du projet GitHub reste sur `C:\Users\<user>\.codex-openai` et les ports `4000` et `4001`. Le Codex original reste sur `C:\Users\<user>\.codex`.

Le lanceur démarre sur `deepseek-flash` sans imposer de menu. Le changement de modèle se fait dans le sélecteur Codex, sans redémarrer l'application :

| Choix | Modèle | Contexte |
|---|---|---:|
| - | Kimi K2.6 | 256k |
| - | Kimi K2.7 Code | 256k |
| - | Kimi K2.7 Code HighSpeed | 256k |
| - | Kimi K3 | 1M |
| - | DeepSeek V4 Pro | 1M |
| - | DeepSeek V4 Flash, identifiant legacy | 1M |
| - | DeepSeek V4.1 Flash | 1M |
| - | Mina Flash, CloudZIR | 64k |
| - | Mina Low, CloudZIR | 128k |
| - | Mina Full, CloudZIR | 256k |

Les clés du Codex Gratuit restent dans `C:\Serveurs\Codex Gratuit\litellm-codex\.env`. Les clés du Codex Home personnel restent dans `G:\Serveurs\Codex-Free-Clone\runtime\.env`. Ces fichiers sont séparés et ne doivent jamais être commités. Aucun lanceur n'écrit une clé dans `config.toml`, dans le catalogue ou dans le paquet.

### Modèles disponibles

| # | Modèle | Fournisseur | MCP | Proxy | Notes |
|---|--------|-------------|-----|-------|-------|
| 1 | DeepSeek-V4-flash | DeepSeek | ✅ | ✅ | **Recommandé** - rapide et pas cher |
| 2 | DeepSeek-V4-pro | DeepSeek | ✅ | ✅ | Plus puissant, plus cher |
| 3 | Kimi K2.6 | Kimi / Moonshot AI | local | ✅ | Multimodal, thinking, contexte 256k |
| 4 | Kimi K3 | Kimi / Moonshot AI | local | ✅ | Flagship, raisonnement, contexte 1M |
| 5 | DeepSeek-V4-pro | NVIDIA NIM | - | ❌ | Désactivé via ce proxy |
| 6 | GLM-5.1 | NVIDIA NIM | - | ❌ | EOL côté NVIDIA |
| 7 | Qwen3-Coder-Next | Hugging Face | local | ✅ | Gratuit (Inference API) |
| 8 | gpt-5-codex | OpenAI | ✅ | ❌ | Ton abonnement OpenAI |
| 9 | minimax-m3:cloud | Ollama cloud | ✅ | ❌ | Nécessite `ollama signin` |

> **MCP** = Model Context Protocol (serveurs externes comme Supabase, Playwright, Figma…).
> Le serveur interne `node_repl` reste géré par Codex. Les serveurs MCP externes sont coupés pour les providers chat gratuits lorsque leur OAuth bloque le démarrage.
> `mcp-backup.toml` est un **filet de secours** : restaure-le manuellement si une màj de Codex efface tes serveurs MCP.

---

## 🏗️ Comment ça marche

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Application Codex                         │
│              (pense parler à OpenAI)                         │
│         envoie ses requêtes en API "Responses"               │
└──────────────────────┬──────────────────────────────────────┘
                       │ http://127.0.0.1:4001/v1/
                       ▼
┌─────────────────────────────────────────────────────────────┐
│           Pont Node (:4001) - codex-litellm-proxy.js         │
│   Corrige GET /v1/models : {"data":[...]} → {"models":[...]} │
│   (format attendu par Codex) puis forwarde tout vers :4000   │
└──────────────────────┬──────────────────────────────────────┘
                       │ http://127.0.0.1:4000
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                   LiteLLM Proxy (:4000)                      │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐     │
│  │  Wildcard "*" : intercepte TOUT nom de modèle       │     │
│  │  (gpt-5.5, gpt-5-codex, etc.) et redirige vers     │     │
│  │  le backend choisi dans le menu                     │     │
│  └─────────────────────────────────────────────────────┘     │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐     │
│  │  codex_deepseek_fix.py (callback pre-call)          │     │
│  │  Réordonne les tool_calls/outputs pour satisfaire   │     │
│  │  la validation stricte de DeepSeek                  │     │
│  └─────────────────────────────────────────────────────┘     │
│                                                              │
│  Pont automatique : API Responses → chat/completions         │
└──────────┬──────────┬──────────┬────────────────────────────┘
           │          │          │
           ▼          ▼          ▼
      DeepSeek    Kimi    NVIDIA NIM   Hugging Face
```

### Le mécanisme du Wildcard

L'app Codex envoie ses requêtes avec des noms de modèles OpenAI (ex: `gpt-5.5`, `gpt-5-codex`). Le proxy LiteLLM utilise un **catch-all wildcard `"*"`** qui intercepte **n'importe quel** nom de modèle et le redirige vers le backend choisi dans le menu.

Ainsi, peu importe ce que l'app affiche comme modèle - c'est le **menu du lanceur** qui décide quel backend reçoit les requêtes.

### Le fix DeepSeek

L'app Codex envoie parfois des appels d'outils **parallèles** dans un ordre que DeepSeek refuse :

```
function_call → function_call → message(assistant) → function_call_output → function_call_output
                                 ↑ DeepSeek refuse ça ici
```

Le callback `codex_deepseek_fix.py` réordonne automatiquement :

```
function_call → function_call → function_call_output → function_call_output → message(assistant)
                                                                                ↑ déplacé après
```

Ce réordonnancement est inoffensif pour NVIDIA/HF et corrige le problème pour DeepSeek.

### Gestion des serveurs MCP

Les serveurs MCP (Supabase, Playwright, Figma, Render…) sont conservés pour OpenAI/Ollama. Pour DeepSeek, Kimi et Hugging Face, le lanceur conserve le serveur interne `node_repl` et coupe les MCP externes lorsque l'API chat ne peut pas les gérer.

- **Tous les choix** : les serveurs MCP sont conservés dans `config.toml` - c'est l'application Codex qui les gère, pas le LLM distant
- **`mcp-backup.toml`** : sauvegarde manuelle des serveurs MCP externes, filet de secours pour une restauration après màj Codex
- Le serveur interne `node_repl` (utilisé par Codex pour son navigateur intégré) n'est **jamais touché**

> ℹ️ Le lanceur contient encore une fonction `Strip-MCP` (qui coupait les MCP externes pour les API chat type DeepSeek). Elle n'est **plus déclenchée** dans le flux actuel : historiquement les choix DeepSeek/NVIDIA/HF coupaient les MCP, ce n'est plus le cas.

---

## 🔗 Bonus 1 - Piloter Codex gratuit depuis Claude Code (`Claude_Commandes/`)

Le dossier [`Claude_Commandes/`](Claude_Commandes/) ajoute des **slash-commandes dans Claude Code** qui font exécuter la review/tâche par **Codex Home tournant sur un provider gratuit** (DeepSeek/Kimi/Mina via le runtime personnel LiteLLM `:4100`) - **sans utiliser ton compte OpenAI**.

> Pourquoi : `/codex:review` natif n'utilise QUE le reviewer OpenAI (payant). Ces commandes lancent à la place `codex exec` forcé sur le provider gratuit choisi.

| Commande | Rôle |
|----------|------|
| `/cx-free-review [provider] [base-ref]` | Revue de code (équivalent gratuit de `/codex:review`) |
| `/cx-free-critique [provider] [base-ref]` | Revue **adversariale** red-team |
| `/cx-free-task [provider] [--write] <demande>` | Toute demande à l'agent (`--write` = autorise l'écriture de fichiers) |
| `/cx-free-status` | État du proxy LiteLLM personnel (ports 4100/4101) + modèles servis |

**Providers** : `deepseek-flash` (défaut), `deepseek-v4-pro`, `deepseek-v4-flash`, `kimi-k2.6`, `kimi-k2.7-code`, `kimi-k2.7-code-highspeed`, `kimi-k3`, `mina-flash`, `mina-low`, `mina-full`. **Cible review** : sans `base-ref` → travail non commité ; avec `base-ref` (ex. `main`) → branche vs base.

Installation :

```powershell
$env:CODEX_HOME_APP_ROOT = 'G:\Serveurs\Codex-Free-Clone'
pwsh -NoProfile -File "C:\Serveurs\Codex Gratuit\Claude_Commandes\install.ps1" -HomeRoot $env:CODEX_HOME_APP_ROOT
```

L'installeur copie les commandes vers `~/.claude/commands/`, le moteur `cx-free.ps1` vers `~/.claude/scripts/`, et les prompts vers `~/.codex-home/prompts/`. Avec `-ImportAssets`, il importe aussi les plugins, compétences, agents et définitions de connecteurs non sensibles depuis `.codex` et `.claude` vers `.codex-openai`, sans copier les jetons. Détails et dépannage : [Claude_Commandes/README.md](Claude_Commandes/README.md).

> ⚠️ `codex exec` exige `model_reasoning_effort = "xhigh"` dans `~/.codex-home/config.toml` pour les commandes `/cx-free-*` - la valeur `"max"` a été supprimée depuis codex-cli 0.118.0.

---

## 🤖 Bonus 2 - Agents Codex et import des assets

Le script `scripts/import-codex-assets.ps1` importe dans `~/.codex-openai/` les plugins, compétences et agents non sensibles de `~/.codex/` et `~/.claude/`, sans écraser un asset existant ni créer de doublon. Les agents Markdown Claude compatibles sont convertis en TOML Codex lorsque leur nom n'existe pas déjà.

Les définitions MCP sont importées sans headers, tokens ou credentials. Les connecteurs OAuth doivent être reconnectés dans le home cible. Les prompts `cx-free-*` sont installés séparément dans `~/.codex-home/prompts/` et Claude continue d'utiliser `~/.claude/commands/`.

---

## 📁 Structure du projet

```
C:\Serveurs\Codex Gratuit\
├── codex-launch.ps1          # Lanceur principal (menu interactif)
├── mcp-backup.toml           # Sauvegarde des serveurs MCP externes (filet manuel)
├── Codex (menu).lnk          # Raccourci Windows (double-clic pour lancer)
├── .gitignore                # Sécurisation Git (exclut .env, config.yaml, secrets)
├── scripts/import-codex-assets.ps1 # Import idempotent sans credentials
├── config.toml.md            # Doc : structure de ~/.codex/config.toml (sans secrets)
├── ollama-launch-models.json.md  # Doc : structure de ollama-launch-models.json (sans secrets)
│
├── litellm-codex/            # Stack proxy (pont Node 4001 + LiteLLM 4000)
│   ├── start-litellm.ps1     # Démarre la stack : valide .env, lance le pont 4001 puis litellm 4000
│   ├── codex-litellm-proxy.js # Pont Node :4001 → :4000 (fix /v1/models pour Codex)
│   ├── config.yaml           # Config LiteLLM (GÉNÉRÉ AUTO par codex-launch.ps1 - ne pas éditer)
│   ├── codex_deepseek_fix.py # Callback : réordonne les tool_calls pour DeepSeek
│   ├── litellm-models.json   # Catalogue léger exposé à Codex (context_window réels)
│   ├── .env                  # 🔒 Clés API - copie CANONIQUE unique (NE JAMAIS COMMITTER)
│   └── .env.example          # Template sans secrets
│
├── Claude_Commandes/         # Pont Claude Code → Codex gratuit (slash-commandes /cx-free-*)
│   ├── install.ps1           # Installe les commandes + helper + prompts
│   ├── README.md             # Doc technique & dépannage du pont
│   ├── PRESENTATION.md       # Présentation visuelle des /cx-free-*
│   ├── commands/             # Slash-commandes Claude Code (cx-free-review|critique|task|status)
│   ├── scripts/cx-free.ps1   # Le moteur (lance codex exec sur le provider gratuit)
│   └── prompts/              # Bonus : /relire et /relire-critique DANS l'app Codex
│
└── user/.codex/agents/       # 15 sous-agents Codex (*.toml) - équipe de relecture/audit
    └── README.md             # Doc de l'équipe d'agents
```

### Fichiers importants hors projet

| Fichier | Emplacement | Rôle |
|---------|-------------|------|
| `config.toml` | `C:\Users\<user>\.codex\config.toml` | Config principale Codex - modifié par le lanceur |
| `ollama-launch-models.json` | `C:\Users\<user>\.codex\ollama-launch-models.json` | Catalogue des modèles et leurs context_window |

> 📚 **Documentation détaillée** : voir `config.toml.md` et `ollama-launch-models.json.md` dans ce projet.

---

## ⚙️ Configuration

### Clés API (`litellm-codex/.env`)

Copie `.env.example` vers `.env` et remplis tes clés :

```env
# DeepSeek (https://platform.deepseek.com/)
DEEPSEEK_API_KEY=replace-with-your-deepseek-api-key

# Kimi / Moonshot AI (https://platform.kimi.ai/)
MOONSHOT_API_KEY=replace-with-your-moonshot-api-key

# NVIDIA Build (https://build.nvidia.com/) - 1 clé par modèle
NVIDIA_API_KEY_DEEPSEEK=replace-with-your-nvidia-deepseek-key
NVIDIA_API_KEY_GLM=replace-with-your-nvidia-glm-key

# Hugging Face (https://huggingface.co/settings/tokens)
HF_TOKEN=replace-with-your-huggingface-token
```

### Ajouter un nouveau modèle

1. Ajoute ta clé API dans `.env`
2. Dans `codex-launch.ps1`, ajoute une entrée dans le `switch` de `Update-LiteLLMConfig` :

   ```powershell
   'mon-modele' { $wcModel = 'provider/nom-du-modele'; $wcBase = 'https://api.example.com'; $wcKey = 'MA_CLE_API' }
   ```

3. Ajoute le slug correspondant dans `litellm-models.json`
4. Ajoute une option dans le menu et le `switch` final

### Serveurs MCP personnalisés

Pour ajouter tes propres serveurs MCP, édite `~\.codex\config.toml` :

```toml
[mcp_servers.mon_serveur]
url = "https://mon-serveur-mcp.com/mcp"
```

Une sauvegarde est automatiquement créée dans `mcp-backup.toml`. En cas de perte après une màj Codex, restaure depuis ce backup.

---

## 🔄 Restauration après mise à jour de Codex

Une mise à jour de l'application Codex peut **écraser** `config.toml` et `ollama-launch-models.json`. Voici quoi vérifier/restaurer :

### 1. Contexte des modèles (le plus critique)

Si le contexte retombe à **65 536 tokens** au lieu de 1M/256k :

- Vérifie `C:\Users\<user>\.codex\ollama-launch-models.json`
- Les slugs `deepseek-flash`, `deepseek-v4-pro`, `kimi-k2.6`, `kimi-k3`, `nvidia-deepseek`, `nvidia-glm`, `hf` doivent exister avec le bon `context_window` (1M / 1M / 256k / 1M / 1M / 200k / 256k)
- Référence : [ollama-launch-models.json.md](ollama-launch-models.json.md)

### 2. Fournisseur LiteLLM

Vérifie que `C:\Users\<user>\.codex-openai\config.toml` (home GRATUIT) contient :

```toml
[model_providers.litellm]
name = "LiteLLM"
base_url = "http://127.0.0.1:4001/v1/"
wire_api = "responses"
env_key = "LITELLM_KEY"
model_catalog_json = 'C:\Serveurs\Codex Gratuit\litellm-codex\litellm-models.json'
```

> ⚠️ `base_url` pointe sur **4001** (le pont Node), pas 4000 (LiteLLM) - sans le pont, l'app
> reçoit `{"data":[...]}` sur `/v1/models` et ignore les modèles. Le lanceur réécrit
> `model_catalog_json` (chaîne littérale TOML à quotes **simples** - des quotes doubles sans
> `\\` échappés rendraient le TOML invalide et Codex ne verrait plus le provider).

### 3. Modèle actif (écrit par le lanceur)

Le lanceur **n'utilise pas de profils** : la fonction `Set-Default` réécrit directement le modèle et le fournisseur **en tête** de `config.toml` (avant la première section `[...]`), à chaque lancement selon le menu :

```toml
model = "deepseek-flash"     # ← réécrit à chaque lancement
model_provider = "litellm"
```

Les noms de modèles valides (qui doivent matcher le `model_list` de `config.yaml` et les slugs de `litellm-models.json`) :

| Choix menu | `model` écrit | `model_provider` |
|------------|---------------|------------------|
| 1 | `deepseek-flash` | `litellm` |
| 2 | `deepseek-v4-pro` | `litellm` |
| 3 | `kimi-k2.6` | `litellm` |
| 4 | `kimi-k3` | `litellm` |
| 5 | `nvidia-deepseek` | `litellm` |
| 6 | `nvidia-glm` | `litellm` |
| 7 | `hf` | `litellm` |
| 8 | `gpt-5.5` | `openai` |
| 9 | `minimax-m3:cloud` | `ollama-launch-codex-app` |

### 4. Serveurs MCP

Si tes serveurs MCP ont disparu, restaure-les depuis `mcp-backup.toml` :

```powershell
# Copie les sections [mcp_servers.*] de mcp-backup.toml vers config.toml
```

### 5. Sandbox

Vérifie `sandbox_mode = "danger-full-access"` (nécessaire pour que Codex puisse exécuter des commandes shell).

Référence complète : [config.toml.md](config.toml.md)

---

## 🔧 Dépannage

### Le proxy ne démarre pas

```powershell
# Vérifie que litellm est installé
litellm --version

# Vérifie que les ports 4000 (LiteLLM) et 4001 (pont Node) écoutent
Get-NetTCPConnection -LocalPort 4000,4001 -State Listen -ErrorAction SilentlyContinue

# Lance manuellement pour voir les erreurs
pwsh -File "C:\Serveurs\Codex Gratuit\litellm-codex\start-litellm.ps1"
```

> `start-litellm.ps1` refuse de démarrer si une clé référencée par `config.yaml` est absente
> de `.env` (message `[!] cles manquantes ou vides`) - remplis la clé et relance.
> ⚠️ Toujours lancer via **pwsh 7** (les raccourcis le font) - jamais `powershell.exe` 5.1,
> qui écrirait un BOM UTF-8 dans `config.toml` à la prochaine réécriture.

### L'app Codex ne répond pas avec DeepSeek

- Vérifie ta clé API DeepSeek dans `.env`
- Vérifie que le proxy tourne : ouvre `http://localhost:4000/health` dans un navigateur
- Regarde la fenêtre minimisée du proxy pour les erreurs

### Mes serveurs MCP ont disparu

Si après une màj Codex tes serveurs MCP ne sont plus dans `config.toml`, restaure-les depuis `mcp-backup.toml` :

```powershell
# Copie manuellement les sections [mcp_servers.*] de mcp-backup.toml vers config.toml
```

### Le callback DeepSeek fix ne se charge pas

Le proxy doit démarrer avec le bon répertoire de travail. Si tu vois `ModuleNotFoundError: No module named 'codex_deepseek_fix'` dans la fenêtre du proxy, vérifie que :

- `start-litellm.ps1` contient `Set-Location -Path $dir` avant `litellm`
- `codex-launch.ps1` utilise `-WorkingDirectory` dans `Start-Process`

### `codex exec` refuse la config : `unknown variant 'max'`

Depuis **codex-cli 0.118.0**, la valeur `model_reasoning_effort = "max"` n'existe plus. Si `codex exec` (utilisé par les commandes `/cx-free-*`) refuse de charger la config, remplace dans `~/.codex/config.toml` :

```toml
model_reasoning_effort = "xhigh"   # et non "max"
```

---

## 🔒 Sécurité

- Le fichier `.env` contient tes clés API - il est exclu de Git via `.gitignore`
- **Copie canonique unique** : `C:\Serveurs\Codex Gratuit\litellm-codex\.env`. Les copies des
  anciens dossiers (`Codex Free`, `Codex_Gratuit-codex-evaluer-le-projet`) ont été supprimées
  le 2026-07-02 ; leurs raccourcis pointent désormais sur ce repo.
- Audit historique git (2026-07-02) : scan des 3 repos (`sk-…`, `nvapi-…`, `hf_…`) - aucun
  `.env` réel jamais commité, placeholders uniquement. Aucune purge nécessaire.
- La stack tourne en **local uniquement** (`127.0.0.1:4000` + `127.0.0.1:4001`) - pas accessible depuis l'extérieur
- La `master_key` du proxy (`sk-codex-local`) est uniquement pour l'accès local

> **Ne committe jamais `.env`** - utilise `.env.example` comme template pour les autres utilisateurs.

---

## 📜 Licence

Projet personnel. L'application OpenAI Codex appartient à OpenAI. Ce projet ne modifie pas l'application - il redirige ses requêtes API via un proxy local.
