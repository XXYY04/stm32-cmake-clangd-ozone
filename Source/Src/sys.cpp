#include "sys.hpp"
#include "stm32f1xx_hal.h"
#include <math.h>

float sign2;

void systemStart(void) {
    sign2 = cosf(HAL_GetTick() / 1000.0f);
}