## To Do

- add makefile to compile & run native_sim
- implement emul i2c & spi bmi190
- implement emul gpio

## Done

- prepared dockerfile devcontainer. get and use ncs/vanilla is working. west build, twister is working
- create .github workflow
    - run build samples/blinky
    - build
    - run twister
    - run local runner
---

## To Do
- run the twister with pytest. create a new simple_pytest_test

- create a test with emul mocking use (eg: spi)
- create pytest e2e console testing
    - create a dummy main app using native_sim inside tests/dummy_main_console

## Pytest Explore
- ble testing
- device adapter
- test fixture

## Docker improvement
- instead of using script ncs.py for install, use west.yaml

## Done
- try run with twister
- successfully prepare dockerfile + devcontainer + volume persistent + ncs.py script
- successfully build main
