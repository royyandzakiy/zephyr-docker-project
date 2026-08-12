#include <zephyr/kernel.h>
#include "biz_logic.h"

int count = 0;

int main(void) {
    biz_logic_init();

    while (1) {
        biz_logic_process();
        printk("Hello from Zephyr RTOS! count = %d\n", ++count);
        k_msleep(get_current_blink_interval());
    }
    return 0;
}