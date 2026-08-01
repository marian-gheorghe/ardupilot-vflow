# ArduPilot SITL Guide

Complete guide for running ArduPilot's Software-in-the-Loop (SITL) simulator.

## TL;DR - Quick Start

### Option 1: With QGroundControl (Recommended - 3D Visualization)

```bash
# 1. Start SITL simulator (builds automatically)
Tools/autotest/sim_vehicle.py -v ArduCopter --no-mavproxy

# 2. Open QGroundControl application
open -a QGroundControl  # macOS
# Or launch from Applications folder

# 3. QGC will auto-connect and show:
#    - 2D satellite map
#    - 3D flight visualization (click "3D" button)
#    - Flight instruments
#    - Full GCS interface

# 4. Control the vehicle in QGC:
#    - Click "Fly" tab
#    - Change flight mode to GUIDED
#    - Click "Arm" → "Takeoff" → Enter altitude → Click "Takeoff"
#    - Click on map to fly to location
#    - Click "Land" when done

# Stop simulator when done
pkill arducopter
```

### Option 2: With MAVProxy (Command Line)

```bash
# Start SITL simulator (builds automatically)
Tools/autotest/sim_vehicle.py -v ArduCopter --no-mavproxy --out=tcpin:0.0.0.0:5760 &

# Wait a few seconds for build and startup, then connect with MAVProxy
mavproxy.py --master=tcp:127.0.0.1:5760

# Common MAVProxy commands
status              # Check vehicle status
mode GUIDED         # Change to GUIDED mode
arm throttle force  # Force arm (bypasses PreArm checks)
takeoff 10          # Takeoff to 10 meters
mode LAND           # Land the vehicle

# Stop simulator when done
pkill arducopter
```

---

## Prerequisites

### Required Python Packages

```bash
# Core dependencies
python3 -m pip install --break-system-packages empy==3.3.4
python3 -m pip install --break-system-packages pexpect
python3 -m pip install --break-system-packages MAVProxy
python3 -m pip install --break-system-packages future
python3 -m pip install --break-system-packages gnureadline

# Optional (for MAVProxy map/console/graph modules)
python3 -m pip install --break-system-packages pygame matplotlib wxPython
```

**Note**: Use `--break-system-packages` on macOS to bypass PEP 668 restrictions.

**MAVProxy Modules:**
- `pygame` + `matplotlib` - Required for map and graph modules
- `wxPython` - Required for console module (GUI interface)

### Git Submodules

```bash
git submodule update --init --recursive
```

## Building and Running

### Method 1: Using sim_vehicle.py (Recommended)

Automatically configures, builds, and launches:

```bash
# Basic start with MAVProxy
Tools/autotest/sim_vehicle.py -v ArduCopter

# Start without MAVProxy (for connecting other GCS)
Tools/autotest/sim_vehicle.py -v ArduCopter --no-mavproxy --out=tcpin:0.0.0.0:5760

# With console and map
Tools/autotest/sim_vehicle.py -v ArduCopter --console --map
```

### Method 2: Manual Build and Run

```bash
# Configure and build
./waf configure --board sitl
./waf copter

# Run simulator
./build/sitl/bin/arducopter --model + --speedup 1 --defaults Tools/autotest/default_params/copter.parm
```

## Connecting Ground Control Stations

### MAVProxy

```bash
# Basic connection
mavproxy.py --master=tcp:127.0.0.1:5760

# With visualization modules
mavproxy.py --master=tcp:127.0.0.1:5760 --console --map

# Forward to additional outputs
mavproxy.py --master=tcp:127.0.0.1:5760 --out=udp:127.0.0.1:14550
```

**Common Commands:**
```
status                    # Check vehicle status
mode GUIDED               # Change flight mode
arm throttle force        # Force arm (SITL only)
takeoff 10                # Takeoff to altitude (meters)
mode LAND                 # Land
param show ARMING_*       # Show parameters
watch ATTITUDE            # Monitor telemetry
```

### QGroundControl (Recommended - Best 3D Visualization)

**Installation:**
```bash
# macOS
brew install --cask qgroundcontrol
# Or download from https://qgroundcontrol.com/

# Linux
# Download AppImage from https://qgroundcontrol.com/

# Windows
# Download installer from https://qgroundcontrol.com/
```

