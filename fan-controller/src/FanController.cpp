#include "FanController.h"

namespace
{
    constexpr Temperature thresholdOn = 58.0;
    constexpr Temperature thresholdOff = 50.0;
}

FanState FanController::updateState(Temperature cpuTemperature)
{
    if (cpuTemperature >= thresholdOn)
    {
        fanState = FanState::On;
    }
    else if (cpuTemperature <= thresholdOff)
    {
        fanState = FanState::Off;
    }
    return fanState;
}

void FanController::forceState(FanState forcedFanState)
{
    fanState = forcedFanState;
}