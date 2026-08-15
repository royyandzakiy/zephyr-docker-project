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