**Starting SITL for QGroundControl:**
```bash
# Option 1: Simple - Just SITL (QGC connects to TCP 5760)
Tools/autotest/sim_vehicle.py -v ArduCopter --no-mavproxy

# Option 2: With MAVProxy too (QGC connects to UDP 14550)
Tools/autotest/sim_vehicle.py -v ArduCopter
```

**Connecting QGroundControl:**

1. **Automatic connection (easiest):**
   - QGC auto-detects SITL on `127.0.0.1:5760`
   - Just open QGC and it should connect automatically

2. **Manual connection (if auto-detect fails):**
   - Open QGC → Click "Q" icon (top-left)
   - Select "Application Settings"
   - Go to "Comm Links" tab
   - Click "Add" button
   - Name: "SITL"
   - Type: "TCP"
   - Server Address: `127.0.0.1`
   - Port: `5760`
   - Click "OK" then "Connect"

3. **Via MAVProxy UDP (if using MAVProxy):**
   - Type: "UDP"
   - Port: `14550`
   - Click "OK" then "Connect"

**Using QGroundControl:**

1. **Main View:**
   - Top bar: Flight mode, battery, GPS, telemetry
   - Center: Map with vehicle position
   - Bottom: Flight instruments (artificial horizon, compass, altitude, speed)

2. **3D Visualization:**
   - Click the "3D" button (usually top-right of map area)
   - Shows 3D representation of vehicle with attitude
   - Visualizes pitch, roll, yaw in real-time

3. **Flying the Vehicle:**
   - Click "Fly" tab (left sidebar)
   - Change mode to "GUIDED" (via flight mode selector at top)
   - Click "Arm" button
   - Click "Takeoff" button
   - Enter altitude (e.g., 10 meters)
   - Click "Takeoff" to confirm
   - Click anywhere on map to fly to that location
   - Click "Land" when finished

4. **Mission Planning:**
   - Click "Plan" tab
   - Click on map to add waypoints
   - Set altitude and actions for each waypoint
   - Upload mission to vehicle
   - Switch to AUTO mode to execute

5. **Vehicle Setup:**
   - Click "Setup" tab
   - Access parameters, calibration, firmware updates
   - Configure vehicle-specific settings

**Features:**
- 3D flight display with real-time attitude
- Interactive satellite map (Google Maps/Mapbox)
- Mission planning with visual waypoint editing
- Parameter management with search and descriptions
- Real-time telemetry graphs
- Video streaming support (if configured)
- Log download and basic analysis
- Multi-vehicle support

**QGroundControl Tips:**
- Press 'F' to toggle fullscreen
- Right-click on map for more options
- Use mouse wheel to zoom map
- Press 'M' to cycle through map types
- Check "Analyze Tools" → "Mavlink Inspector" to see all messages

### Mission Planner (Windows)

1. Download from https://ardupilot.org/planner/
2. Select `TCP` from connection dropdown
3. Click `Connect`, enter `127.0.0.1` and port `5760`

## Controlling the Vehicle in MAVProxy

Once connected and armed, you can control the vehicle using various methods.

### Method 1: GUIDED Mode Commands

GUIDED mode allows you to command the vehicle to specific GPS coordinates:

```bash
# Change to GUIDED mode
mode GUIDED

# Arm and takeoff
arm throttle force
takeoff 10

# Fly to GPS coordinates (lat, lon, altitude_in_meters)
guided -35.362262 149.165237 15

# Fly in a square pattern to see movement on map
guided -35.362262 149.165237 15   # North
guided -35.362262 149.165337 15   # North-East
guided -35.363262 149.165337 15   # South-East
guided -35.363262 149.165237 15   # Back to start

# Land
mode LAND
```

### Method 2: RC Override (Manual Control)

Control the vehicle directly like with an RC transmitter:

```bash
# RC channel values: 1000-2000 (1500 is center/neutral)
# Channel 1: Roll (left/right)
# Channel 2: Pitch (forward/backward)
# Channel 3: Throttle (up/down)
# Channel 4: Yaw (rotate)

# Move forward
rc 2 1600

# Move backward
rc 2 1400

# Move right (roll right)
rc 1 1600

# Move left (roll left)
rc 1 1400

# Rotate clockwise
rc 4 1600

# Rotate counter-clockwise
rc 4 1400

# Return to neutral (stop movement)
rc 1 1500
rc 2 1500
rc 4 1500
```

