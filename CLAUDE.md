# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build System

ArduPilot uses the WAF build system (Python-based). All build commands should be run from the repository root.

### Common Build Commands

**Configure for a board** (required first step):
```bash
./waf configure --board <board-name>
```

Common boards:
- `sitl` - Software-in-the-loop simulator (for development/testing)
- `sitl --debug` - SITL with debug symbols
- `CubeBlack` - Pixhawk2/Cube flight controller
- `Pixhawk1` - Original Pixhawk
- `linux` - Linux-based boards

**Build vehicle firmware**:
```bash
./waf copter          # All multirotor types
./waf heli            # Helicopter
./waf plane           # Fixed wing (including VTOL)
./waf rover           # Ground rovers and boats
./waf sub             # Submarines/ROVs
./waf antennatracker  # Antenna tracker
./waf AP_Periph       # CAN peripheral firmware
```

**Build specific binary**:
```bash
./waf --targets bin/arducopter
./waf --targets tests/test_math
```

**List all available targets**:
```bash
./waf list
```

**List available boards**:
```bash
./waf list_boards
```

**Clean build artifacts**:
```bash
./waf clean           # Clean current board only
./waf distclean       # Clean all boards
```

**Submodule management**:
```bash
./waf submodulesync         # Sync submodules
./waf submodule_force_clean # Force clean and resync submodules
```

**Upload firmware** (for supported boards):
```bash
./waf --targets bin/arducopter --upload
```

Build artifacts are located in `build/<board-name>/bin/`.

### Build Options

Enable/disable features during configure:
```bash
./waf configure --board sitl --enable-scripting --enable-networking
```

See `Tools/scripts/build_options.py` for all available options.

## Testing

### Running SITL (Software-in-the-Loop)

Primary method for development and testing:
```bash
Tools/autotest/sim_vehicle.py -v ArduCopter
Tools/autotest/sim_vehicle.py -v ArduPlane
Tools/autotest/sim_vehicle.py -v Rover
```

The `sim_vehicle.py` script automatically configures, builds, and launches the simulator with MAVProxy.

### Running Unit Tests

```bash
./waf configure --board sitl
./waf check              # Build and run relevant tests
./waf check-all          # Build and run all tests
./waf --alltests         # Same as check-all
```

Individual test:
```bash
./waf --targets tests/test_vectors
./build/sitl/tests/test_vectors  # Run directly after building
```

### Running Autotest Suite

The comprehensive test suite that validates vehicle behavior:
```bash
Tools/autotest/autotest.py                    # Run all tests
Tools/autotest/autotest.py build.Copter       # Test ArduCopter
Tools/autotest/autotest.py test.Copter.SITL   # Run SITL tests
```

Test scripts per vehicle:
- `Tools/autotest/arducopter.py` - Copter tests
- `Tools/autotest/arduplane.py` - Plane tests
- `Tools/autotest/rover.py` - Rover tests
- `Tools/autotest/ardusub.py` - Sub tests

## Architecture Overview

### Repository Structure

```
ArduPilot/
├── ArduCopter/          # Multicopter/helicopter vehicle firmware
├── ArduPlane/           # Fixed-wing vehicle firmware
├── Rover/               # Ground/water vehicle firmware
├── ArduSub/             # Underwater vehicle firmware
├── AntennaTracker/      # Ground antenna tracker firmware
├── Blimp/               # Lighter-than-air vehicle firmware
├── libraries/           # 150+ shared libraries (core functionality)
│   ├── AP_*             # Core autopilot libraries
│   ├── AC_*             # Copter-specific control libraries
│   ├── AR_*             # Rover-specific libraries
│   ├── AP_HAL*/         # Hardware Abstraction Layer implementations
│   └── GCS_MAVLink/     # MAVLink communication protocol
├── Tools/
│   ├── autotest/        # Automated testing framework
│   ├── AP_Bootloader/   # Universal bootloader
│   ├── AP_Periph/       # CAN peripheral firmware
│   └── scripts/         # Utility scripts
└── modules/             # Git submodules (DroneCAN, ChibiOS, MAVLink, etc.)
```

### Key Architectural Patterns

**1. Modular Library System**

Each vehicle is composed of libraries selected for its needs. Libraries are in `libraries/` and fall into categories:
- **AP_*** - Core autopilot functionality (sensors, control, navigation, logging, communication)
- **AC_*** - Copter-specific control (attitude control, position control, autotune)
- **AR_*** - Rover-specific control (motor control, waypoint navigation)
- **AP_HAL*** - Hardware abstraction layer implementations

**2. Hardware Abstraction Layer (HAL)**

Located in `libraries/AP_HAL/` with implementations in:
- `AP_HAL_ChibiOS/` - STM32 microcontrollers (primary flight controllers)
- `AP_HAL_Linux/` - Single-board computers (Raspberry Pi, BeagleBone)
- `AP_HAL_ESP32/` - ESP32 microcontrollers
- `AP_HAL_SITL/` - Software simulation
- `AP_HAL_QURT/` - Qualcomm Snapdragon

The HAL provides platform-independent interfaces for UART, I2C, SPI, GPIO, timers, storage, etc.

**3. Configuration System**

