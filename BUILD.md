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

```bash
# Build & Run
royya@tuff16:~/project-coding/iot/zephyr-ztest-emul-button-hal$ west twister -vv -n -T tests/biz_logic --outdir build_tests_twister
INFO    - Using Ninja..
INFO    - Zephyr version: ncs-v3.2.1
INFO    - Using 'zephyr' toolchain.
INFO    - Selecting default platforms per testsuite scenario
INFO    - Building initial testsuite list...
INFO    - Writing JSON report build_tests_twister/testplan.json
INFO    - JOBS: 20
INFO    - Adding tasks to the queue...
INFO    - Added initial list of jobs to queue
INFO    - 1/1 native_sim/native         biz_logic.testing.ztest                            PASSED (native 0.008s <host>)
INFO    -                                    biz_logic_tests.boost_mode                                                  PASSED      
INFO    -                                    biz_logic_tests.magnet_detected                                             PASSED      
INFO    -                                    biz_logic_tests.default_state                                               PASSED      

INFO    - 1 test scenarios (1 configurations) selected, 0 configurations filtered (0 by static filter, 0 at runtime).
Summary
├── Total test suites: 1
├── Processed test suites: 1
│   ├── Filtered test suites: 0
│   │   ├── Filtered test suites (static): 0
│   │   └── Filtered test suites (at runtime): 0
│   └── Selected test suites: 1
│       ├── Skipped test suites: 0
│       ├── Passed test suites: 1
│       ├── Built only test suites: 0
│       ├── Failed test suites: 0
│       └── Errors in test suites: 0
└── Total test cases: 3
    ├── Filtered test cases: 0
    └── Selected test cases: 3
        ├── Passed test cases: 3
        ├── Skipped test cases: 0
        ├── Built only test cases: 0
        ├── Blocked test cases: 0
        ├── Failed test cases: 0
        └── Errors in test cases: 0
INFO    - 1 of 1 executed test configurations passed (100.00%), 0 built (not run), 0 failed, 0 errored, with no warnings in 18.77 seconds.
INFO    - 3 of 3 executed test cases passed (100.00%) on 1 out of total 1205 platforms (0.08%).
INFO    - 1 test configurations executed on platforms, 0 test configurations were only built.
INFO    - Saving reports...
INFO    - Writing JSON report /home/royya/project-coding/iot/zephyr-ztest-emul-button-hal/build_tests_twister/twister.json
INFO    - Writing xunit report /home/royya/project-coding/iot/zephyr-ztest-emul-button-hal/build_tests_twister/twister.xml...
INFO    - Writing xunit report /home/royya/project-coding/iot/zephyr-ztest-emul-button-hal/build_tests_twister/twister_report.xml...
INFO    - Run completed
```

### Using west build

```bash
west build -b native_sim -s tests/biz_logic -d build_tests_west -- -DEXTRA_DTC_OVERLAY_FILE=../../boards/native_sim.overlay
build_tests_west/biz_logic/zephyr/zephyr.exe
```

```bash
# Run
royya@tuff16:~/project-coding/iot/zephyr-ztest-emul-button-hal$ /home/royya/project-coding/iot/zephyr-ztest-emul-button-hal/build_test/biz_logic/zephyr/zephyr.exe
WARNING: Using a test - not safe - entropy source
*** Booting nRF Connect SDK v3.2.1-d8887f6f32df ***
*** Using Zephyr OS v4.2.99-ec78104f1569 ***
Running TESTSUITE biz_logic_tests
===================================================================
START - test_boost_mode
 PASS - test_boost_mode in 0.000 seconds
===================================================================
START - test_default_state
 PASS - test_default_state in 0.000 seconds
===================================================================
START - test_magnet_detected
 PASS - test_magnet_detected in 0.000 seconds
===================================================================
TESTSUITE biz_logic_tests succeeded

------ TESTSUITE SUMMARY START ------

SUITE PASS - 100.00% [biz_logic_tests]: pass = 3, fail = 0, skip = 0, total = 3 duration = 0.000 seconds
 - PASS - [biz_logic_tests.test_boost_mode] duration = 0.000 seconds
 - PASS - [biz_logic_tests.test_default_state] duration = 0.000 seconds
 - PASS - [biz_logic_tests.test_magnet_detected] duration = 0.000 seconds

------ TESTSUITE SUMMARY END ------

===================================================================
PROJECT EXECUTION SUCCESSFUL
```