# SPDX-License-Identifier: Apache-2.0

cmake_minimum_required(VERSION 3.20.0)

# Setup Test overlay, needs to be defined before find_package
set(TEST_OVERLAY "${CMAKE_CURRENT_SOURCE_DIR}/../../boards/nrf5340dk_test.overlay")

if(DEFINED TEST_OVERLAY_PATH)
    set(TEST_OVERLAY ${TEST_OVERLAY_PATH})
endif()

# Check and apply the overlay
if(EXISTS ${TEST_OVERLAY})
    set(EXTRA_DTC_OVERLAY_FILE ${TEST_OVERLAY})
    message(STATUS "📄 Using extra test overlay: ${TEST_OVERLAY}")
else()
    message(FATAL_ERROR "❌ Test overlay not found: ${TEST_OVERLAY}")
endif()

find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})
project(gpio_test)

target_sources(app PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/../../src/main.c
    ${CMAKE_CURRENT_SOURCE_DIR}/../../src/biz_logic.c
    ${CMAKE_CURRENT_SOURCE_DIR}/test_harness.c
)