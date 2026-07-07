ROOT = $(dir $(lastword $(MAKEFILE_LIST)))

WAF_BINARY = $(realpath $(ROOT)/modules/waf/waf-light)
WAF = python $(WAF_BINARY) $(WAF_FLAGS)

EXPLICIT_COMMANDS = check check-all clean list_boards

VEHICLES = copter plane rover sub heli

BOARD_LIST := $(shell $(WAF) list_boards | head -1)

all: help

$(WAF_BINARY):
	@git submodule init && git submodule update

waf-%: $(WAF_BINARY)
	@$(WAF) $*

%-configure: $(WAF_BINARY)
	@$(WAF) configure --board $*

$(EXPLICIT_COMMANDS): $(WAF_BINARY)
	@$(WAF) $@

$(VEHICLES): $(WAF_BINARY)
	@echo Build for vehicle $@
	@$(WAF) $@

.DEFAULT: %-configure
	@$(WAF) configure --board $@ build

define target_template
$(1)-$(2) : $(1)-configure $(2)
endef

$(foreach board,$(BOARD_LIST),$(foreach vehicle,$(VEHICLES),$(eval $(call target_template,$(board),$(vehicle)))))

help:
	@echo "Ardupilot Building"
	@echo "=================="
	@echo "This is a make wrapper for Ardupilot's Waf build system. This wrapper is"
	@echo "intended to provide convenience for basic and common build tasks. If you need"
	@echo "more than what this wrapper provides, it's a good idea to use waf directly."
	@echo "The waf executable is at '$(WAF_BINARY)'."
	@echo ""
	@echo "For more detailed instructions see https://ardupilot.org/dev/docs/building-the-code.html"
	@echo ""
	@echo "Boards"
	@echo "------"
	@echo ""
	@echo "In order to trigger the build for a board/platform, the name of the board is"
	@echo "used as the target. Example: make linux"
	@echo "If no target is passed, then the build will be triggered for the last board"
	@echo "used. You can suffix the board/platform with '-configure' in order to just "
	@echo "configure without triggering a build command."
	@echo ""
	@echo "You can get a list of available boards using the command:"
	@echo "    make list_boards"
	@echo ""
	@echo "Vehicles"
	@echo "--------"
	@echo ""
	@echo "It's possible to build for a specific vehicle by defining the target as one of:"
	@echo "    $(VEHICLES)"
	@echo ""
	@echo "Not that if it's your first time building or you want to change the target "
	@echo "board/platform, you'll need to configure the build before (e.g"
	@echo "make linux-configure)"
	@echo ""
	@echo "Combinations"
	@echo "------------"
	@echo ""
	@echo "It's possible to build for a specific vehicle type and board using"
	@echo "    make BOARD-VEHICLE"
	@echo ""
	@echo "For example, to build copter for the Pixracer, use this:"
	@echo "    make Pixracer-copter"
	@echo ""
	@echo "Check"
	@echo "-----"
	@echo ""
	@echo "Check targets are used for running tests. There are two targets available:"
	@echo "    check:	 for running tests that are still failing or that are new or"
	@echo "    		   have been modified"
	@echo "    check-all: to run all tests"
	@echo ""
	@echo "Waf commands"
	@echo "------------"
	@echo ""
	@echo "Waf commands can be explicitly called with targets prefixed by 'waf-'. Example:"
	@echo "    make waf-clean"
	@echo "    make waf-build"
	@echo ""
	@echo "Common commands"
	@echo "---------------"
	@echo ""
	@echo "Some Waf commands can be executed without the need of prefixing the target name"
	@echo "with 'waf-'. They are: $(EXPLICIT_COMMANDS)"
	@echo ""
	@echo "Waf flags"
	@echo "---------"
	@echo ""
	@echo "The variable WAF_FLAGS can be used to set any waf command line options that"
	@echo "come to be necessary. Ex: make linux WAF_FLAGS='-c no'"
	@echo ""

	@echo "SITL Dev Shortcuts"
	@echo "------------------"
	@echo ""
	@echo "Convenience targets for local ArduCopter SITL development:"
	@echo "    make setup      Install Python deps, restore MAVLink headers, configure sitl"
	@echo "    make setup-gui  Install MAVProxy console/map deps (wxPython, pygame, matplotlib, opencv)"
	@echo "    make build      Build ArduCopter SITL (auto-configures if needed)"
	@echo "    make test       Run the unit-test suite (waf check)"
	@echo "    make sitl       Launch SITL (MAVProxy Option 2; listens on TCP 5760)"
	@echo "    make sitl-gui   Launch SITL with MAVProxy console + map (needs 'make setup-gui')"
	@echo "    make mavproxy   Connect MAVProxy to a running SITL"
	@echo "    make fly        Self-contained smoke test: SITL + arm + takeoff 10m"
	@echo "    make stop       Kill running SITL / MAVProxy processes"
	@echo "    make distclean  Remove all build artifacts (all boards)"
	@echo ""