**Tip:** Start with small changes (1550-1600) and observe the effect before making larger inputs.

### Method 3: Waypoint Missions

Create and execute automated missions:

```bash
# Switch to AUTO mode for missions
mode AUTO

# Clear existing waypoints
wp clear

# Add waypoints (lat, lon, altitude)
wp add -35.362262 149.165237 20
wp add -35.362262 149.165337 20
wp add -35.363262 149.165337 20
wp add -35.363262 149.165237 20

# List waypoints to verify
wp list

# Set current waypoint
wp set 1

# Vehicle will automatically fly the mission in AUTO mode
```

**Mission Commands:**
```bash
wp load /path/to/mission.txt   # Load mission from file
wp save /path/to/mission.txt   # Save current mission
wp clear                        # Clear all waypoints
wp list                         # Show all waypoints
wp set N                        # Jump to waypoint N
```

### Method 4: Position Control (LOITER Mode)

```bash
# Switch to LOITER mode (holds position)
mode LOITER

# Use RC override to move
rc 2 1600  # Move forward
rc 1 1600  # Move right

# Vehicle will hold new position when RC returns to neutral
rc 1 1500
rc 2 1500
```

### Monitoring Vehicle Movement

Track the vehicle's position and movement in real-time:

```bash
# Watch GPS position updates
watch GLOBAL_POSITION_INT

# Watch speed, altitude, and heading
watch VFR_HUD

# Watch attitude (roll, pitch, yaw)
watch ATTITUDE

# Clear all watches
watch clear

# List available message types
watch list
```

### Quick Movement Test

Try this sequence to see the vehicle move on the map:

```bash
# Ensure you're in GUIDED mode and airborne
mode GUIDED
arm throttle force
takeoff 10

# Wait for takeoff to complete, then fly in a square
guided -35.362262 149.165237 15
# (Wait ~10 seconds for movement)
guided -35.362262 149.165337 15
# (Wait ~10 seconds)
guided -35.363262 149.165337 15
# (Wait ~10 seconds)
guided -35.363262 149.165237 15

# Land when done
mode LAND
```

### Visualization Tips

**Enable map module:**
```bash
module load map
```

**Enable console module (instruments):**
```bash
module load console
```

**Start MAVProxy with modules:**
```bash
mavproxy.py --master=tcp:127.0.0.1:5760 --console --map
```

The map will automatically center on the vehicle and show its track as it moves.

## Network Ports

| Port | Purpose | Protocol |
|------|---------|----------|
| 5760 | SERIAL0 (primary MAVLink) | TCP |
| 5762 | SERIAL1 | TCP |
| 5763 | SERIAL2 | TCP |
| 5501 | SITL control interface | TCP |
| 14550 | MAVProxy UDP output | UDP |

## Managing the Simulator

```bash
# Check if running
ps aux | grep arducopter | grep -v grep
lsof -i -P | grep 5760

# View logs
tail -f /tmp/ArduCopter.log

# Stop simulator
pkill arducopter
```

## Troubleshooting

### MAVProxy Module Warnings

**Warning messages:**
```
Failed to load module: No module named 'console'
Failed to load module: No module named 'map'
```

**Solution:** Install the optional visualization dependencies:
```bash
python3 -m pip install --break-system-packages wxPython pygame matplotlib
```

**What each package provides:**
- `wxPython` - Enables console module (GUI interface with instruments)
- `pygame` + `matplotlib` - Enables map and graph modules

**Note:** If you don't need visualization, these warnings are harmless and can be ignored. Core MAVProxy functionality (commands, telemetry, parameters) works perfectly without them.

### Build Errors

**"No module named 'empy'":**
```bash
python3 -m pip install --break-system-packages empy==3.3.4
```

**"No module named 'pexpect'":**
```bash
python3 -m pip install --break-system-packages pexpect
```

**"source not found: 'modules/littlefs/lfs.c'":**
```bash
git submodule update --init --recursive
```

