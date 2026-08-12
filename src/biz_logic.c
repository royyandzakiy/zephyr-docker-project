#include <zephyr/kernel.h>
#include <zephyr/drivers/gpio.h>
#include "biz_logic.h"

static const struct gpio_dt_spec led = GPIO_DT_SPEC_GET(DT_ALIAS(led0), gpios);
static const struct gpio_dt_spec btn = GPIO_DT_SPEC_GET(DT_ALIAS(sw0), gpios);
static const struct gpio_dt_spec hal = GPIO_DT_SPEC_GET(DT_ALIAS(hal0), gpios);

static int blink_interval = 500;

void biz_logic_init(void) {
    gpio_pin_configure_dt(&led, GPIO_OUTPUT_INACTIVE);
    gpio_pin_configure_dt(&btn, GPIO_INPUT);
    gpio_pin_configure_dt(&hal, GPIO_INPUT);
}

void biz_logic_process(void) {
    bool btn_pressed = (gpio_pin_get_dt(&btn) > 0);
    bool magnet_near = (gpio_pin_get_dt(&hal) > 0);

    // Logic: If magnet is near, go fast. If button also pressed, go super fast.
    if (magnet_near && btn_pressed) {
        blink_interval = 100;
    } else if (magnet_near) {
        blink_interval = 250;
    } else {
        blink_interval = 500;
    }
    
    gpio_pin_toggle_dt(&led);
}

int get_current_blink_interval(void) {
    return blink_interval;
}