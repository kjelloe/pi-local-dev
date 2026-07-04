# Design Decisions

## 2026-07-02 — noctrex-qwen3.6:35b as default model

Chose `Qwen3.6-35B-A3B-MTP-MXFP4_MOE.gguf` as the default for the startup script.

Rationale: 32/33 benchmark tasks at 121 tok/s on 4090+3090. Best overall score in the 2x24gb
suite. f16 KV avoids precision-boundary failures (e.g. python_hashmap). MXFP4 format is
supported by both Ampere GPUs in the system.

Alternative considered: `qwen3-coder:30b-1m` (perfect coding 19/19) — preferred when working
on large codebases that benefit from 1M context.

## 2026-07-02 — llama-server over Ollama

llama-server chosen as the inference backend (not Ollama) because:
- Direct control over quantization, KV type, batch size, tensor_split
- Benchmark harness (llm-test-bench) already uses llama-server
- Avoids Ollama model format conversion overhead
- Ollama pulls remain available for quick experiments (`ollama run ...`)

## 2026-07-02 — Pi as primary coding CLI

`@earendil-works/pi-coding-agent` chosen over Aider as primary because:
- Supports custom OpenAI-compatible providers (llama-server at port 8080)
- AGENTS.md convention: Pi auto-loads from cwd and all ancestors
- Agent Skills standard for slash commands matches our skills/ layout
- Built-in tool set (bash/read/edit/write/grep/find/ls) identical to Claude Code — skills
  and workflows are portable between local and cloud agents
- Aider kept as optional second opinion

## 2026-07-02 — 65536 default context window

65536 chosen as the startup script default. Rationale:
- Fits comfortably in 48 GB for all supported models
- Sufficient for typical coding tasks and multi-file edits
- Override with `CTX=131072` for long-context tasks (qwen3-coder:30b-1m handles 1M)

## 2026-07-04 — dev.sh single-command launcher

`scripts/dev.sh` added as the primary entry point. Rationale:
- Eliminates the two-step workflow (start server, then start Pi) that caused "server not ready" errors
- Polls `/health` for up to 90 s — covers slow mlock load of large MXFP4 models
- `localai` alias makes it reachable from any directory without `cd`
- Server stays running between Pi sessions if relaunched; dev.sh detects this and skips startup

## 2026-07-04 — Agent Skills over raw prompts/ for Pi integration

Skills in `skills/<name>/SKILL.md` chosen over pointing Pi at `prompts/`:
- Agent Skills standard (agentskills.io) is the canonical format Pi uses
- SKILL.md frontmatter (`name`, `description`) gives Pi the XML skill listing in its system prompt
- Model invokes `/skill:name` or Pi invokes via read — both paths work
- `prompts/` kept as human-readable references; skills/ is the machine-invocable layer
- No duplication in practice: skills/ content is the authoritative workflow; prompts/ can diverge

## 2026-07-04 — Project-level .pi/settings.json for default model

`.pi/settings.json` added at repo root to set `defaultProvider` and `defaultModel`. Rationale:
- Eliminates `--model llama-local/local` flag every session
- Project settings override global — different repos can target different providers
- `skills` array in project settings keeps the skills/ path self-contained to the repo
