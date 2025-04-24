#include "xx.h"
#include "stm32f1xx_hal.h"
#include <math.h>

 float sign; // Declare signal as an external variable
void systemStartp(void) {
        sign = sinf(HAL_GetTick() / 1000.0f);
}