### Connection Issues

**QGroundControl shows "Disconnected":**

This can happen when MAVProxy and QGC both try to connect simultaneously.

**Solution**: Start simulator without MAVProxy:
```bash
# Kill all existing processes
pkill -f sim_vehicle
pkill -f mavproxy
pkill -9 arducopter

# Start simulator only (no MAVProxy)
Tools/autotest/sim_vehicle.py -v ArduCopter --no-mavproxy --out=tcpin:0.0.0.0:5760 &

# Now connect QGC to tcp://127.0.0.1:5760
```

**Alternative**: Use MAVProxy as proxy:
```bash
# Start with MAVProxy
Tools/autotest/sim_vehicle.py -v ArduCopter

# Connect QGC to UDP: 127.0.0.1:14550
```

### Simulator Crashes on macOS

If the simulator crashes immediately when clients connect:

**Symptoms:**
- Log shows: "Connection on serial port 5760" → "Closed connection on SERIAL0"
- MAVProxy exits immediately

**Possible Solutions:**

1. **Try a stable release:**
```bash
git checkout Copter-4.3.0
./waf distclean
./waf configure --board sitl
./waf copter
```

2. **Rebuild from scratch:**
```bash
./waf distclean
rm -rf build/
./waf configure --board sitl --debug
./waf copter
```

3. **Check for crash reports:**
```bash
ls ~/Library/Logs/DiagnosticReports/ | grep arducopter
```

4. **Use debugger for investigation:**
```bash
lldb ./build/sitl/bin/arducopter -- --model + --speedup 1 --defaults Tools/autotest/default_params/copter.parm
```

## Docker SITL (Alternative)

If local builds have issues, you can use Docker:

### Using Official ArduPilot Docker Image

```bash
# Pull the development image
docker pull ardupilot/ardupilot-dev-chibios:latest

# Run SITL in container (mount your local source)
docker run --rm -it \
  -v $(pwd):/ardupilot \
  -w /ardupilot \
  -p 5760:5760 \
  -p 14550:14550/udp \
  ardupilot/ardupilot-dev-chibios:latest \
  bash

# Inside container:
./waf configure --board sitl
./waf copter
Tools/autotest/sim_vehicle.py -v ArduCopter --out=udp:0.0.0.0:14550
```

### Pre-configured SITL Container

```bash
# Run with sim_vehicle.py directly
docker run --rm -it \
  -v $(pwd):/ardupilot \
  -w /ardupilot \
  -p 5760:5760 \
  -p 14550:14550/udp \
  ardupilot/ardupilot-dev-chibios:latest \
  bash -c "Tools/autotest/sim_vehicle.py -v ArduCopter --out=udp:0.0.0.0:14550"

# Connect from host:
# - MAVProxy: mavproxy.py --master=udp:127.0.0.1:14550
# - QGC: UDP connection to 127.0.0.1:14550
```

**Note**: The Docker image is primarily a build environment. You need to mount your local ArduPilot source code.

## Visualization Options

Beyond the basic MAVProxy 2D map, there are several visualization options for SITL.

### 1. MAVProxy Built-in Modules (Already Working!)

**Map Module (2D Map)** - You're using this!
```bash
module load map
```
- Vehicle position and track
- Waypoints and mission path
- Home location marker
- Geofence boundaries

**Console Module (Instrument Panel)**
```bash
module load console
```
- Real-time artificial horizon
- Altitude and climb rate gauges
- Speed indicators (ground/air)
- Battery voltage and current
- GPS status and satellite count
- Flight mode display
- Compass heading

**Graph Module (Real-time Plotting)**
```bash
module load graph

# Plot specific values
graph ATTITUDE.roll ATTITUDE.pitch
graph VFR_HUD.alt VFR_HUD.climb
graph BATTERY_STATUS.current_battery
```
- Live telemetry graphs
- Multiple parameters on same plot
- Historical data visualization

### 2. QGroundControl (Recommended Full-Featured GCS)

**Best for:** Complete ground control station experience with modern UI

**Installation:**
```bash
# Download from https://qgroundcontrol.com/
# macOS: Download QGroundControl.dmg
```