- **Hardware definitions**: `libraries/AP_HAL_*/hwdef/*.dat` files define board-specific pin mappings and peripherals
- **Feature configuration**: Each library has `<LibraryName>_config.h` for compile-time feature enablement
- **Vehicle configuration**: Each vehicle has `config.h`, `defines.h`, and `Parameters.h`
- **Build options**: `Tools/scripts/build_options.py` centralizes feature flags

**4. Parameter System**

The `AP_Param` library (`libraries/AP_Param/`) provides persistent parameter storage:
- Parameters are defined in vehicle `Parameters.h` files
- Stored in EEPROM/flash with backward compatibility support
- Accessible via MAVLink protocol and scripting
- Support for nested parameter groups

**5. MAVLink Communication**

`libraries/GCS_MAVLink/` implements the MAVLink protocol:
- `GCS_Common.cpp` - Core MAVLink handling (~6000 lines)
- Vehicle-specific extensions in each vehicle directory
- Handles telemetry, commands, parameters, missions

**6. Vehicle Entry Points**

Each vehicle has a main class (e.g., `Copter`, `Plane`, `Rover`) that:
- Inherits from `AP_Vehicle` base class
- Implements scheduler callbacks for periodic tasks
- Manages flight mode state machines
- Coordinates library interactions

Main files:
- ArduCopter: `ArduCopter/Copter.cpp` and `Copter.h`
- ArduPlane: `ArduPlane/Plane.cpp` and `Plane.h`
- Rover: `Rover/Rover.cpp` and `Rover.h`

### Build System Architecture

1. **Configuration**: `./waf configure --board X` selects board definition and HAL
2. **Library Selection**: Each vehicle's `wscript` specifies required libraries
3. **Compilation**: WAF recursively compiles libraries and vehicle code
4. **Linking**: Libraries are linked into static archives, then linked with vehicle code
5. **Output**: Binary placed in `build/<board>/bin/`

The root `wscript` (890+ lines) orchestrates the entire build process.

## Development Patterns

### Adding Features to Vehicles

1. Most new functionality goes into a library (create in `libraries/` or extend existing)
2. Add library to vehicle's `wscript` build dependencies
3. Instantiate library object in vehicle class
4. Add parameters if needed in vehicle's `Parameters.h`
5. Call library methods from vehicle's scheduler or mode logic

### Working with Parameters

Parameters use the `AP_Param` system:
```cpp
// In header file
AP_Int16 my_param;

// In parameters table
// @Param: MY_PARAM
// @DisplayName: My Parameter
// @Description: Description of what it does
// @Range: 0 100
// @User: Standard
AP_GROUPINFO("MY_PARAM", 1, ClassName, my_param, 0),
```

Parameter metadata comments are parsed for documentation generation.

### Working with MAVLink

- Message handlers in `GCS_MAVLink/GCS_Common.cpp` or vehicle-specific files
- Use `handle_message()` virtual function for vehicle-specific messages
- Send messages using `send_*()` functions
- MAVLink definitions come from `modules/mavlink/` submodule

### Scripting Support

Lua scripting enabled with `SCR_ENABLE` parameter:
- Scripts placed in `scripts/` folder (on SD card or working directory)
- Scripts have access to vehicle state, sensors, and actuators
- Enable with `--enable-scripting` during configure
- Examples in `libraries/AP_Scripting/examples/`

### Running Single Tests During Development

For rapid iteration on specific functionality:
```bash
./waf configure --board sitl --debug
./waf --targets tests/test_math
./build/sitl/tests/test_math
```

Or run SITL for quick functional testing:
```bash
Tools/autotest/sim_vehicle.py -v ArduCopter --console --map
```

## Important Notes

- **Never run `waf` with `sudo`** - causes permission issues
- **Always run from repository root** - not from subdirectories
- **Incremental builds are default** - cleaning rarely needed
- **Submodules required** - clone with `--recursive` or run `submodulesync`
- **Board selection persistent** - only need to configure once per board
- **Multiple boards supported** - builds isolated in `build/<board>/` directories

## SITL Quick Reference

For complete SITL documentation including setup, troubleshooting, and Docker options, see **[SITL.md](SITL.md)**.

**Quick start:**
```bash
# Start simulator without MAVProxy (recommended for GCS connection)
Tools/autotest/sim_vehicle.py -v ArduCopter --no-mavproxy --out=tcpin:0.0.0.0:5760 &

# Connect with MAVProxy
mavproxy.py --master=tcp:127.0.0.1:5760

# Stop simulator
pkill arducopter
```

**Common MAVProxy commands:**
```
status              # Check vehicle status
mode GUIDED         # Change to GUIDED mode
arm throttle force  # Force arm (bypasses PreArm in SITL)
takeoff 10          # Takeoff to 10 meters
mode LAND           # Land the vehicle
```

## Reference Documentation

- Developer wiki: https://ardupilot.org/dev/
- Build system docs: https://ardupilot.org/dev/docs/building-the-code.html
- SITL docs: https://ardupilot.org/dev/docs/sitl-simulator-software-in-the-loop.html
- Contributing guide: https://ardupilot.org/dev/docs/contributing.html
- Discussion forum: https://discuss.ardupilot.org/
