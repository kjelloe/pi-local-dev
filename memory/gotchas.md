# Known Gotchas

## llama-server

**flash-attn requires explicit value in newer builds**
`--flash-attn on` (not bare `--flash-attn`). The bench client handles this via `_BOOL_EMIT_VALUE`.

**tensor_split uses commas in CLI, pipes in model config files**
Model files (2x24gb.txt) use `tensor_split=1|1`; the CLI flag is `--tensor-split 1,1`.

**llama-server silently caps ctx below requested value**
Qwen2.5-Coder models cap at 32768 on 48 GB despite KV math predicting they should fit.
Symptom: server reports a lower `max_ctx` than you requested. Use `max_ctx=32768` to get
`SKIPPED_CTX` instead of `CTX_TRUNCATED` on oversized requests.

**Pi doesn't send `temperature` — llama-server's default (0.80, random seed) governs unless pinned**
Confirmed by grepping the installed Pi package's `dist/core`: no `temperature` param in the actual
agent completion path. `start-llama.sh` now pins `--temp 0 --seed 1` (2026-08-16) so Pi sessions
get deterministic output matching llm-test-bench's harness convention — before this fix, every Pi
session was unknowingly running at real sampling temperature. Verify with `curl
127.0.0.1:8080/props | python3 -m json.tool | grep -i "temp\|seed"`. If a client request ever does
specify `temperature`, it wins over this server default — re-check `/props` after any Pi upgrade.

**MTP models and speculative decoding**
noctrex-qwen3.6:35b is an MTP (Multi-Token Prediction) model. Do NOT pass spec-decoding flags
(`--draft-model`, etc.) — MTP breaks temp=0 determinism when used for spec decoding.

**no_mmap is required for large MoE models**
Without `--no-mmap`, large MXFP4 MoE models can take very long to load and may cause
page-fault latency spikes during inference.

**Large MXFP4 models take 30-90 s to load**
dev.sh polls for up to 90 s. If the server hasn't responded by then, check `/tmp/llama-server.log`.
The most common cause is VRAM not freeing from a previous process — run `nvidia-smi` to confirm.

**hwmonitor.py pauses (not kills) llama-server on thermal CRIT**
`start-llama.sh` auto-launches `scripts/hwmonitor.py` in the background (`HWMONITOR=0` to skip).
On a CRIT breach (default 95°C core / 100°C junction / 98% power) it sends `SIGSTOP` to
`llama-server`, not a kill — any in-flight Pi request just hangs until temps recover below WARN
and it auto-resumes with `SIGCONT`. `localai-temps` tails the log; `localai-stop` stops hwmonitor
and force-resumes the server first in case it was left paused. If a server ever seems stuck
(hung request, no response, but `curl /health` also hangs) check `ps -o stat= -p <pid>` — state
`T` means it's paused; `nvidia-smi` running hot at the same time confirms it was hwmonitor, not a
crash. Registering a `SIGTERM` handler (not just `KeyboardInterrupt`) for the resume-on-exit path
was required — see `memory/decisions.md` (2026-08-16) for why plain `kill` would otherwise leave
a paused server stuck forever.

**Server stays running between sessions — use `localai-stop` to release VRAM**
`dev.sh` reuses an already-running server rather than restarting it (avoids the 30-90s reload).
This means VRAM stays pinned after you close Pi unless you explicitly release it. Run
`localai-stop` (`scripts/stop-llama.sh`) when you're done coding for a while. It's PID-file based
(`/tmp/llama-server-<port>.pid`, written by `start-llama.sh` via `$$` right before `exec`) with a
`lsof -ti:<port>` fallback for servers started before this existed or started manually. If you
ever see a stale `/tmp/llama-server-8080.pid` pointing at a dead or reused PID, it's safe to
delete — `stop-llama.sh` already detects and ignores this case via `/proc/<pid>/comm`.

## Pi

**Developer role not supported by llama-server**
Set `"supportsDeveloperRole": false` in `~/.pi/agent/models.json`. Pi sends system prompts as
`developer` role by default; llama-server only understands `system`.

**`maxTokens` in models.json caps output per response, not context — too small truncates mid-reasoning**
`~/.pi/agent/models.json`'s `maxTokens` (was 16384, raised to 32768 on 2026-08-16) is the API
`max_tokens` sent per completion, independent of `contextWindow`. Reasoning models (qwen3.8:27b,
qwen3.5:27b, gpt-oss:120b, etc.) can easily exceed a small budget on complex tasks — llm-test-bench's
own notes cite 8000-24000+ tokens needed for thinking models on L3+ tasks, and node_paratrooper
(L6-full) is the hardest task in the suite. Symptom: Pi reports "Model stopped because it reached
the maximum output token limit," often mid-`<think>` trace (visible as raw reasoning text like
"Wait, let me actually redo that..." in the response). Fix is `maxTokens`, not `CTX`/`contextWindow`
— confirm which one was actually hit before assuming it's a context-size problem. Also bump `CTX`
(server context window) if using a large `maxTokens` on a long multi-turn session, so prompt +
accumulated history + max output all still fit — qwen3.8:27b supports 131072 on a single GPU
(architecture headroom, not a KV limit — see `memory/models.md`).

**ReasoningEffort not supported**
Set `"supportsReasoningEffort": false`. Local models do not implement the reasoning effort API.

