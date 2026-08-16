# Testing on nRF5340dk (on-target)

```bash
west build -b nrf5340dk/nrf5340/cpuapp -p always -d build_nrf53_pytest_shell -s tests/pytest_shell -p always

nrfutil device program --firmware build_nrf53_pytest_shell/zephyr/zephyr.hex --serial-number 1050073602

python3 -m serial.tools.miniterm --raw /dev/ttyACM1 115200
```

```bash
west twister -p nrf5340dk/nrf5340/cpuapp --device-testing --device-serial /dev/ttyACM1 --west-flash="--snr 1050073602" -T tests/pytest_shell
```

# Testing on Native Sim (off-target)
## Build & Run

```bash
west build -b native_sim -p always --
```

```bash
zephyr-emul-project/build/zephyr-emul-project/zephyr/zephyr.exe
```

```bash
# serial monitor
WARNING: Using a test - not safe - entropy source
*** Booting nRF Connect SDK v3.3.0-ba167d9f3db4 ***
*** Using Zephyr OS v4.3.99-fd9204a02d52 ***
Hello from Zephyr RTOS! count = 1
Hello from Zephyr RTOS! count = 2
Hello from Zephyr RTOS! count = 3
Hello from Zephyr RTOS! count = 4
^C
Stopped at 1.790s
```

## Testing

### `simple_test` Twister based test build & run

```bash
twister -p native_sim/native -T tests/simple_test
```

```bash
# Output
Renaming previous output directory to /workspaces/zephyr-emul-project/twister-out.11
INFO    - Using Ninja..
INFO    - Zephyr version: fd9204a02d52
INFO    - Using 'zephyr' toolchain.
INFO    - Building initial testsuite list...
INFO    - Built testsuite list in 0.01 seconds
INFO    - Writing JSON report /workspaces/zephyr-emul-project/twister-out/testplan.json
INFO    - JOBS: 16
INFO    - Adding tasks to the queue...
INFO    - Added initial list of jobs to queue
INFO    - Total complete:    1/   1  100%  built (not run):    0, filtered:    0, failed:    0, error:    0
INFO    - 1 test scenarios (1 configurations) selected, 0 configurations filtered (0 by static filter, 0 at runtime).
INFO    - 1 of 1 executed test configurations passed (100.00%), 0 built (not run), 0 failed, 0 errored, with no warnings in 8.89 seconds.
INFO    - 2 of 2 executed test cases passed (100.00%) on 1 out of total 1386 platforms (0.07%).
INFO    - 1 test configurations executed on platforms, 0 test configurations were only built.
INFO    - Saving reports...
INFO    - Writing JSON report /workspaces/zephyr-emul-project/twister-out/twister.json
INFO    - Writing xunit report /workspaces/zephyr-emul-project/twister-out/twister.xml...
INFO    - Writing xunit report /workspaces/zephyr-emul-project/twister-out/twister_report.xml...
INFO    - Run completed
```

### `simple_test` West based test build & run

```bash
rm -rf build_tests
west build -p -b native_sim/native tests/simple_test -d build_tests
```

```bash
zephyr-emul-project/build_tests/simple_test/zephyr/zephyr.exe

# Output
WARNING: Using a test - not safe - entropy source
*** Booting nRF Connect SDK v3.3.0-ba167d9f3db4 ***
*** Using Zephyr OS v4.3.99-fd9204a02d52 ***
Running TESTSUITE test_simple_tests
===================================================================
START - test_another_check
[00:00:00.000,000] <inf> simple_test: === Starting test_another_check ===
[00:00:00.000,000] <inf> simple_test: Expected: 5, Actual: 5
[00:00:00.000,000] <inf> simple_test: === Test passed! ===
 PASS - test_another_check in 0.000 seconds
===================================================================
START - test_simple_assert
[00:00:00.000,000] <inf> simple_test: === Starting test_simple_assert ===
[00:00:00.000,000] <inf> simple_test: === Test passed! ===
 PASS - test_simple_assert in 0.000 seconds
===================================================================
TESTSUITE test_simple_tests succeeded

------ TESTSUITE SUMMARY START ------

SUITE PASS - 100.00% [test_simple_tests]: pass = 2, fail = 0, skip = 0, total = 2 duration = 0.000 seconds
 - PASS - [test_simple_tests.test_another_check] duration = 0.000 seconds
 - PASS - [test_simple_tests.test_simple_assert] duration = 0.000 seconds

------ TESTSUITE SUMMARY END ------

===================================================================
PROJECT EXECUTION SUCCESSFUL
root@f0aaad86c393:/workspaces/zephyr-emul-project# ls build_tests/compile_commands.json
ls: cannot access 'build_tests/compile_commands.json': No such file or directory
root@f0aaad86c393:/workspaces/zephyr-emul-project# 
```

### `pytest_basic` build & run

```bash
twister -p native_sim/native -T tests/pytest_basic -vvv
```

