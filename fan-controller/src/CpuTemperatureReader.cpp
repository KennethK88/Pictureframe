#include "CpuTemperatureReader.h"
#include <fstream>

std::optional<Temperature> CpuTemperatureReader::getTemperature() const
{
    std::ifstream file("/sys/class/thermal/thermal_zone0/temp");

    if (!file) return std::nullopt;

    int milliDegrees = 0;
    file >> milliDegrees;

    if (!file) return std::nullopt;

    return milliDegrees / 1000.0;
}