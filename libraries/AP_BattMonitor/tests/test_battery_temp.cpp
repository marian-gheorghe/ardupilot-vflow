#include <AP_gtest.h>

#include <AP_BattMonitor/AP_BattMonitor_Backend.h>

/*
  The battery over-temperature pre-arm verdict. A battery hotter than the configured maximum must
  report over-temperature (arming refused); one at or below it must not. A disabled limit (zero or
  negative) never reports over-temperature, whatever the sensor reads.
 */
TEST(AP_BATTMONITOR_TEMP, hot_battery_is_over_temperature)
{
    EXPECT_TRUE(AP_BattMonitor_Backend::overtemperature(70.0f, 60.0f));
    EXPECT_TRUE(AP_BattMonitor_Backend::overtemperature(60.5f, 60.0f));
}

TEST(AP_BATTMONITOR_TEMP, cool_battery_is_not_over_temperature)
{
    EXPECT_FALSE(AP_BattMonitor_Backend::overtemperature(25.0f, 60.0f));
    EXPECT_FALSE(AP_BattMonitor_Backend::overtemperature(60.0f, 60.0f));
}

TEST(AP_BATTMONITOR_TEMP, disabled_limit_never_reports_over_temperature)
{
    EXPECT_FALSE(AP_BattMonitor_Backend::overtemperature(120.0f, 0.0f));
    EXPECT_FALSE(AP_BattMonitor_Backend::overtemperature(120.0f, -1.0f));
}

AP_GTEST_MAIN()
