# Design Decisions

## 2026-08-17 — localai-reasoning preset + auto-syncing models.json (closes the profile-drift class of bug)

The 2026-08-16 `node_paratrooper` fix (qwen3.8:27b, single GPU, `CTX=131072`,
`--reasoning-budget 20000`, matching `models.json` values) was applied by hand via one-off
`nohup start-llama.sh ...` invocations — never made a persisted default. Bit twice as a result:
re-running "the same prompt" a day later via plain `localai` silently started the *default*
`qwopus3.6:35b` config (no `--reasoning on`, no budget, `CTX=65536`) — a model never confirmed
capable of this task at all — and failed the same way (`maximum output token limit`) for an
entirely different reason (no cap on unbounded reasoning) than the original bug it looked
identical to.

Fixed two ways:
- **`scripts/dev-reasoning.sh`** (`localai-reasoning` alias): named preset mirroring `dev.sh`,
  hardcoding the confirmed `node_paratrooper`-passing config. Unlike `dev.sh`, it *always* stops
  and restarts the server rather than reusing whatever's running — switching to this profile is a
  deliberate, infrequent action, so correctness beats the reload cost.
- **`scripts/set-model-profile.py`**: syncs `~/.pi/agent/models.json`'s `contextWindow`/`maxTokens`
  to a named profile (`coder` or `reasoning`). `dev-reasoning.sh` calls it with the explicit
  profile right after starting its server. `dev.sh` calls it with `auto`, which queries the
  *running* server's `/props` for the loaded GGUF filename and picks the matching profile —
  critically, this means a plain `localai` run no longer blindly assumes "coder": if a
  `localai-reasoning` server is still up when someone runs plain `localai` elsewhere, `auto`
  correctly detects and keeps the reasoning profile instead of silently shrinking `maxTokens`
  back down and reintroducing the exact truncation bug this whole arc was about fixing.

Verified 2026-08-17, all three directions: `localai-reasoning` → syncs to reasoning profile and
matches `/props`; plain `localai` while the reasoning server is still up → `auto` correctly
detects and preserves the reasoning profile (does NOT force coder); plain `localai` from cold →
starts the default `qwopus3.6:35b` and syncs to the coder profile. `models.json` can no longer
drift out of sync with whatever `llama-server` is actually running through either launch path.

## 2026-08-17 — node_paratrooper (L6-full) confirmed passing through Pi, not just the raw harness

Closing out the debugging arc from 2026-08-16: `qwen3.8:27b` implemented `Game` in
`/tmp/mytestdir3/src/game.js` via an ordinary Pi session (`localai` from the task directory,
natural-language prompt pointing at `TASK.md`) and passed all 40 tests. Verified independently —
not trusting Pi's self-reported summary: `tests/game.test.js` and `package.json` confirmed
byte-identical to the pristine originals, `node --test tests/game.test.js` re-run directly showed
40/40 pass, and the implementation itself (seeded `mulberry32` RNG, `DEFAULTS`-merged config,
full entity-state fields) is a genuine solution, not a degenerate one.

