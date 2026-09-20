#pragma once
#include "Types.h"

class FanController
{
    private:
        FanState fanState = FanState::Off;

    public:
        FanState updateState(Temperature cpuTemperature);
        void forceState(FanState forcedFanState);
};