**Pi needs llama-server running before launch**
Pi connects on startup; if the server isn't ready it will fail immediately. Use `dev.sh` (or
`localai`) rather than launching Pi directly — it waits for the health endpoint before exec.

**Skills directory must be in .pi/settings.json**
Pi only scans for skills in directories explicitly listed under `"skills"` in settings.json.
The repo's `.pi/settings.json` already sets `"skills": ["./skills"]`. If you add a new skills
directory, add it to that array.

**SKILL.md description field is required**
A skill with no `description:` in its frontmatter is silently skipped — it will not appear in
the system prompt or as a `/skill:name` command. Always include a non-empty description.

**Pi project settings only apply when run from inside the repo**
`.pi/settings.json` is loaded relative to cwd, so it only takes effect when running a bare `pi`
command from inside `localdev` itself. `scripts/dev.sh` (and the `localai` alias) no longer
depend on this — since 2026-08-16 it passes `--provider llama-local --model local --skill
$REPO_DIR/skills` explicitly and does not `cd` into the repo, so `localai` works correctly from
any project directory. `.pi/settings.json` still matters if you run bare `pi` from inside
`localdev` without going through `dev.sh`.

**`~/.pi/agent/models.json` model `name` is a display label only — it drifts silently**
It does not select which GGUF loads (that's `MODEL=` / `scripts/start-llama.sh`'s default), so it
can go stale whenever the default model changes and nothing will fail or warn. Found stale
2026-08-16 (still said `noctrex-qwen3.6:35b` a month after the default moved to `qwopus3.6:35b`).
Update it by hand whenever the default in `scripts/start-llama.sh` changes.

**No per-call permission gating for Pi's tools**
Unlike Claude Code, Pi has no interactive "approve this specific bash/edit call" prompt. `--tools`
/ `--exclude-tools` (and the `"skills"` config) only allowlist or denylist tool *availability* up
front for the whole session — once a tool is enabled, every invocation of it runs unconfirmed,
including arbitrary `bash` commands. The only mitigation available is scoping which tools a
session or skill can see at all (e.g. `pi --tools read,grep,find,ls` for a read-only session, or
restricting a skill to fewer tools) — there is no built-in equivalent to Claude Code's per-action
approval or hooks. Keep this in mind before pointing Pi at anything with `bash` enabled unattended.

**qwopus3.6:35b (default model) has no re-download path**
The jashepp HuggingFace repo was deleted 2026-07-26. The GGUF in `allmodels/` is the only copy —
back it up before any cleanup of that directory. If it's ever lost, fall back to the prior default
(`Qwen3.6-35B-A3B-MTP-MXFP4_MOE.gguf`, still downloadable) until a replacement coder model is chosen.

## Hardware

**PCIe bandwidth limits 70B tensor-parallel throughput**
None of the 3 GPUs (RTX 4090 + RTX 3090 + RTX 3090) have NVLink. At 70B (Q4_K_S, ~37 GB)
tensor-split across cards, throughput is PCIe-bound (~20 tok/s). 30-35B MoE models with small
active parameter sets are effectively immune to this because inter-GPU traffic is minimal — this
still holds with a 3rd GPU in the mix. Confirmed at the 3-way split too: gpt-oss:120b (MoE, small
active param set) runs `--tensor-split 1,1,1` fully GPU-resident at 56 tok/s (llm-test-bench 3×24
GB tier) — no PCIe-bandwidth-specific 3-way regression noted in that repo's confirmed data.
qwen2.5:72b (dense, 3×24 GB) is the counter-case: 8.7 tok/s, 6× slower than gpt-oss:120b — but
that's a dense-vs-MoE effect (identical to the 70B dense case above), not something new to 3-way
splits specifically.

**qwen3.8:27b `node_paratrooper` (L6-full) — 3-way explicit tensor_split PASSES (confirmed 2026-08-16)**
Confirmed to FAIL under 2-way explicit `--tensor-split 1,1` (reproduced 3×, cross-GPU floating-point
reduction flips an early token choice — see llm-test-bench's L6-full wall notes). Confirmed to PASS
under single-GPU, 3-GPU auto-distribution, and now explicit `--tensor-split 1,1,1` (9.6 tok/s, 474s
— matches the earlier auto-dist result). **Important nuance**: the 3-way output is NOT byte-identical
to the single-GPU output — it's a genuinely different (but still fully correct) implementation.
Cross-GPU divergence happens at any split; whether it lands on broken logic (2-way, reliably) or an
equally-valid alternate implementation (3-way, this one run) appears to be probabilistic per-run, not
a property of split count. This is one confirmed 3-way run, not proof every 3-way run will pass the
way the 2-way FAIL is proven to reliably fail (3 reproductions). If this task ever matters here,
don't treat 3-way tensor_split as guaranteed-safe without re-running.

**RTX 3090 at 333-344W (95-98%) under dense tensor_split is normal**
This is the card running at capacity during dense 27-32B tensor-split. Not a thermal concern
unless the card reports throttling.

**CUDA_VISIBLE_DEVICES for single-GPU MoE**
Small MoE models (MXFP4, ~16-20 GB) that fit on one GPU run faster without tensor_split
because the 4090 (~1008 GB/s) is faster than the 3090 (~936 GB/s) and splitting adds overhead.
Use `CUDA_VISIBLE_DEVICES=0` to pin to the 4090.