**Connection:**
- Auto-detects SITL on `127.0.0.1:5760` (if MAVProxy not connected)
- Or connect via MAVProxy UDP: `127.0.0.1:14550`

**Features:**
- 3D flight display with attitude indicator
- Interactive satellite map (Google/Mapbox)
- Mission planning and editing
- Parameter editor with descriptions
- Real-time telemetry charts
- Log download and analysis
- Video streaming support
- Multi-vehicle management

**Setup with running MAVProxy:**
```bash
# MAVProxy forwards to UDP 14550 automatically
# In QGC: Application Settings → Comm Links → Add
# Type: UDP, Host: 127.0.0.1, Port: 14550
```

### 3. Mission Planner (Windows - Most Feature-Rich)

**Best for:** Advanced configuration, tuning, and analysis

**Installation:**
- Windows: Download from https://ardupilot.org/planner/
- macOS/Linux: Can run via Wine

**Features:**
- Comprehensive mission planning
- Full HUD with artificial horizon
- Advanced parameter management
- Auto-tune wizards
- Log analysis tools (detailed graphs)
- Configuration wizards for vehicle setup
- Simulation interface
- Advanced PID tuning tools

**Connection:**
```bash
# Select TCP, enter 127.0.0.1:5760
# Or UDP 127.0.0.1:14550 if using MAVProxy
```

### 4. FlightGear 3D Visualization (Realistic 3D)

**Best for:** Photorealistic aircraft visualization

**Installation:**
```bash
# Install FlightGear
brew install --cask flightgear  # macOS
# Or download from https://www.flightgear.org/
```

**Start SITL with FlightGear:**
```bash
# Basic copter
Tools/autotest/sim_vehicle.py -v ArduCopter -f quad

# With MAVProxy console and map
Tools/autotest/sim_vehicle.py -v ArduCopter -f quad --console --map

# Different aircraft models
Tools/autotest/sim_vehicle.py -v ArduCopter -f octa
Tools/autotest/sim_vehicle.py -v ArduPlane -f plane
```

**Features:**
- Photorealistic 3D rendering
- Environmental effects (weather, time of day)
- Cockpit view and external views
- Realistic physics visualization
- Multiple camera angles

### 5. Gazebo Simulation (Advanced Physics)

**Best for:** Multi-robot scenarios, realistic sensors, computer vision

**Setup:**
```bash
# Install Gazebo
brew install gazebo  # macOS
# Or follow https://gazebosim.org/docs
```

**Features:**
- High-fidelity physics simulation
- Realistic sensor simulation (LIDAR, cameras, GPS)
- Multiple vehicle support
- ROS integration
- Custom world environments
- Collision detection

### 6. Web-based Visualization

**MAVProxy WebTools Module:**
```bash
# Load in MAVProxy
module load webtools

# Access via browser
# http://127.0.0.1:8000
```

**Features:**
- Web-based interface
- Basic telemetry display
- Command interface
- No installation needed
- Remote access capability

### 7. Custom Python Scripts (pymavlink)

**For developers:** Create custom visualizations

```python
from pymavlink import mavutil
import matplotlib.pyplot as plt

# Connect to SITL
master = mavutil.mavlink_connection('tcp:127.0.0.1:5760')
master.wait_heartbeat()

# Read and plot telemetry
while True:
    msg = master.recv_match(type='ATTITUDE', blocking=True)
    if msg:
        print(f"Roll: {msg.roll}, Pitch: {msg.pitch}, Yaw: {msg.yaw}")
```

### Comparison Table

| Tool | Complexity | Features | Best For | Platform |
|------|-----------|----------|----------|----------|
| MAVProxy Map | Easy | 2D map, basic | Quick testing | All |
| MAVProxy Console | Easy | Instruments | Terminal users | All |
| QGroundControl | Easy | Modern GCS | General use | All |
| Mission Planner | Medium | Most complete | Advanced config | Windows |
| FlightGear | Medium | 3D visual | Realistic sim | All |
| Gazebo | Hard | Physics/sensors | Research/dev | Linux/macOS |
| Web Tools | Easy | Browser UI | Remote access | All |

### Recommended Combinations

**For beginners:**
```bash
# MAVProxy with map and console
mavproxy.py --master=tcp:127.0.0.1:5760 --console --map
```

