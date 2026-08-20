# tests/drivers/gpio_button_toggle/pytest/test_gpio_toggle.py

import logging
from twister_harness import Shell

logger = logging.getLogger(__name__)


def test_gpio_button_toggle(shell: Shell):
    # 1st press: Registers/triggers initial setup state
    logger.info('Sending 1st test_btn command')
    lines = shell.exec_command('test_btn')
    assert any('Test: Triggering emulated button press' in line for line in lines), \
        'Initial test_btn output missing trigger confirmation'

    # 2nd press: LED turns ON
    logger.info('Sending 2nd test_btn command')
    lines = shell.exec_command('test_btn')
    assert any('Button pressed! LED is now ON' in line for line in lines), \
        'Expected LED to turn ON on 2nd press'

    # 3rd press: LED turns OFF
    logger.info('Sending 3rd test_btn command')
    lines = shell.exec_command('test_btn')
    assert any('Button pressed! LED is now OFF' in line for line in lines), \
        'Expected LED to turn OFF on 3rd press'

    # 4th press: LED turns ON again
    logger.info('Sending 4th test_btn command')
    lines = shell.exec_command('test_btn')
    assert any('Button pressed! LED is now ON' in line for line in lines), \
        'Expected LED to turn ON on 4th press'

    # 5th press: LED turns OFF again
    logger.info('Sending 5th test_btn command')
    lines = shell.exec_command('test_btn')
    assert any('Button pressed! LED is now OFF' in line for line in lines), \
        'Expected LED to turn OFF on 5th press'