## To Do

- flash and twister for esp32, nucleog4, native_sim

- more advanced pytest
- add makefile to compile & run native_sim

## Done

- implement emul based shell test for btn, modify pytest_shell
- prepared dockerfile devcontainer. get and use ncs/vanilla is working. west build, twister is working
- create .github workflow
    - run build samples/blinky
    - build
    - run twister
    - run local runner
- try run with twister
- successfully prepare dockerfile + devcontainer + volume persistent + ncs.py script
- successfully build main
