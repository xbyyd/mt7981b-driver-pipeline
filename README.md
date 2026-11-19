# mt7981b-driver-pipeline

Reproducible container pipeline for porting the MediaTek **MT7981B** (Filogic 820) PPE/WED driver hooks into an out-of-tree kernel module on top of OpenWrt 24.10 `mediatek/filogic` (aarch64, Cortex-A53, Linux 6.6.x).

Everything runs inside Docker so the host toolchain, the kernel tree and the driver patch are pinned to the same combination on any machine. No SDK installed on the host.

## Status

| Stage | What it does | State |
|---|---|---|
| `00-bootstrap` | host build deps + toolchain inside the image | done |
| `01-fetch-openwrt` | clone `openwrt-24.10`, `feeds update/install` | done |
| `02-configure` | generate `.config` for `mediatek/filogic`, `make defconfig` | done |
| `03-apply-patches` | stage the `mt7981b-ppe` package + patch `0001` | done |
| `04-build` | build `mt7981b_ppe.ko` with `make V=s`, tee log | **fails at modpost** |
| `05-insmod` | load module on the target, read `dmesg` | blocked by 04 |

## Current blocker

`modpost` cannot resolve two WED/PPE symbols, so the module never reaches the link stage:

```
$ docker run --rm mt7981b-pipeline
...
  CC [M]  .../linux-mediatek_filogic/mt7981b-ppe/mt7981b_ppe.o
  MODPOST .../linux-mediatek_filogic/mt7981b-ppe/Module.symvers
ERROR: modpost: "mtk_wed_device_attach" [mt7981b_ppe] undefined!
ERROR: modpost: "mtk_ppe_wed_bind" [mt7981b_ppe] undefined!
make[6]: *** [scripts/Makefile.modpost:133: .../Module.symvers] Error 1
```

Full capture: [`logs/build-2026-11-18-modpost.log`](logs/build-2026-11-18-modpost.log)

Load-time symptom from the earlier build (symbols stubbed, not exported):

```
$ insmod mt7981b_ppe.ko
insmod: ERROR: could not insert module mt7981b_ppe.ko: Unknown symbol in module
```

Capture: [`logs/target-insmod-2026-11-17.log`](logs/target-insmod-2026-11-17.log)

### Root cause

`CONFIG_NET_MEDIATEK_SOC_WED` is off in the `.config` this pipeline generates, so `mtk_wed` / `mtk_ppe` are built without the WED glue and the symbols never land in `Module.symvers`:

```
$ grep -i 'NET_MEDIATEK_SOC_WED\|NET_MEDIATEK_SOC' build/openwrt/.config
# CONFIG_NET_MEDIATEK_SOC_WED is not set
CONFIG_NET_MEDIATEK_SOC=y
$ grep -c mtk_wed_device_attach build/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-mediatek_filogic/Module.symvers
0
```

Two ways out, being evaluated:

1. enable `CONFIG_NET_MEDIATEK_SOC_WED` (+ `CONFIG_NET_MEDIATEK_WED`) in the target config and rebuild the kernel — heavy, changes the firmware footprint;
2. drop the strong dependency: negotiate the WED attach through an exported ops table instead of direct symbol references, so `mt7981b_ppe.ko` only needs `mtk_ppe_*` core symbols.

Option 2 is the current line of work; see `src/mt7981b_ppe.c` (`#ifdef MT7981B_WED_DIRECT_CALLS`).

## Repo layout

```
.
├── Dockerfile                     # ubuntu:22.04 + openwrt build deps
├── scripts/
│   ├── run-pipeline.sh            # entrypoint, runs 00 -> 04
│   ├── 00-bootstrap.sh            # sanity checks inside the image
│   ├── 01-fetch-openwrt.sh        # clone + feeds
│   ├── 02-configure.sh            # .config for mediatek/filogic
│   ├── 03-apply-patches.sh        # stage package, apply patches
│   └── 04-build.sh                # build the module, tee to logs/
├── package/kernel/mt7981b-ppe/
│   ├── Makefile                   # OpenWrt kernel package
│   └── src/                       # module sources + Kbuild
├── patches/0001-*.patch           # PPE/WED hook wiring
├── logs/                          # captured build + load logs
└── .github/workflows/build.yml    # CI: build image, run pipeline, upload logs
```

## Quick start

```bash
git clone https://github.com/xbyyd/mt7981b-driver-pipeline.git
cd mt7981b-driver-pipeline

docker build -t mt7981b-pipeline .
docker run --rm -v "$PWD/logs:/build/logs" mt7981b-pipeline
```

First run pulls ~1.2 GB of image layers and clones OpenWrt; the module build itself is a couple of minutes on 8 cores. The run always ends at the same modpost failure until the symbol issue above is resolved — that is the point of the pinned container.

Host target used for the captures in `logs/`:

```
$ docker --version && nproc && uname -m
Docker version 27.3.1, build ce12230
12
x86_64
```

## Roadmap

- [ ] replace direct WED symbol references with the ops-table handoff (branch `feat/wed-ops-table`)
- [ ] enable `CONFIG_NET_MEDIATEK_SOC_WED` as a comparison build
- [ ] `05-insmod` stage against a real MT7981B board (`BananaPi BPI-R3 mini` / `GL-MT3000`), `dmesg` diff
- [ ] PPE flow-offload smoke test (`iperf3` + `conntrack -L`)
- [ ] CI: cache the OpenWrt tree between runs

## Notes

- `logs/` is committed on purpose — the build failures are part of the record.
- Nothing here touches a vendor SDK under NDA; all sources are the public `openwrt-24.10` tree plus my own patch.
- Kernel version in the pinned tree: `6.6.73` (`mediatek/filogic`).

License: GPL-2.0 (kernel module), MIT for the pipeline scripts.
