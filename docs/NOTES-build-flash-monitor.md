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

```bash
west sdk list

west sdk install -t xtensa-espressif_esp32s3_zephyr-elf
west sdk install -t xtensa-espressif_esp32_zephyr-elf

west blobs fetch hal_espressif
```

## STM

```bash
export BOARD="nucleo_g474re"

# Build
west build -b $BOARD zephyr/samples/basic/blinky -d build -p -- -DZEPHYR_SCACHE=ccache

# Flash via ST-LINK
west flash -d build

# Monitor (press Ctrl+] to exit)
python3 -m serial.tools.miniterm /dev/ttyACM0 115200 --raw
```