This is the first confirmed pass of this task through localdev's actual agentic Pi workflow —
llm-test-bench's confirmed pass was the harness's raw single-shot `BEGIN_FILE`/`END_FILE`
completion, a meaningfully different prompt shape (see the 2026-08-16 CTX=131072 decision above).
Getting here required stacking every fix from that session:
- `--temp 0 --seed 1` (Pi sends no sampling params at all — server default was governing, and
  wasn't deterministic before this)
- `--reasoning-budget 20000` (hard cap on the thinking phase — this model's reasoning was
  otherwise open-ended and exceeded even a 32768-token `maxTokens` ceiling)
- `maxTokens: 49152` / `contextWindow: 131072` in `~/.pi/agent/models.json` (must match the
  server's actual `--ctx-size`, or Pi may compact context prematurely against a stale number)
- `CTX=131072`, single GPU (`CUDA_VISIBLE_DEVICES=0 --tensor-split 1`), f16 KV, `--reasoning on`

Reference config for reproducing this specific task again:
```bash
CUDA_VISIBLE_DEVICES=0 MODEL=Qwen3.8-27B-Q4_K_M.gguf CTX=131072 ./scripts/start-llama.sh \
  --reasoning on --tensor-split 1 --reasoning-budget 20000 \
  --reasoning-budget-message "I have thought enough, time to answer."
```
`~/.pi/agent/models.json` needs `contextWindow: 131072, maxTokens: 49152` while this config is
active — remember to revert both when switching back to the default `qwopus3.6:35b` config
(`contextWindow: 65536`), per the drift gotcha in `memory/gotchas.md`.

## 2026-08-16 — start-llama.sh pins --temp 0 --seed 1 (deterministic sampling)

Added `--temp 0 --seed 1` to `start-llama.sh`'s hardcoded flags.

Discovered while debugging a Pi session that hit the output-token ceiling on `node_paratrooper`
(L6-full, qwen3.8:27b): Pi's client does not send a `temperature` parameter in its completion
requests at all (confirmed by grepping the installed Pi package's `dist/core` — no `temperature`
reference in the actual agent completion path, only in an unrelated proxy module). `start-llama.sh`
never overrode llama-server's own default either. Checked `llama-server --help`: default
`--temp` is 0.80, default `--seed` is -1 (random). So every Pi session against this server had
actually been running with real sampling temperature and a random seed — not the `temp=0, seed=1`
that llm-test-bench's harness uses (`~/GIT/llm-test-bench/CLAUDE.md`: "Default temperature=0 and
seed=1") and that the confirmed `node_paratrooper` pass specifically depended on.

This matters more than it might for a typical assistant: `memory/gotchas.md`'s config-sensitivity
notes on this exact task show the model's correctness is knife-edge sensitive to numeric
differences even *at* temp=0 (cross-GPU floating-point reduction order alone flips the outcome).
Running with real sampling on top of that is strictly worse — outcomes become non-reproducible
run to run, on the single hardest task in the whole benchmark suite.

Verified via `/props` after restart: `"seed": 1, "temperature": 0.0`. Chose to pin this at the
server level (affects every model, every session) rather than special-case it for one task,
because `temp=0/seed=1` is already this project's own general convention for a correctness-focused
coding assistant (matches llm-test-bench's harness default, and this repo's own AGENTS.md
preference for deterministic, non-creative output) — not a narrow reproduction hack.

Caveat: llama-server takes the client's value over the server default if a request ever does
specify `temperature`/`seed`. If a future Pi version starts sending its own sampling params, this
server-level pin will silently stop applying — worth re-checking `/props` after any Pi upgrade.

## 2026-08-16 — qwen3.8:27b session runs at CTX=131072, not the benchmark's confirmed ctx=8192

While setting up the `node_paratrooper` test in `/tmp/localtest1`, initially matched
llm-test-bench's exact confirmed-pass config as closely as possible. Deliberately diverged on one
axis: context window. The confirmed pass used the harness's bare `ctx=8192` default (sufficient
because the actual generation was ~4700 tokens — well under even the harness's own generous
`--num-predict 24000` ceiling for that task group). Pi's prompt is not the harness's bare
single-shot `BEGIN_FILE`/`END_FILE` completion — it carries a system prompt, tool schemas,
`AGENTS.md`, skill content, and multi-turn history, all of which the raw benchmark prompt doesn't.
The session hit Pi's *old* 16384-token output ceiling before finishing a turn, which is direct
evidence the Pi-mediated prompt+reasoning needs more headroom than the harness's minimal one, not
less. Kept `CTX=131072` (architecture headroom for this model on a single GPU, not a KV limit —
see `memory/models.md`) rather than reverting to 8192, since 8192 would likely fail *harder*
(context overflow) given what was already observed. Also raised `~/.pi/agent/models.json`'s
`maxTokens` 16384 → 32768 for the same reason — see the gotcha entry on this.

Net: this is not an attempt at byte-identical reproduction of llm-test-bench's specific
deterministic run (impossible anyway — genuinely different prompt structure). It's matching the
axes that generalize (f16 KV, `--reasoning on`, single GPU, and now `temp=0`/`seed=1`) while
giving the agentic setting the extra headroom its different prompt shape actually needs.

## 2026-08-16 — hwmonitor.py thermal watchdog: pause (not abort) on CRIT

Added `scripts/hwmonitor.py`, auto-launched in the background by `start-llama.sh` for every
server it starts (skip with `HWMONITOR=0`). Adapted from `~/GIT/llm-test-bench/hwmonitor/`, which
polls GPU/CPU/RAM via `nvidia-smi` and `/proc` and aborts `bench.py` on a CRIT threshold breach.

Rationale for diverging from llm-test-bench's abort-and-restart pattern: `bench.py` runs are
resumable batch jobs — killing one on CRIT and restarting is cheap. A localdev `llama-server`
instance backs a live, interactive Pi coding session; killing it mid-task drops whatever Pi is
waiting on and forces a 30-90s reload plus re-prompting. Instead, on CRIT, `hwmonitor.py` sends
`SIGSTOP` to `llama-server` (freezes it in place — no new GPU work queues) and automatically sends
`SIGCONT` once temps recover below the WARN threshold. Pi's in-flight HTTP request simply hangs
until resumed rather than erroring out.

Implementation notes:
- Targets the server via the `/tmp/llama-server-<port>.pid` pidfile from the 2026-08-16 VRAM-release
  work, with the same `pgrep` fallback for servers started before pidfiles existed.
- `stop-llama.sh` now also stops hwmonitor and sends the paused server a `SIGCONT` before its own
  shutdown signal, in case hwmonitor left it paused.
- **Found and fixed during testing**: hwmonitor.py's resume-on-exit only fired on
  `KeyboardInterrupt` (Ctrl+C). Killing it via plain `kill` (default `SIGTERM` — exactly what
  `stop-llama.sh` does) bypassed that path entirely, which would leave `llama-server` stuck in
  `SIGSTOP` forever with nothing left running to un-stick it. Fixed by registering a `SIGTERM`
  handler that raises the same cleanup exception as `KeyboardInterrupt`. Verified with a dummy
  process: forced CRIT → confirmed `ps` state `T` (stopped) → sent `SIGTERM` to hwmonitor →
  confirmed `SIGCONT` fired and state returned to `S` before hwmonitor exited.
- No automatic "slow down" (e.g. `nvidia-smi -pl` power-limit reduction) — that needs root and
  is a more invasive, harder-to-reverse action than pause/resume for a one-user local box. Left as
  a manual mitigation if pause/resume alone isn't enough in practice.
- Deliberately does **not** implement per-model or per-task auto-tuning of thresholds; defaults
  match llm-test-bench's (85°C/95°C core, 90°C/100°C junction, 98% power, 90% RAM) since this is
  the same hardware.

## 2026-08-16 — stop-llama.sh + localai-stop for explicit VRAM release

Added `scripts/stop-llama.sh` (aliased `localai-stop`) to stop `llama-server` and free its VRAM
on demand, plus a PID-file mechanism in `start-llama.sh` to support it: right before `exec`ing
into the `llama-server` binary, it writes its own PID (`$$`, which survives `exec` since exec
replaces the process image, not the PID) to `/tmp/llama-server-<port>.pid`.

Rationale: the 2026-07-04 decision to leave the server running between Pi sessions (avoids 30-90s
reload) is still correct as a default, but means VRAM (72 GB across 3 GPUs) stays pinned
indefinitely with no way to give it back short of manually finding and killing the process. This
adds an explicit, opt-in release step for "done coding for a while, need the GPUs" — not an
automatic stop-on-Pi-exit, which would undo the whole point of staying warm.

Design choices:
- **PID file over blind `pkill -f llama-server`**: a name/pattern match could kill an unrelated
  process (e.g. a benchmark run from `llm-test-bench` on a different port) sharing the machine.
  The stop script also double-checks `/proc/<pid>/comm` before signaling, in case the pidfile is
  stale (process died, PID reused by something else).
- **Fallback via `lsof -ti:<port>`**: covers servers started before this feature existed, or
  started manually (`nohup ./scripts/start-llama.sh &` outside `dev.sh`) — confirmed working
  2026-08-16 by stopping a server that predated the pidfile change.
- **PID file lives in `start-llama.sh`, not `dev.sh`**: makes it correct regardless of how the
  server was launched (via `dev.sh`'s background job, directly, or via `nohup`), since
  `start-llama.sh` always knows its own final PID via `$$`.

Verified 2026-08-16: pidfile PID matched the live `llama-server` PID exactly after a fresh
`localai` start; `localai-stop` released VRAM on both the pidfile path and the fallback path
(GPU1/GPU2 dropped to 0 MiB used after stop).

## 2026-08-16 — dev.sh launches Pi against the caller's cwd, not localdev's

Changed `scripts/dev.sh`'s final line from `cd "$REPO_DIR"; exec pi "$@"` to
`exec pi --provider llama-local --model local --skill "$REPO_DIR/skills" "$@"` (no `cd`).

Rationale: the intended use of this repo is as a launcher for *other* project directories
(`~/GIT/some-web-project`, `~/GIT/some-game`), not only for editing localdev itself. The old
`cd "$REPO_DIR"` forced Pi to operate on localdev regardless of where `localai` was invoked from,
and relying on `.pi/settings.json` for the local-model default meant a bare `pi` run from any
other directory silently fell back to Pi's global default provider (`google`) instead of the local
model. `llama-local` is already a global provider (defined in `~/.pi/agent/models.json`, not
project-scoped), so passing it explicitly on the command line works from any cwd without needing
per-project `.pi/settings.json` files.

Verified 2026-08-16: ran `dev.sh` from a scratch directory outside localdev — Pi correctly reported
`pwd` as the scratch directory (not localdev), read a file placed there, used the local model with
no explicit `--provider`/`--model` flags needed, and localdev's skills (`add-feature`, `fix-bug`,
etc.) were available via `/skill:name`.

Trade-off: `.pi/settings.json` in this repo is now effectively unused by the `localai`/`dev.sh`
path (it still applies if someone runs bare `pi` from inside `localdev` directly). Left in place
rather than removed — it's not harmful, and documents the intended defaults for that case.

## 2026-08-16 — 3rd GPU added: Architect/Reviewer pick changes to gpt-oss:120b

Hardware change: the workstation now has 3 GPUs (RTX 4090 + RTX 3090 + RTX 3090, 72 GB total,
confirmed via `nvidia-smi`), up from 2 (48 GB). `scripts/start-llama.sh` and docs updated:
`--tensor-split 1,1` → `1,1,1`.

Coder default (qwopus3.6:35b) is unchanged — it only needs ~20 GB and shows no throughput or
quality benefit from a 3rd GPU (see llm-test-bench's 3×24 GB notes: "all other models below 45 GB
run identically to 2×24 GB — the 3rd GPU adds no quality benefit for sub-25 GB models"). It's
still the fastest confirmed perfect coder (161 tok/s, 19/19) and the highest-frequency skills
(`add-feature`, `fix-bug`) prioritize speed.

Architect/Reviewer pick changes from qwen3.5:27b (28 tok/s, 2×24 GB) to gpt-oss:120b (56 tok/s,
3×24 GB) — this is not a portability projection, it's the newly available real tier for this
system. gpt-oss:120b is 19/19 coding + 4/4 web + full L6-stepped chain, and is actually *faster*
than the old pick despite being ~4× larger, because the 3rd GPU makes it fully GPU-resident
(single-GPU fallback needs `--n-cpu-moe 35` and drops to ~17 tok/s). qwen3.5:27b stays documented
in `memory/models.md` as a lighter/faster fallback if `CUDA_VISIBLE_DEVICES` restricts the system
to 2 GPUs.

Data reused from `~/GIT/llm-test-bench/CLAUDE.md` and
`~/GIT/llm-test-bench/reports/models-status-August-2026.md`'s 3×24 GB tier — not re-derived here.

## 2026-08-16 — qwopus3.6:35b replaces noctrex-qwen3.6:35b as default model

Changed the default in `scripts/start-llama.sh` from `Qwen3.6-35B-A3B-MTP-MXFP4_MOE.gguf`
(noctrex-qwen3.6:35b) to `Qwopus3.6-35B-A3B-Coder-MXFP4_MOE_Q8_0-Imatrix.gguf` (qwopus3.6:35b).

Rationale: llm-test-bench's August 2026 benchmark refresh shows qwopus3.6:35b strictly ahead of
the prior default on this hardware's actual tier (2×24 GB) — 19/19 coding vs 17/19 (noctrex
regressed on `csv_nordic_property` after a llama-server binary update — see llm-test-bench's
`CLAUDE.md` "Binary Regression Note"), and faster (161 vs 121 tok/s). Same architecture class
(MXFP4 A3B MoE, Ampere+ required, `tensor_split=1|1`) — no operational changes beyond the model
file and container flags.

This system's primary use is Pi as a coding CLI (`add-feature`, `fix-bug` — the highest-frequency
skills), so the default now optimizes for that case specifically, following this decision's own
original heuristic ("best overall score") applied to the current data.

Trade-off accepted: qwopus3.6:35b fails `python_fastapi_endpoint` (web task, whitespace-validation
gap specific to coder fine-tunes) and, like nearly every model benchmarked except qwen3.8:27b,
fails the from-scratch `node_paratrooper` (L6-full) task entirely. Neither is relevant to this
repo (no FastAPI code, no from-scratch game logic), so the trade-off is a clean win here.

For deep-reasoning tasks (`review`, `implement-spec`), switch explicitly to qwen3.5:27b — it's the
only model confirmed at full Skill L6 on this hardware (passes fastapi, passes multi-entity
state-tracking that qwopus doesn't need to). See `memory/models.md` for both role picks across all
VRAM tiers this system might run on. Revert: change `MODEL=` in `scripts/start-llama.sh` back to
`Qwen3.6-35B-A3B-MTP-MXFP4_MOE.gguf` if the fastapi/state-tracking gap ever matters here.

## 2026-07-02 — noctrex-qwen3.6:35b as default model (superseded 2026-08-16, see above)

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
