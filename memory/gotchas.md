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

**MTP models and speculative decoding**
noctrex-qwen3.6:35b is an MTP (Multi-Token Prediction) model. Do NOT pass spec-decoding flags
(`--draft-model`, etc.) — MTP breaks temp=0 determinism when used for spec decoding.

**no_mmap is required for large MoE models**
Without `--no-mmap`, large MXFP4 MoE models can take very long to load and may cause
page-fault latency spikes during inference.

**Large MXFP4 models take 30-90 s to load**
dev.sh polls for up to 90 s. If the server hasn't responded by then, check `/tmp/llama-server.log`.
The most common cause is VRAM not freeing from a previous process — run `nvidia-smi` to confirm.

## Pi

**Developer role not supported by llama-server**
Set `"supportsDeveloperRole": false` in `~/.pi/agent/models.json`. Pi sends system prompts as
`developer` role by default; llama-server only understands `system`.

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
`.pi/settings.json` is loaded relative to cwd. Running Pi from a parent directory will miss
the project settings and fall back to global — the `--model` flag will be needed.

## Hardware

**PCIe bandwidth limits 70B tensor-parallel throughput**
RTX 4090 + RTX 3090 have no NVLink. At 70B (Q4_K_S, ~37 GB) tensor-split across both cards,
throughput is PCIe-bound (~20 tok/s). 30-35B MoE models with small active parameter sets are
effectively immune to this because inter-GPU traffic is minimal.

**RTX 3090 at 333-344W (95-98%) under dense tensor_split is normal**
This is the card running at capacity during dense 27-32B tensor-split. Not a thermal concern
unless the card reports throttling.

**CUDA_VISIBLE_DEVICES for single-GPU MoE**
Small MoE models (MXFP4, ~16-20 GB) that fit on one GPU run faster without tensor_split
because the 4090 (~1008 GB/s) is faster than the 3090 (~936 GB/s) and splitting adds overhead.
Use `CUDA_VISIBLE_DEVICES=0` to pin to the 4090.
