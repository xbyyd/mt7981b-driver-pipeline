# X post (draft)

## Main post

```
Porting MT7981B (Filogic 820) PPE/WED hooks into OpenWrt 24.10 on aarch64 —
containerised build, pinned kernel tree, no vendor SDK.

Blocker today: modpost says "mtk_wed_device_attach [mt7981b_ppe] undefined!".
CONFIG_NET_MEDIATEK_SOC_WED is off, so the symbol never reaches Module.symvers.
On target it shows up as insmod: Unknown symbol in module (err -2).

Repo + full logs: https://github.com/xbyyd/mt7981b-driver-pipeline

Next: replace the direct calls with an ops-table handoff, then retest on the
MT7981B board.
```

Character count of the code block above, excluding newlines: roughly 480 —
too long for a single tweet. Split into a thread, or use the short version.

## Short version (fits one post, ~270 chars)

```
Porting MT7981B (Filogic 820) PPE/WED hooks into OpenWrt 24.10 in a Docker build
pipeline. Blocker: modpost "mtk_wed_device_attach [mt7981b_ppe] undefined!" —
CONFIG_NET_MEDIATEK_SOC_WED off, symbol never reaches Module.symvers.
Repo + log: github.com/xbyyd/mt7981b-driver-pipeline
```

## Thread follow-up (optional, post as reply)

```
Triage trail:
- grep .config -> # CONFIG_NET_MEDIATEK_SOC_WED is not set
- Module.symvers has 0 hits for mtk_wed_device_attach
- /proc/kallsyms on the board shows it as lowercase 't' (local, unexported)
Same root cause, two symptoms: link time and load time.
```

## Before you post — check these

1. Replace `xbyyd` with the account that actually hosts the repo,
   and make sure the repo is public (a 404 behind a login reads as no evidence).
2. Only keep the Devin sentence if Devin is genuinely part of the work. If it
   is not, delete it — an easily disproved claim is worse than no claim.
3. Pin the repo link in your profile or reply, so the post and the repo point
   at each other.
