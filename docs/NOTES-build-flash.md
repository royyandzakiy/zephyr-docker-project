# Zephyr Command Reference: Build, Flash, Twister

**General Notes**:

- Every command below is one of three phases. Almost all flag confusion comes from putting a flag in the wrong phase.
- `-p` means **pristine** in `west build`, but **platform** in `west twister`. They are unrelated. This is the single most common mix-up.
- Flags are grouped here by *who consumes them*, not by alphabet.

## The Three Phases

```
cmake/ninja  ──build──▶  zephyr.elf  ──flash──▶  board  ──observe──▶  pass/fail
     ▲                                   ▲                    ▲
  build args                        flash args          device args
  -D... / --extra-args              --west-flash=       --device-serial
```

Rule of thumb:

- Changes the **bytes in the image** → build arg (overlays, Kconfig, `CONFIG_*`)
- Changes **where the bytes go / how they get there** → flash arg (port, dev-id, runner options)
- Changes **how you watch the result** → device arg (console port, baud)

A devicetree overlay is consumed by the devicetree compiler at configure time. By the time `west flash` runs, its effect is already baked into `zephyr.bin` — passing it to the flash step is meaningless and the runner will reject it as an unknown argument.

---

## `west build`

```bash
west build -b <board> -s <source_dir> -d <build_dir> -p always -- -D<VAR>=<value>
```

Flags:

- `-b, --board`: target board, e.g. `nrf5340dk/nrf5340/cpuapp`. Board qualifiers (`/soc/core`) are required on multi-core SoCs.
- `-s, --source-dir`: app or test directory. If omitted, defaults to cwd.
- `-d, --build-dir`: output directory. Use a distinct one per board so builds don't clobber each other.
- `-p, --pristine`: wipe the build dir first. Accepts `always` / `never` / `auto`; bare `-p` equals `-p always`. Passing it twice does nothing.
- `-t, --target`: run a specific build target instead of the default, e.g. `-t menuconfig`, `-t guiconfig`.
- `--`: everything after this goes to CMake, not to west.

CMake args (all go after `--`, each prefixed with `-D`):

- `-DEXTRA_DTC_OVERLAY_FILE=<abs_path>`: **appends** an overlay on top of the auto-discovered set (`app.overlay`, `boards/<board>.overlay`). This is what you want in almost every case.
- `-DDTC_OVERLAY_FILE=<abs_path>`: **replaces** the entire auto-discovered set. `app.overlay` is silently dropped. Only use when you deliberately need to suppress the defaults.
- `-DEXTRA_CONF_FILE=<abs_path>`: appends a Kconfig fragment on top of `prj.conf`.
- `-DCONF_FILE=<abs_path>`: replaces `prj.conf` entirely. Same replace-vs-append trap as above.

Paths must be **absolute**. Relative paths resolve against the app source dir, not your cwd. Use `$PWD/...` so the command still works outside the devcontainer.

### Overlay auto-discovery

Relative to the source dir given by `-s`:

```
tests/drivers/gpio_button_toggle/
  app.overlay                                 # all boards, automatic
  prj.conf                                    # all boards, automatic
  boards/
    esp32s3_devkitc_esp32s3_procpu.overlay    # this board only, automatic
    native_sim_native.conf                    # this board only, automatic
```

Board filenames use the **normalized** board name: slashes become underscores. Files in the *workspace* root `boards/` are never found — discovery is relative to `-s`, so those must be passed explicitly.

---

## `west flash`

```bash
west flash -d <build_dir> --runner <runner> [runner options]
```

Flags:

- `-d, --build-dir`: which build to flash. Required if you use non-default build dirs.
- `-r, --runner`: flash backend. `nrfutil`, `esp32`, `pyocd`, `jlink`, `openocd`.
- `--dev-id <id>`: which physical probe/board, when more than one is attached. Common option, understood by most runners.
- `--erase`: full chip erase before programming.
- `--`: separator before runner-specific args. Not needed for common options like `--dev-id`, but harmless.

Runner-specific:

- `--esp-device <port>` (**esp32 only**): serial port esptool writes to.
- `--esp-baud-rate <baud>` (**esp32 only**): flashing baud. Independent of console baud.
- `--runner nrfutil` (**Nordic only**): replaces the deprecated `nrfjprog`. `--snr` is dead; use `--dev-id`.
- `--runner pyocd` (**ST/ARM CMSIS-DAP**): `--dev-id` here is the ST-LINK serial number.

Nordic without west, if you want the raw tool:

```bash
nrfutil device program --firmware <build_dir>/zephyr/zephyr.hex --serial-number 1050073602
nrfutil device reset --serial-number 1050073602
```

---

## Monitor

```bash
python3 -m serial.tools.miniterm --raw /dev/ttyACM0 115200
```

