# Build, Flash, Monitor

## NRF

```bash
export SNR="1050073602"
export BOARD="nrf5340dk/nrf5340/cpuapp"

# Build
west build -b $BOARD zephyr/samples/basic/blinky -d build -p -- -DZEPHYR_SCACHE=ccache

# Flash & Reset
nrfutil device erase --serial-number $SNR
nrfutil device program --serial-number $SNR --firmware build/zephyr/zephyr.hex
nrfutil device reset --serial-number $SNR

# Monitor (press Ctrl+] to exit)
python3 -m serial.tools.miniterm $(nrfutil device list --json | jq -r --arg snr "$SNR" '.[] | select(.serialNumber == $snr) | .ports[]? | select(.port | contains("tty")) | .port' | head -n 1) 115200 --raw
```

## ESP

```bash
export BOARD="esp32s3_devkitm/esp32s3/procpu"

# Build
west build -b $BOARD zephyr/samples/basic/blinky -d build -p -- -DZEPHYR_SCACHE=ccache

# Flash (west handles esptool underneath)
west flash -d build

# Monitor (press Ctrl+] to exit)
python3 -m serial.tools.miniterm /dev/ttyACM0 115200 --raw
```

Error: Espressif toolchain not yet installed

```bash
Make Error at /workdir/zephyr-sdks/v4.2.2/zephyr/cmake/compiler/gcc/target.cmake:11 (message):
  C compiler
  /workdir/zephyr-sdks/toolchains/zephyr-sdk-0.17.0/xtensa-espressif_esp32s3_zephyr-elf/bin/xtensa-espressif_esp32s3_zephyr-elf-gcc
  not found - Please check your toolchain installation
```

Solution:

```bash
west sdk list

west sdk install -t xtensa-espressif_esp32s3_zephyr-elf
west sdk install -t xtensa-espressif_esp32_zephyr-elf

west blobs fetch hal_espressif
```

## STM

```bash
export BOARD="nucleo_g474re"

west build -b nucleo_g474re -s tests/drivers/gpio_button_toggle -p always -d build_nucleog4_test_gpio_toggle

west flash --runner pyocd -d build_nucleog4_test_gpio_toggle/
# or, to be specific
west flash --runner pyocd -d build_nucleog4_test_gpio_toggle/ -- --dev-id 0046002E3234510A37333934

# Monitor (press Ctrl+] to exit)
python3 -m serial.tools.miniterm /dev/ttyACM0 115200 --raw
```

Error: STM32 G4 not yet installed

```bash
-- west flash: rebuilding
ninja: no work to do.
-- west flash: using runner pyocd
-- runners.pyocd: Flashing file: build_nucleog4_test_gpio_toggle/zephyr/zephyr.hex
Waiting for a debug probe to be connected...
0026001 C Target type stm32g474retx not recognized. Use 'pyocd list --targets' to see currently available target types. See <https://pyocd.io/docs/target_support.html> for how to install additional target support. [__main__]
FATAL ERROR: command exited with status 1: pyocd flash -e sector -a 0x8000000 -t stm32g474retx build_nucleog4_test_gpio_toggle/zephyr/zephyr.hex
```

Solution:

```bash
pyocd list --targets
pyocd pack install stm32g474retx
```