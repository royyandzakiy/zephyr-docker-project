# Testing on nRF5340dk (on-target)

```bash
west build -b nrf5340dk/nrf5340/cpuapp -p always -d build_nrf53_test_gpio_toggle -s tests/drivers/gpio_button_toggle -p always

west flash -d build_nrf53_test_gpio_toggle --runner nrfutil -- --dev-id 1050073602
# or
nrfutil device program --firmware build_nrf53_test_gpio_toggle/zephyr/zephyr.hex --serial-number 1050073602

python3 -m serial.tools.miniterm --raw /dev/ttyACM1 115200
```

```bash
# hardware-map.yaml
- connected: true
  id: '1050073602'
  platform: nrf5340dk/nrf5340/cpuapp
  product: J-Link
  runner: nrfutil
  serial: /dev/ttyACM1
```

```bash
west twister --device-testing --hardware-map hardware-map.yaml -T tests/drivers/gpio_button_toggle

# or, without hardware-map
west twister \
  -p nrf5340dk/nrf5340/cpuapp \
  --device-testing \
  --device-serial /dev/ttyACM1 \
  --west-flash-extra="--runner=nrfutil,--dev-id=1050073602" \
  -T tests/drivers/gpio_button_toggle
```

Result

```bash
root@673c242c8bb0:/workspaces/zephyr-docker-project# west twister \
  -p nrf5340dk/nrf5340/cpuapp \
  --device-testing \
  --device-serial /dev/ttyACM1 \
  --west-flash-extra="--runner=nrfutil,--dev-id=1050073602" \
  -T tests/drivers/gpio_button_toggle
Renaming output directory to /workspaces/zephyr-docker-project/twister-out.18
INFO    - Using Ninja..
INFO    - Zephyr version: v4.2.2
INFO    - Using 'zephyr' toolchain.
INFO    - Building initial testsuite list...
INFO    - Writing JSON report /workspaces/zephyr-docker-project/twister-out/testplan.json

Device testing on:

| Platform                 | ID   | Serial device   |
|--------------------------|------|-----------------|
| nrf5340dk/nrf5340/cpuapp |      | /dev/ttyACM1    |

INFO    - JOBS: 16
INFO    - Adding tasks to the queue...
INFO    - Added initial list of jobs to queue
INFO    - Total complete:    1/   1  100%  built (not run):    0, filtered:    0, failed:    0, error:    0
INFO    - 1 test scenarios (1 configurations) selected, 0 configurations filtered (0 by static filter, 0 at runtime).
INFO    - 1 of 1 executed test configurations passed (100.00%), 0 built (not run), 0 failed, 0 errored, with no warnings in 77.59 seconds.
INFO    - 1 of 1 executed test cases passed (100.00%) on 1 out of total 1115 platforms (0.09%).
INFO    - 1 test configurations executed on platforms, 0 test configurations were only built.

Hardware distribution summary:

| Board                    | ID   |   Counter |   Failures |
|--------------------------|------|-----------|------------|
| nrf5340dk/nrf5340/cpuapp |      |         1 |          0 |
INFO    - Saving reports...
INFO    - Writing JSON report /workspaces/zephyr-docker-project/twister-out/twister.json
INFO    - Writing xunit report /workspaces/zephyr-docker-project/twister-out/twister.xml...
INFO    - Writing xunit report /workspaces/zephyr-docker-project/twister-out/twister_report.xml...
INFO    - Run completed
```

# Testing on ESP32S3 (on-target)

```bash
west build -b esp32s3_devkitc/esp32s3/procpu \
  -s tests/drivers/gpio_button_toggle \
  -p always \
  -d build_esp32s3_test_gpio_toggle \
  -- -DDTC_OVERLAY_FILE="/workspaces/zephyr-docker-project/boards/esp32s3_devkitc_esp32s3_procpu.overlay"

west flash --runner esp32 --esp-device /dev/ttyACM0 -d build_esp32s3_test_gpio_toggle

python3 -m serial.tools.miniterm --raw /dev/ttyACM0 115200
```

added flags:
- `--flash-before`: by default is, the harness opens the serial port first, then flashes, causing it to be stale and fail to read. flashes first and opens the serial connection afterwards, and it propagates into the generated pytest command
- `--extra-args=DTC_OVERLAY_FILE`: esp32s3 does NOT have a built in switch0 and led0 in its default .dts files, hence the overlay needs to be called explicitly. another thing is, currently the esp32s3 is stored inside the root/boards, hence does NOT get automatically captured because our target is not to root, but instead to `tests/drivers/gpio_button_toggle`
- `--west-runner esp32`: required to be able to flash. the esp32 is universal for espressif chips, not just the esp32 type board.

```bash
west twister \
  -p esp32s3_devkitc/esp32s3/procpu \
  --device-testing \
  --device-serial /dev/ttyACM0 \
  --device-serial-baud 115200 \
  --flash-before \
  --west-flash="--esp-device=/dev/ttyACM0" \
  --west-runner esp32 \
  -T tests/drivers/gpio_button_toggle \
  --extra-args=DTC_OVERLAY_FILE=/workspaces/zephyr-docker-project/boards/esp32s3_devkitc_esp32s3_procpu.overlay
```

```bash
# hardware-map.yaml
- connected: true
  id: '/dev/ttyACM0'
  platform: esp32s3_devkitc/esp32s3/procpu
  product: ESP32-S3
  runner: esp32
  serial: /dev/ttyACM0
  baud: 115200
```

# Testing on Nucleo G4 (on-target)

```bash
west build -b nucleo_g474re -s tests/drivers/gpio_button_toggle -p always -d build_nucleog4_test_gpio_toggle

west flash --runner pyocd -d build_nucleog4_test_gpio_toggle/
# or, to be specific
west flash --runner pyocd -d build_nucleog4_test_gpio_toggle/ -- --dev-id 0046002E3234510A37333934

python3 -m serial.tools.miniterm --raw /dev/ttyACM0 115200
```

```bash
# hardware-map.yaml
- connected: true
  id: '0046002E3234510A37333934'
  platform: nucleo_g474re
  product: ST-LINK/V3
  runner: pyocd
  serial: /dev/ttyACM0
  baud: 115200
```

```bash
west twister --device-testing --hardware-map hardware-map.yaml -T tests/drivers/gpio_button_toggle

# or, without hardware-map
west twister \
  -p nucleo_g474re \
  --device-testing \
  --device-serial /dev/ttyACM0 \
  --device-serial-baud 115200 \
  --west-flash \
  --west-runner pyocd \
  -T tests/drivers/gpio_button_toggle
```

# Testing on Native Sim (off-target)

```bash
west build -p always -b native_sim/native -s tests/drivers/gpio_button_toggle -d build_nativesim_test_gpio_toggle -- -DDTC_OVERLAY_FILE="/workspaces/zephyr-docker-project/boards/native_sim.overlay"

build_nativesim_test_gpio_toggle/zephyr/zephyr.exe
```

```bash
twister -p native_sim/native -T tests/drivers/gpio_button_toggle -- -DDTC_OVERLAY_FILE="/workspaces/zephyr-docker-project/boards/native_sim.overlay"
```