- `--raw`: don't mangle control characters. Without it, shell output and ANSI escapes render wrong.
- Port must be free. Close the monitor before flashing or running Twister, or you get a port-busy error.

**ESP32-S3 note**: `ttyACM0` is the native USB-Serial-JTAG peripheral, `ttyUSB0` is the onboard UART bridge. They are different endpoints with different behaviour. Pick one and use it consistently across build, flash, and monitor.

---

## `west twister`

```bash
west twister \
  -p <board> \
  --device-testing \
  --device-serial <port> \
  --device-serial-baud 115200 \
  --west-flash[="arg,arg"] \
  --west-runner <runner> \
  -T <testsuite_root>
```

### Selection

- `-p, --platform`: board to test. Repeatable. **Platform**, not pristine.
- `-T, --testsuite-root`: directory to scan for `testcase.yaml` / `sample.yaml`. Repeatable.
- `-s, --scenario`: run one specific scenario, e.g. `-s tests/drivers/gpio_button_toggle/gpio.button.toggle`.
- `-O, --outdir`: output dir, defaults to `twister-out/`. Previous runs roll over to `twister-out.1`, `.2`, etc. — check you're reading logs from the current one.
- `-c, --clobber-output`: overwrite `twister-out/` instead of rolling over.

### Build phase

- `-x, --extra-args=VAR=value`: passed to CMake as `-DVAR=value`. Same vars as the `west build` section above. Repeatable.
  - Applies **globally to every platform in the run**. There is no per-board form. If one board needs a different overlay than the others, `--extra-args` cannot express that — use `boards/<board>.overlay` auto-discovery instead.
- `--build-only`: compile, don't flash or run.
- `--test-only`: skip the build, flash and run existing binaries.

### Flash phase

- `--device-testing`: run on real hardware instead of an emulator. Required for all on-target runs.
- `--west-flash[="a,b,c"]`: use `west flash` instead of the build system's flash target. The optional value is a **comma-separated** list of extra args appended to `west flash`.
  - Comma-separated, not space-separated. `--west-flash="--dev-id 123"` is passed as one token and the runner rejects it. Write `--west-flash="--dev-id=123"`.
- `--west-runner <runner>`: which runner. **Requires `--west-flash` to also be present** — Twister errors out otherwise.
- `--flash-before`: flash first, then open the serial port. Default order is the reverse.
  - **ESP32-S3 specific in practice**: native USB re-enumerates on reset, so a port opened before flashing goes stale. J-Link and ST-LINK are separate CDC bridges that survive the reset, so they don't need it.

### Observe phase

- `--device-serial <port>`: port Twister opens to **read** test output and decide pass/fail. Consumed by the harness — never handed to CMake, never handed to `west flash`.
- `--device-serial-baud <baud>`: baud for that console port. Defaults to 115200. Unrelated to flashing baud.

On the ESP32-S3 you name the same port twice, for two different consumers: `--west-flash="--esp-device=/dev/ttyACM0"` for esptool writing, and `--device-serial /dev/ttyACM0` for the harness reading. Not redundant — nothing links them. On the nRF5340DK they legitimately differ: flashing goes through the J-Link by `--dev-id`, while the console is `/dev/ttyACM1`, and no port appears in the flash args at all.

### Debugging a failing run

- `-v`, `-vv`: verbosity.
- `-ll DEBUG`: log level.
- `--pytest-args=<arg>`: forwarded to pytest. Repeatable, e.g. `--pytest-args=-v --pytest-args=--log-cli-level=DEBUG`.

Logs live in `twister-out/<board>/<scenario>/`:

- `build.log` — compile errors
- `device.log` — flash output, runner errors
- `handler.log` — serial capture
- `twister_harness.log` — pytest harness

---

## Hardware Map

Replaces the per-invocation device flags. Preferred for CI and for multi-board runs.

```bash
west twister --device-testing --hardware-map hardware-map.yaml -T tests/drivers/gpio_button_toggle
```

```yaml
- connected: true
  id: '1050073602'
  platform: nrf5340dk/nrf5340/cpuapp
  product: J-Link
  runner: nrfutil
  serial: /dev/ttyACM1
  baud: 115200

- connected: true
  id: '/dev/ttyACM0'
  platform: esp32s3_devkitc/esp32s3/procpu
  product: ESP32-S3
  runner: esp32
  serial: /dev/ttyACM0
  baud: 115200

- connected: true
  id: '0046002E3234510A37333934'
  platform: nucleo_g474re
  product: ST-LINK/V3
  runner: pyocd
  serial: /dev/ttyACM0
  baud: 115200
```

Fields:

- `id`: Twister translates this into the runner-specific argument automatically — `--dev-id` for nrfutil, `--board-id` for pyocd, `--esp-device` for esp32. This is why the map form needs no `--west-flash` escape hatch.
- `runner_params`: list of extra args, the map equivalent of stuffing values into `--west-flash`.
- `connected: true`: skipped if false. `west twister --generate-hardware-map map.yaml` scaffolds the file.

