#pragma once
#include <optional>
#include "Types.h"

class CpuTemperatureReader
{
    public:
        std::optional<Temperature> getTemperature() const;
};