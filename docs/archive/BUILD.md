# Running

> WARNING: For `native_sim` & `qemu_cortex_m3` currently only working in linux/WSL. Does NOT compile nor run for windows

Start new terminal that has all necessary environments setup

![new-terminal](docs/new-terminal.png)

## Build & Run `root` on nrf5340dk (real hardware)

```bash
# Build
west build --build-dir build_nrf5340dk -s . --pristine --board nrf5340dk/nrf5340/cpuapp -- -DEXTRA_DTC_OVERLAY_FILE=boards/nrf5340dk_nrf5340_cpuapp.overlay -DDEBUG_THREAD_INFO=On -DCONFIG_DEBUG_THREAD_INFO=y -Dzephyr-ztest-emul-button-hal_DEBUG_THREAD_INFO=On

# Flash
lsusb
ls /dev/ttyACM*
west flash -d build_nrf5340dk

# Monitor
minicom -D /dev/ttyACM0 -b 115200
```

## Build & Run `root` on qemu_cortex_m3 (hardware simulation)

This currently **does NOT work on Windows** (only on WSL or Linux)

```bash
west build --build-dir build_qemu -s . --pristine --board qemu_cortex_m3 -- -DEXTRA_DTC_OVERLAY_FILE="boards/qemu_cortex_m3.overlay" -DDEBUG_THREAD_INFO=On -DCONFIG_DEBUG_THREAD_INFO=y
west build -d build_qemu/zephyr-ztest-emul-button-hal -t run
```

```bash
royya@tuff16:~/project-coding/iot/zephyr-ztest-emul-button-hal$ west build -d build_qemu/zephyr-ztest-emul-button-hal -t run
-- west build: running target run
[0/1] To exit from QEMU enter: 'CTRL+a, x'[QEMU] CPU: cortex-m3
qemu-system-arm: warning: nic stellaris_enet.0 has no peer
Timer with period zero, disabling
*** Booting nRF Connect SDK v3.2.1-d8887f6f32df ***
*** Using Zephyr OS v4.2.99-ec78104f1569 ***
```

## Build & Run `root` on native_sim (software simulation)

This currently **does NOT work on Windows** (only on WSL or Linux)

### Using west build

```bash
west build --build-dir build_native_sim -s . --pristine --board native_sim/native -- -DEXTRA_DTC_OVERLAY_FILE="boards/native_sim.overlay" -DDEBUG_THREAD_INFO=On -DCONFIG_DEBUG_THREAD_INFO=y -Dzephyr-ztest-emul-button-hal_DEBUG_THREAD_INFO=On

build_native_sim/zephyr-ztest-gpio-emul/zephyr/zephyr.exe
```

### Alt. via nrf connect extension

> Note: extension cannot run .exe, so needs to still call from the build folder directly, or set as extension in .vscode launch.json

![nrf-build-native-sim](docs/nrf-build-native-sim.png)

```bash
# Running
(.venv) royya@tuff16:~/project-coding/iot/project/zephyr-ztest-gpio-emul$ /home/royya/project-coding/iot/project/zephyr-ztest-gpio-emul/build_native_sim/zephyr-ztest-gpio-emul/zephyr/zephyr.exe
WARNING: Using a test - not safe - entropy source
*** Booting nRF Connect SDK v3.2.1-d8887f6f32df ***
*** Using Zephyr OS v4.2.99-ec78104f1569 ***
```

![build_qemu_m3-configuration](docs/build_qemu_m3-configuration.png)

![build_native_sim-configuration](docs/build_native_sim-configuration.png)

---

# Testing

## Build & Run `tests/biz_logic` on native_sim

The reason native_sim is used, is because the ability to use `gpio_emul` to emulate gpio input and output values. Therefore really supercharging the unit testing capability just like using fakes.

### Using Twister

```bash
west twister -vv -n -T tests/biz_logic --outdir build_tests_twister
```

### Using west build

```bash
west build -b native_sim -s tests/biz_logic -d build_tests_west -- -DEXTRA_DTC_OVERLAY_FILE=../../boards/native_sim.overlay
build_tests_west/biz_logic/zephyr/zephyr.exe
```