```bash
# Output
Renaming previous output directory to /workspaces/zephyr-emul-project/twister-out.22
INFO    - Using Ninja..
INFO    - Zephyr version: fd9204a02d52
INFO    - Using 'zephyr' toolchain.
INFO    - Building initial testsuite list...
INFO    - Built testsuite list in 0.00 seconds
INFO    - Writing JSON report /workspaces/zephyr-emul-project/twister-out/testplan.json
INFO    - JOBS: 16
INFO    - Adding tasks to the queue...
INFO    - Added initial list of jobs to queue
INFO    - 1/1 native_sim/native         sample.twister.pytest                              PASSED (native 0.020s <host>)
INFO    -                                    sample.twister.pytest.test_case                                             PASSED      
INFO    -                                    sample.twister.pytest.test_custom_arg                                       PASSED      

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
└── Total test cases: 2
    ├── Filtered test cases: 0
    └── Selected test cases: 2
        ├── Passed test cases: 2
        ├── Skipped test cases: 0
        ├── Built only test cases: 0
        ├── Blocked test cases: 0
        ├── Failed test cases: 0
        └── Errors in test cases: 0
INFO    - 1 of 1 executed test configurations passed (100.00%), 0 built (not run), 0 failed, 0 errored, with no warnings in 16.78 seconds.
INFO    - 2 of 2 executed test cases passed (100.00%) on 1 out of total 1386 platforms (0.07%).
INFO    - 1 test configurations executed on platforms, 0 test configurations were only built.
INFO    - Saving reports...
INFO    - Writing JSON report /workspaces/zephyr-emul-project/twister-out/twister.json
INFO    - Writing xunit report /workspaces/zephyr-emul-project/twister-out/twister.xml...
INFO    - Writing xunit report /workspaces/zephyr-emul-project/twister-out/twister_report.xml...
INFO    - Run completed
```

### `pytest_shell` build & run

```bash
twister -p native_sim/native -T tests/pytest_shell -vvv
```

```bash
# Output
Renaming previous output directory to /workspaces/zephyr-emul-project/twister-out.23
INFO    - Using Ninja..
INFO    - Zephyr version: fd9204a02d52
INFO    - Using 'zephyr' toolchain.
INFO    - Building initial testsuite list...
INFO    - Built testsuite list in 0.00 seconds
INFO    - Writing JSON report /workspaces/zephyr-emul-project/twister-out/testplan.json
INFO    - JOBS: 16
INFO    - Adding tasks to the queue...
INFO    - Added initial list of jobs to queue
INFO    - 1/3 native_sim/native         sample.harness.shell                               PASSED (native 0.231s <host>)
INFO    -                                    sample.harness.shell.test_shell_harness                                     PASSED      
INFO    - 2/3 native_sim/native         sample.pytest.shell.vt100_colors_off               PASSED (native 0.469s <host>)
INFO    -                                    sample.pytest.shell.vt100_colors_off.test_shell_print_help                  PASSED      
INFO    -                                    sample.pytest.shell.vt100_colors_off.test_shell_print_version               PASSED      
INFO    - 3/3 native_sim/native         sample.pytest.shell                                PASSED (native 0.451s <host>)
INFO    -                                    sample.pytest.shell.test_shell_print_help                                   PASSED      
INFO    -                                    sample.pytest.shell.test_shell_print_version                                PASSED      

INFO    - 3 test scenarios (3 configurations) selected, 0 configurations filtered (0 by static filter, 0 at runtime).
Summary
├── Total test suites: 3
├── Processed test suites: 3
│   ├── Filtered test suites: 0
│   │   ├── Filtered test suites (static): 0
│   │   └── Filtered test suites (at runtime): 0
│   └── Selected test suites: 3
│       ├── Skipped test suites: 0
│       ├── Passed test suites: 3
│       ├── Built only test suites: 0
│       ├── Failed test suites: 0
│       └── Errors in test suites: 0
└── Total test cases: 5
    ├── Filtered test cases: 0
    └── Selected test cases: 5
        ├── Passed test cases: 5
        ├── Skipped test cases: 0
        ├── Built only test cases: 0
        ├── Blocked test cases: 0
        ├── Failed test cases: 0
        └── Errors in test cases: 0
INFO    - 3 of 3 executed test configurations passed (100.00%), 0 built (not run), 0 failed, 0 errored, with no warnings in 18.69 seconds.
INFO    - 5 of 5 executed test cases passed (100.00%) on 1 out of total 1386 platforms (0.07%).
INFO    - 3 test configurations executed on platforms, 0 test configurations were only built.
INFO    - Saving reports...
INFO    - Writing JSON report /workspaces/zephyr-emul-project/twister-out/twister.json
INFO    - Writing xunit report /workspaces/zephyr-emul-project/twister-out/twister.xml...
INFO    - Writing xunit report /workspaces/zephyr-emul-project/twister-out/twister_report.xml...
INFO    - Run completed
```