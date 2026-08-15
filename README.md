# zephyr-docker-project

A reusable devcontainer + project template for Zephyr RTOS and nRF Connect SDK development, with off-target testing wired up from the start.

One container image. SDKs live in shared Docker volumes, not in your repo and not in the image. Clone this template for a new project and it attaches to the same SDKs you already downloaded — no re-download, no per-project toolchain sprawl.

Ships with **vanilla Zephyr v4.2.2** and **nRF Connect SDK v3.3.0**, switchable with a single shell command.

---

## What you get

| | |
|---|---|
| **Container** | Devcontainer on top of `zephyrprojectrtos/zephyr-build`, reproducible across Windows (WSL2), macOS and Linux |
| **SDKs** | Vanilla Zephyr + NCS side by side, switched per-terminal with `use-vanilla` / `use-ncs` |
| **Shared cache** | SDKs live in named Docker volumes shared by every project using this template |
| **Off-target** | `native_sim` and `qemu_cortex_m3` ready, with board overlays already in place |
| **Unit tests** | ztest suites runnable in milliseconds, no board required |
| **Test runner** | Twister as the canonical runner, across platforms and configurations |
| **E2E tests** | Twister's `harness: pytest`, plus a host-side pytest layer for build/workflow validation |
| **Editor** | clangd configuration for real completion and diagnostics on Zephyr sources |
| **CI** | GitHub Actions workflows for hosted builds and, optionally, self-hosted hardware runs |

---

## The idea

Most Zephyr setups put the SDK somewhere on your host, or bake it into a per-project image. Both hurt: the first is a manual environment everyone reproduces slightly differently, the second means every new project re-downloads several gigabytes.

This template does neither. The Dockerfile installs *tooling* only. The SDKs are fetched on first container start into two named Docker volumes:

```
zephyr-sdks-cache  ->  /workdir/zephyr-sdks    vanilla Zephyr + zephyr-sdk toolchains
ncs-sdks-cache     ->  /workdir/ncs-sdks       NCS trees + nrfutil toolchain bundles
```

Named volumes are global to your Docker daemon. Any project whose `devcontainer.json` declares the same mounts sees the same SDKs. Start a second project, and the setup script finds everything already present and exits in seconds.

Adding a new SDK version costs one download, once, for all projects.

---

## Requirements

- Docker Desktop (Windows/macOS, WSL2 backend) or Docker Engine (Linux)
- VS Code with the **Dev Containers** extension
- ~25 GB free disk for SDKs and toolchains
- x86_64 host

> **Note on `native_sim` and `qemu_cortex_m3`:** both run inside the Linux container, so they work identically on all three host OSes. What does *not* work is building them natively on Windows outside the container — which is exactly why the container is not optional here.

---

## Quick start

```bash
git clone <your-repo> && cd <your-repo>
code .
```

Then **Reopen in Container**. On first start, `.devcontainer/setup-sdks.sh` populates the volumes. Expect roughly 10–20 minutes for the initial vanilla Zephyr fetch and toolchain install. Every subsequent start, and every other project on the same machine, is near-instant.

Open a new terminal and build:

```bash
west build -b native_sim -s . -d build_native_sim --pristine \
  -- -DEXTRA_DTC_OVERLAY_FILE="boards/native_sim.overlay"

./build_native_sim/zephyr/zephyr.exe
```

Run the test suite:

```bash
west twister -T tests/ --outdir build_tests_twister -vv
```

---

## Switching SDKs

Three functions are available in every interactive shell:

```bash
use-vanilla                # vanilla Zephyr v4.2.2, zephyr-sdk 0.17.0 (default)
use-vanilla v4.1.0 0.17.0  # any version/toolchain pair you have installed
use-ncs                    # nRF Connect SDK v3.3.0
use-ncs v3.2.1             # any NCS version — installed on demand if missing
reset-ncs                  # back to container baseline
```

Each call resets the environment before applying the new one, so switching is safe and repeatable. `ZEPHYR_BASE`, `ZEPHYR_SDK_INSTALL_DIR`, `PATH` and `LD_LIBRARY_PATH` are all rewritten together — a partial switch is the usual cause of "wrong toolchain" build failures, and this avoids it.

`use-vanilla v4.2.2` runs automatically on shell start. Change the last line of the `.bashrc` block in `.devcontainer/Dockerfile` if you'd rather default to NCS.

**Installing a version you don't have yet:**

```bash
use-ncs v3.2.1
# -> not found locally, installs toolchain via nrfutil, fetches sources via west, then switches
```

