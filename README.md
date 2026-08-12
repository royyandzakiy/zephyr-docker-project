# Zephyr ZTest and GPIO Emulation

> Tested, successfully build & running on WSL2/Ubuntu `24.04`, nRF Connect SDK `v3.2.1` & `v3.3.0`

## Overview

This repository serves as a reference implementation for developing and testing embedded business logic within the Zephyr RTOS ecosystem. The project demonstrates a robust hardware-abstraction workflow, allowing developers to verify peripheral-dependent logic using software emulation before deploying to physical silicon.

The core objective of this project is to showcase how **ZTest** and **GPIO Emulation** can be used to "fake" hardware inputs (such as Hall sensors and buttons) to achieve 100% test coverage of business logic without requiring physical hardware interaction.

For reference, you can refer to the Zephyr Project documentation on Emulator/Simulators: [https://docs.zephyrproject.org/latest/hardware/emulator/index.html](https://docs.zephyrproject.org/latest/hardware/emulator/index.html)

## Key Features

* **Decoupled Business Logic:** Implementation of logic in a standalone module (`biz_logic`) that is independent of specific hardware drivers.
* **Multi-Platform Support:** Single codebase targeting physical Nordic Semiconductor hardware, QEMU ARM emulation, and Native POSIX simulation.
* **Emulated Test Suite:** A comprehensive test suite located in `tests/biz_logic` that utilizes the `zephyr,gpio-emul` driver to simulate various hardware states.
* **Automated Testing with Twister:** Full integration with Zephyr’s `twister` tool for automated test execution and reporting.

## Project Structure

* `src/`: Primary application source code.
* `tests/`: ZTest suites for verifying business logic.
* `boards/`: Devicetree overlays for `nrf5340dk`, `qemu_cortex_m3`, and `native_sim`.
* `NOTES.md`: Detailed technical documentation, build commands, and execution logs.

## Hardware and Simulation Targets

This project is configured to run on three distinct targets, each serving a specific phase of the development lifecycle:

1. **Native Simulation (`native_sim`):** Used for rapid development and unit testing. This target supports GPIO emulation, allowing for automated verification of logic branches.
2. **QEMU (`qemu_cortex_m3`):** Provides a middle-ground hardware simulation to verify architecture-specific behavior (Cortex-M3) without physical hardware.
3. **Physical Hardware (`nrf5340dk`):** Final deployment target for real-world verification on the Nordic nRF5340 Development Kit.

Note: Currenlty Native Simulation & QEMU had only successfully been tested to work on WSL/Linux (NOT on Windows)

## Getting Started

To begin using this framework, ensure you have the Zephyr development environment and the nRF Connect SDK (v3.2.1 or later) installed.

### Build and Test

The project utilizes `west` for building and flashing. For detailed command-line instructions, including specific arguments for Devicetree overlays and Sysbuild configuration, please refer to the documentation in `NOTES.md`.

### Testing Workflow

The recommended workflow for this project is:

1. Modify logic in `src/`.
2. Execute tests on `native_sim` using `west twister` or `west build`.
3. Verify system behavior in `qemu_cortex_m3`.
4. Perform final integration testing on the `nrf5340dk`.

## Documentation

For a complete list of build commands, monitor configurations, and example execution output, please refer to the **[NOTES.md](https://www.google.com/search?q=./NOTES.md)** file.