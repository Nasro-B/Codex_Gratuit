# Codex Home Model Picker Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow Codex Home to expose Kimi, DeepSeek and Mina in the Codex model picker and switch between them without restarting the application or changing the original `.codex` home.

**Architecture:** Keep the GitHub Codex Gratuit project on its existing `.codex-openai` home and 4000/4001 runtime. Give the personal Codex Home Windows app its own runtime under `G:\Serveurs\Codex-Free-Clone`, its own `.codex-home` home, its own provider `.env`, and ports 4100/4101. Route every supported model through explicit static LiteLLM entries, use the personal catalogue for the Codex picker, and make Claude headless commands target only the personal Codex Home runtime.

**Tech Stack:** PowerShell 7, LiteLLM, Node.js bridge, TOML Codex configuration, JSON model catalogue, Windows AppX clone launcher.

**Spec:** User request in the active conversation: choose Kimi, DeepSeek and Mina directly from the Codex model selector without restarting, while keeping the original Codex application and `.codex` isolated.

## Global Constraints

- Never modify `C:\Users\Nasro\.codex` or the original Codex application.
- Keep Codex Gratuit state in `C:\Users\Nasro\.codex-openai` and its existing 4000/4001 runtime.
- Keep Codex Home state in `C:\Users\Nasro\.codex-home` and its personal G: runtime on 4100/4101.
- Keep provider secrets in separate `.env` files for the two runtimes; never add secrets to source, docs, tests or commits.
- Keep the ten requested models and their current context-window values.
- Preserve headless `/cx-free-*` model selection and read-only defaults.
- Do not launch the original Codex application during verification.

---

### Task 1: Define the picker routing contract

**Files:**
- Modify: `codex-home-proxy.ps1`
- Modify: `codex-home.ps1`
- Modify: `G:/Serveurs/Codex-Free-Clone/codex-home.ps1`
- Create: `G:/Serveurs/Codex-Free-Clone/runtime/`

**Interfaces:**
- The personal GUI launcher starts with `deepseek-flash` as a default model when no model argument is supplied.
- The proxy keeps explicit routes for all ten models and uses only a fallback wildcard for unknown requests.
- Passing `-Model` remains supported for deterministic headless tests and Claude commands.
- Codex Gratuit never reads the personal runtime files or `.codex-home`.

- [x] Update proxy parameters so GUI startup does not require a provider-specific menu choice.
- [x] Keep explicit model routes for all Kimi, DeepSeek and Mina slugs.
- [x] Make the C: launcher use the safe default without prompting when `-Model` is omitted.
- [x] Forward the same default behavior from the G: launcher.
- [x] Move the personal proxy, bridge, catalogue and provider environment to the G: runtime.
- [x] Make the C: compatibility wrappers resolve only through `CODEX_HOME_APP_ROOT`.

### Task 2: Align the Codex catalogue and documentation

**Files:**
- Modify: `litellm-codex/litellm-models.json` only if validation finds a mismatch.
- Modify: `README.md`
- Modify: `Claude_Commandes/README.md`
- Modify: `Claude_Commandes/scripts/cx-free.ps1`
- Modify: `Claude_Commandes/install.ps1`

**Interfaces:**
- The catalogue remains the single source for picker labels, slugs and context windows.
- Documentation states that model changes in the picker do not restart the GUI, while adding new models requires one reload.

- [x] Validate the ten target slugs and context windows against the proxy routes.
- [x] Document the model picker behavior and the Mina HTTP 402 prerequisite.
- [x] Keep original `.codex` isolation explicit.
- [x] Document the separate Codex Gratuit and personal Codex Home homes, ports and `.env` files.

### Task 3: Verify configuration and runtime isolation

**Files:**
- No production files.
- Verification uses PowerShell commands and the existing headless helper.

- [x] Parse every modified PowerShell file.
- [x] Validate the model catalogue and proxy model list.
- [x] Confirm `.codex/config.toml` hash is unchanged.
- [x] Confirm `.codex-openai` is not used by Codex Home and `.codex-home` is not used by Codex Gratuit.
- [x] Confirm original Codex processes remain on the OpenAI package path.
- [ ] Start the clone once and confirm it uses the G: layout path. Intentionally not run because the user requested no GUI launch during testing.
- [x] Run health checks for all ten models and report provider-specific HTTP results without exposing secrets.

### Task 4: Review the final diff

**Files:**
- Review all staged and unstaged files in `C:\Serveurs\Codex Gratuit`.

- [x] Confirm no `.env`, key, token or generated personal config is tracked.
- [x] Confirm no unrelated files changed.
- [x] Report commit and push separately after the secret-safe commit and remote verification.

### Task 5: Import non-secret Codex and Claude assets

**Files:**
- Create: `scripts/import-codex-assets.ps1`
- Modify: `Claude_Commandes/install.ps1`
- Local targets: `C:/Users/Nasro/.codex-openai` and `C:/Users/Nasro/.codex-home`

**Interfaces:**
- The importer is idempotent and deduplicates identical skills, agents and plugin files.
- OAuth tokens, API keys, credentials, sessions, histories, caches and telemetry are never copied.
- Connector definitions are imported without inline authentication material and require a fresh login when the connector uses OAuth.
- The `cx-*` prompts remain available in `.codex-home`, while Claude continues to own the slash-command installation.

- [x] Inventory source assets from `.codex` and `.claude` without reading secret values into output.
- [x] Import non-secret plugins, skills and agents into `.codex-openai` without overwriting existing unique content.
- [x] Import safe MCP connector definitions and omit auth-only fields.
- [x] Install the `cx-*` prompt set into `.codex-home` and keep Claude command routing on the personal runtime.
- [x] Run the importer twice and confirm the second run adds no duplicates.