Vanilla versions are added by editing `ZEPHYR_VAN_VER` / `ZEPHYR_SDK_VER` in `.devcontainer/setup-sdks.sh`, or by fetching manually into `/workdir/zephyr-sdks/<version>/zephyr`.

List what's installed:

```bash
python3 .devcontainer/ncs.py --list
```

**A note on the shape of this:** `ncs.py` prints shell `export` statements that the bash function `eval`s. That's what lets a Python script mutate your live shell environment. It's a small trick, but it's the reason SDK switching works without sourcing files by hand.

---

## Layout

```
.devcontainer/
  Dockerfile          tooling, nrfutil, J-Link, SDK switch helpers
  devcontainer.json   volume mounts, USB passthrough, VS Code extensions
  setup-sdks.sh       first-run SDK provisioning (idempotent)
  ncs.py              NCS version resolution / install / env emission
.github/workflows/    CI pipelines
boards/               devicetree overlays per target
src/                  application source
tests/
  <suite>/            ztest suites  (testcase.yaml + src/)
  <suite>/pytest/     Twister pytest harness tests
  python/             host-side pytest (build & workflow validation)
.clangd               clangd configuration
CMakeLists.txt
prj.conf
pytest.ini
requirements-dev.txt
```

---

## Building

The overlay flag is the part people forget. Targets and their overlays:

```bash
# native_sim — fastest loop, supports gpio/i2c/spi emulation
west build -b native_sim -s . -d build_native_sim --pristine \
  -- -DEXTRA_DTC_OVERLAY_FILE="boards/native_sim.overlay"
./build_native_sim/zephyr/zephyr.exe

# qemu_cortex_m3 — architecture-accurate, no board
west build -b qemu_cortex_m3 -s . -d build_qemu --pristine \
  -- -DEXTRA_DTC_OVERLAY_FILE="boards/qemu_cortex_m3.overlay"
west build -d build_qemu -t run

# nrf5340dk — physical hardware
west build -b nrf5340dk/nrf5340/cpuapp -s . -d build_nrf5340dk --pristine \
  -- -DEXTRA_DTC_OVERLAY_FILE="boards/nrf5340dk_nrf5340_cpuapp.overlay"
west flash -d build_nrf5340dk
```

To add a target: drop an overlay in `boards/`, add the board to `platform_allow` in the relevant `testcase.yaml`.

---

## Testing

Three layers, each with a different job.

### 1. ztest on `native_sim` — unit tests

Your fast loop. Runs as a native binary on the host, in milliseconds, with Zephyr's emulator subsystem (`gpio-emul`, `i2c_emul`, SPI emulators) standing in for peripherals at the devicetree level.

```bash
west twister -T tests/<suite> --outdir build_tests_twister -vv

# or a direct build when you want to iterate on one suite
west build -b native_sim -s tests/<suite> -d build_test --pristine \
  -- -DEXTRA_DTC_OVERLAY_FILE=../../boards/native_sim.overlay
./build_test/zephyr/zephyr.exe
```

Each suite is a mini Zephyr application: `CMakeLists.txt`, `prj.conf`, `src/`, `testcase.yaml`. Copy an existing one as a starting point.

### 2. Twister — the canonical runner

Everything else is a convenience; Twister is what CI runs and what you should trust.

```bash
west twister -T tests/ --outdir build_tests_twister -vv     # everything
west twister -T tests/ -p native_sim -p qemu_cortex_m3      # platform matrix
west twister -T tests/ --tag pytest                         # filter by tag
west twister -T tests/ --coverage --coverage-tool gcovr     # coverage
west twister -T tests/ --device-testing --hardware-map map.yml   # on hardware
```

Artifacts land in the outdir: `twister.json`, `twister.xml` (JUnit), per-configuration build and run logs.

### 3. pytest — end-to-end

Two distinct things share the name, and it's worth keeping them separate:

**Twister's pytest harness** (`tests/<suite>/pytest/`) drives a running Zephyr image via the device abstraction — the shell, mcumgr, a serial console. Selected by `harness: pytest` in `testcase.yaml`, and invoked through Twister like any other suite. This is your black-box end-to-end layer, and it runs on `native_sim` and on real hardware unchanged.

**Host-side pytest** (`tests/python/`) tests the project itself: structure, configs, build scripts, whether the binary boots. It never touches Zephyr's test framework.

```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements-dev.txt

pytest tests/python/ -v -m "not e2e"    # fast validation
pytest tests/python/ -v                 # everything
```

Markers are defined in `pytest.ini`: `smoke`, `unit`, `integration`, `e2e`, `slow`.