The map and the `-p` / `--device-serial` flags are **mutually exclusive approaches**. Don't mix them in one invocation.

---

## Per-Platform Cheat Sheet

### nRF5340DK — `nrf5340dk/nrf5340/cpuapp`

```bash
west build -b nrf5340dk/nrf5340/cpuapp -p always \
  -s tests/drivers/gpio_button_toggle \
  -d build_nrf53_test_gpio_toggle

west flash -d build_nrf53_test_gpio_toggle --runner nrfutil --dev-id 1050073602

west twister \
  -p nrf5340dk/nrf5340/cpuapp \
  --device-testing \
  --device-serial /dev/ttyACM1 \
  --device-serial-baud 115200 \
  --west-flash="--dev-id=1050073602" \
  --west-runner nrfutil \
  -T tests/drivers/gpio_button_toggle
```

Specific to this board: `nrfutil` runner (not `nrfjprog`), `--dev-id` (not `--snr`), `sw0`/`led0` already exist in the board DTS so no extra overlay is needed.

### ESP32-S3 — `esp32s3_devkitc/esp32s3/procpu`

```bash
west build -b esp32s3_devkitc/esp32s3/procpu -p always \
  -s tests/drivers/gpio_button_toggle \
  -d build_esp32s3_test_gpio_toggle \
  -- -DEXTRA_DTC_OVERLAY_FILE="$PWD/boards/esp32s3_devkitc_esp32s3_procpu.overlay"

west flash -d build_esp32s3_test_gpio_toggle --runner esp32 --esp-device /dev/ttyACM0

west twister \
  -p esp32s3_devkitc/esp32s3/procpu \
  --device-testing \
  --device-serial /dev/ttyACM0 \
  --device-serial-baud 115200 \
  --flash-before \
  --west-flash="--esp-device=/dev/ttyACM0" \
  --west-runner esp32 \
  -T tests/drivers/gpio_button_toggle \
  --extra-args="EXTRA_DTC_OVERLAY_FILE=$PWD/boards/esp32s3_devkitc_esp32s3_procpu.overlay"
```

Specific to this board: `--flash-before` for USB re-enumeration; `--west-runner esp32` covers all Espressif parts, not just the original ESP32; no `sw0`/`led0` in the default DTS so an overlay is mandatory; `ttyACM0` vs `ttyUSB0` are different endpoints.

### Nucleo G474RE — `nucleo_g474re`

```bash
west build -b nucleo_g474re -p always \
  -s tests/drivers/gpio_button_toggle \
  -d build_nucleog4_test_gpio_toggle

west flash -d build_nucleog4_test_gpio_toggle --runner pyocd --dev-id 0046002E3234510A37333934

west twister \
  -p nucleo_g474re \
  --device-testing \
  --device-serial /dev/ttyACM0 \
  --device-serial-baud 115200 \
  --west-flash \
  --west-runner pyocd \
  -T tests/drivers/gpio_button_toggle
```

Specific to this board: `pyocd` runner; `--west-flash` with no value, since the single attached ST-LINK needs no disambiguation.

### native_sim — `native_sim/native`

```bash
west build -b native_sim/native -p always \
  -s tests/drivers/gpio_button_toggle \
  -d build_nativesim_test_gpio_toggle \
  -- -DEXTRA_CONF_FILE="$PWD/boards/native_sim_native.conf"

./build_nativesim_test_gpio_toggle/zephyr/zephyr.exe

west twister \
  -p native_sim/native \
  -T tests/drivers/gpio_button_toggle \
  --extra-args="DTC_OVERLAY_FILE=$PWD/boards/native_sim_native.overlay" \
  --extra-args="EXTRA_CONF_FILE=$PWD/boards/native_sim_native.conf"
```

Specific to this target: no `--device-testing`, no runner, no serial — the binary runs as a host process. The build output is `zephyr.exe`, not `.hex`/`.bin`. This is the one place `DTC_OVERLAY_FILE` (replacing) is correct rather than `EXTRA_`, because `app.overlay` must be suppressed — it references a `led0` node native_sim has no way to provide. `CONFIG_UART_NATIVE_PTY_0_ON_STDINOUT=y` in the `.conf` routes console output to stdout so the harness can read it instead of a pty.

---

## Not Flags

Things that look plausible and are not:

- `--west-flash-extra` — does not exist. Runner args go inside `--west-flash="..."`.
- `--snr` — dead with `nrfutil`. Use `--dev-id`.
- `--west-runner` alone — errors without `--west-flash`.
- `--west-flash="--dev-id 123"` — space-separated is one token; the runner rejects it. Comma-separate and use `=`.
- `-DDTC_OVERLAY_FILE` inside `--west-flash` — wrong phase. Build args never reach the flash step.