# ---------------------------------------------------------------------------
# SITL development convenience targets (see 'make help').
# BOARD/vehicle default to sitl/copter; override BOARD=... if needed.
# ---------------------------------------------------------------------------
BOARD ?= sitl
PYTHON ?= python3
SITL_MASTER ?= tcp:127.0.0.1:5760
SITL_OUT ?= tcpin:0.0.0.0:5760
SETUP_PKGS = empy==3.3.4 pexpect future MAVProxy pymavlink dronecan gnureadline
# Extra deps for MAVProxy's console (wxPython) and map (pygame, matplotlib,
# opencv-python) modules. Kept out of `setup` because wxPython can be a slow
# source build.
VIZ_PKGS = pygame matplotlib wxPython opencv-python
# MAVProxy modules launched by `make sitl-gui`; override to taste,
# e.g. `make sitl-gui GUI_MODULES=--map`.
GUI_MODULES ?= --console --map

.PHONY: setup setup-gui build test sitl sitl-gui mavproxy fly stop distclean

setup:
	@echo ">> Installing Python dependencies ..."
	@$(PYTHON) -m pip install $(SETUP_PKGS) \
		|| $(PYTHON) -m pip install --break-system-packages $(SETUP_PKGS)
	@echo ">> Restoring gitignored MAVLink fixed C headers (needed by mavgen) ..."
	@PYMAVLINK_C=$$($(PYTHON) -c "import pymavlink, os; print(os.path.join(os.path.dirname(pymavlink.__file__), 'generator', 'C'))"); \
		DST="$(ROOT)/modules/mavlink/pymavlink/generator/C"; \
		mkdir -p "$$DST"; \
		cp -R "$$PYMAVLINK_C/." "$$DST/"; \
		echo "   restored: $$(ls "$$DST"/include_v2.0 | tr '\n' ' ')"
	@echo ">> Configuring waf for board $(BOARD) ..."
	@$(WAF) configure --board $(BOARD)
	@echo ">> Setup complete. Run 'make build'."

setup-gui:
	@echo ">> Installing MAVProxy console/map deps ($(VIZ_PKGS)) ..."
	@$(PYTHON) -m pip install $(VIZ_PKGS) \
		|| $(PYTHON) -m pip install --break-system-packages $(VIZ_PKGS)
	@echo ">> GUI deps installed. Run 'make sitl-gui'."

build: $(WAF_BINARY)
	@test -f "$(ROOT)/build/c4che/_cache.py" || $(WAF) configure --board $(BOARD)
	@$(WAF) copter

test: $(WAF_BINARY)
	@$(WAF) check

sitl:
	@$(ROOT)/Tools/autotest/sim_vehicle.py -v ArduCopter --no-mavproxy --out=$(SITL_OUT)

sitl-gui:
	@$(ROOT)/Tools/autotest/sim_vehicle.py -v ArduCopter $(GUI_MODULES)

mavproxy:
	@mavproxy.py --master=$(SITL_MASTER)

fly: $(WAF_BINARY)
	@$(PYTHON) $(ROOT)/Tools/sitl_smoke_test.py

stop:
	-@pkill -f sim_vehicle.py 2>/dev/null || true
	-@pkill -f mavproxy.py 2>/dev/null || true
	-@pkill -9 arducopter 2>/dev/null || true
	@echo ">> Stopped SITL / MAVProxy."

distclean: $(WAF_BINARY)
	@$(WAF) distclean

# Don't run in parallel, let waf take care of that.
.NOTPARALLEL:
