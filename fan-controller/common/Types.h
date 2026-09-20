#pragma once

using Temperature = double;

enum class FanState
{
    Off,
    On
};

enum class GpioLevel
{
    Low,
    High
};

using GpioPin = unsigned int;