---

## clangd

Zephyr's include graph is generated at build time, so no static configuration can be right for every target. The reliable setup is to point clangd at the compilation database CMake already produces:

```bash
west build -b native_sim -s . -d build_native_sim --pristine \
  -- -DEXTRA_DTC_OVERLAY_FILE="boards/native_sim.overlay" \
     -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
ln -sf build_native_sim/compile_commands.json compile_commands.json
```

clangd then reads the exact flags, defines and generated headers used for that build. Re-link the symlink when you switch the target you're working against.

`.clangd` in the repo root carries the diagnostic suppressions that make Zephyr sources readable in an editor (generated devicetree macros and `__ZEPHYR__` internals otherwise produce a lot of noise).

> The clangd config is per-project state, not container state, and needs to match the SDK you have active. If completion goes quiet after a `use-ncs` / `use-vanilla` switch, rebuild and re-link the database.

---

## CI

`.github/workflows/` holds two patterns.

**Hosted build and test** runs in `zephyrprojectrtos/ci`, caches the Zephyr workspace, SDK and ccache between runs, builds, and uploads artifacts. This is the one to enable on every push — it needs no hardware and costs nothing but minutes.

**Self-hosted hardware runs** flash and test on a physical board. The container ships a GitHub Actions runner binary and the Nordic tooling (`nrfutil`, `nrfjprog`, J-Link) for exactly this, with `--privileged` and `/dev/bus/usb` passthrough declared in `devcontainer.json` so a probe attached to the host is visible inside the container.

Both workflows are `workflow_dispatch`-only as shipped. Uncomment the `push` / `pull_request` triggers when you want them live.

> **If you don't need hardware CI,** the runner download and the Nordic command-line tools are roughly 700 MB of image you're carrying for nothing, and `--privileged` is a real permission grant. Deleting the "SETTING UP GITHUB ACTIONS RUNNER" block from the Dockerfile and the `runArgs` from `devcontainer.json` gives you a smaller, less privileged container that still does everything in the Testing section above.

Hardware runs need `CI_<BOARD>_SNR` set to your probe's serial number (`nrfutil device list`) and a `concurrency` group so two jobs never reach for the same board at once.

---

## Reusing this for a new project

```bash
git clone https://github.com/royyandzakiy/zephyr-docker-project my-new-project
cd my-new-project && rm -rf .git && git init
```

Then:

1. Rename the CMake `project()` in `CMakeLists.txt`
2. Replace `src/` with your application
3. Replace `tests/` suites with yours, keeping one as a reference
4. Trim `boards/` to the targets you actually build

Open in the container. Because the volume names are unchanged, it attaches to the SDKs already on disk and is ready in seconds.

**Two projects, different SDK versions?** Fine — the volumes hold many versions in parallel, and the active one is per-terminal, not per-container. Change the default in the Dockerfile's `.bashrc` block per project if you want it automatic.

---

## Troubleshooting

| Symptom | Cause |
|---|---|
| `ZEPHYR_BASE not set` | Fresh non-interactive shell. Run `use-vanilla` or `use-ncs`. |
| Build picks the wrong SDK | Half-switched environment. `reset-ncs`, then switch again in a clean terminal. |
| CMake can't find the Zephyr SDK | Toolchain not registered as a CMake package — re-run `setup.sh -c` in the SDK directory. |
| First container start takes forever | Expected. It's downloading the SDKs into the volumes. Only happens once per machine. |
| `nrfutil device list` empty | USB passthrough. On WSL2 you must `usbipd attach` from Windows first. |
| J-Link connect fails (`-105`) | Something else holds the probe. The nRF Connect VS Code extension is the usual culprit — close it, or don't install it in the container. |
| clangd shows errors everywhere | No compilation database. Build with `-DCMAKE_EXPORT_COMPILE_COMMANDS=ON` and symlink it. |

To start completely clean:

```bash
docker volume rm zephyr-sdks-cache ncs-sdks-cache
```

---

## Versions

| Component | Version |
|---|---|
| Base image | `zephyrprojectrtos/zephyr-build:v0.29.3` |
| Vanilla Zephyr | v4.2.2 |
| Zephyr SDK | 0.17.0 (`x86_64-zephyr-elf`, `arm-zephyr-eabi`) |
| nRF Connect SDK | v3.3.0 |
| Nordic Command Line Tools | 10.24.0 |
| GitHub Actions runner | 2.336.0 |

Pinned deliberately. Reproducibility is the point — bump them when you decide to, not when upstream does.