**For mission planning:**
```bash
# Use QGroundControl or Mission Planner
# Connect to 127.0.0.1:5760 (or :14550 via MAVProxy)
```

**For realistic visualization:**
```bash
# FlightGear + MAVProxy
Tools/autotest/sim_vehicle.py -v ArduCopter -f quad --console --map
```

**For development/testing:**
```bash
# MAVProxy + custom Python scripts
mavproxy.py --master=tcp:127.0.0.1:5760
# Run your Python script separately
```

### Quick Setup: Multiple Visualizations at Once

You can run multiple GCS/visualization tools simultaneously:

```bash
# 1. Start SITL with MAVProxy
Tools/autotest/sim_vehicle.py -v ArduCopter --console --map

# 2. MAVProxy automatically forwards to UDP :14550
# 3. Connect QGroundControl to UDP 127.0.0.1:14550
# 4. Now you have MAVProxy map + QGC running together!
```

**Or use multiple outputs:**
```bash
mavproxy.py --master=tcp:127.0.0.1:5760 \
  --out=udp:127.0.0.1:14550 \
  --out=udp:127.0.0.1:14551 \
  --console --map

# QGC on :14550
# Mission Planner on :14551
```

## Advanced Usage

### Running Specific Vehicles

```bash
Tools/autotest/sim_vehicle.py -v ArduPlane
Tools/autotest/sim_vehicle.py -v Rover
Tools/autotest/sim_vehicle.py -v ArduSub
```

### Custom Location

```bash
# Use predefined location
Tools/autotest/sim_vehicle.py -v ArduCopter -L CMAC

# Custom coordinates (lat,lng,alt,heading)
Tools/autotest/sim_vehicle.py -v ArduCopter -L 37.7749,-122.4194,10,0
```

### Speed Control

```bash
# Run at 2x speed
Tools/autotest/sim_vehicle.py -v ArduCopter --speedup 2

# Run as fast as possible
Tools/autotest/sim_vehicle.py -v ArduCopter --speedup 0
```

### Debug Build

```bash
./waf configure --board sitl --debug
./waf copter

# Run with GDB
gdb --args ./build/sitl/bin/arducopter --model + --speedup 1
```

### FlightGear 3D Visualization

```bash
# Requires FlightGear installed
Tools/autotest/sim_vehicle.py -v ArduCopter -f quad --console --map
```

## Development Workflow

1. **Make code changes** in `ArduCopter/` or `libraries/`

2. **Rebuild** (incremental, fast):
```bash
./waf copter
```

3. **Test in SITL**:
```bash
Tools/autotest/sim_vehicle.py -v ArduCopter
```

4. **Debug** using:
   - MAVProxy console commands
   - Log file analysis (`/tmp/ArduCopter.log`)
   - GDB debugger (with `--debug` build)

## Testing

### Quick Functionality Test

```bash
# In terminal 1: Start simulator
Tools/autotest/sim_vehicle.py -v ArduCopter

# In terminal 2: Connect and test
mavproxy.py --master=tcp:127.0.0.1:5760

# In MAVProxy:
status
mode GUIDED
arm throttle force
takeoff 10
mode LAND
```

### Automated Tests

```bash
# Run all copter tests
Tools/autotest/autotest.py build.Copter test.Copter

# Run specific test
Tools/autotest/autotest.py test.Copter.ArmFeatures
```

## Resources

- **ArduPilot Dev Docs**: https://ardupilot.org/dev/
- **SITL Documentation**: https://ardupilot.org/dev/docs/sitl-simulator-software-in-the-loop.html
- **MAVLink Protocol**: https://mavlink.io/
- **MAVProxy Docs**: https://ardupilot.org/mavproxy/
- **Discussion Forum**: https://discuss.ardupilot.org/
- **GitHub Issues**: https://github.com/ArduPilot/ardupilot/issues

## Summary

SITL provides a complete flight simulator for ArduPilot development:
- ✓ No hardware required
- ✓ Fast iteration cycles
- ✓ Safe testing environment
- ✓ Full sensor simulation
- ✓ Compatible with all ground control stations
- ✓ Supports all vehicle types

The recommended workflow is to use `sim_vehicle.py` which handles configuration, building, and launching automatically.
