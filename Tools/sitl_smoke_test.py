#!/usr/bin/env python3
"""Self-contained ArduCopter SITL smoke test.

Launches SITL, connects over MAVLink, waits for a position estimate, switches
to GUIDED, force-arms, takes off to a target altitude, asserts the altitude is
reached, then tears everything down.

Exit code 0 on success, non-zero on failure. Used by `make fly` and suitable
for CI. Overridable via env vars: SITL_MASTER, SITL_OUT, SMOKE_TARGET_ALT.
"""

import os
import signal
import socket
import subprocess
import sys
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MASTER = os.environ.get("SITL_MASTER", "tcp:127.0.0.1:5760")
OUT = os.environ.get("SITL_OUT", "tcpin:0.0.0.0:5760")
TARGET_ALT = float(os.environ.get("SMOKE_TARGET_ALT", "10"))
SITL_LOG = "/tmp/sitl_fly.log"


def log(msg):
    print("[smoke] %s" % msg, flush=True)


def start_sitl():
    log("starting SITL (log: %s) ..." % SITL_LOG)
    logf = open(SITL_LOG, "w")
    return subprocess.Popen(
        [sys.executable, "Tools/autotest/sim_vehicle.py", "-v", "ArduCopter",
         "--no-mavproxy", "--out=" + OUT],
        cwd=ROOT, stdout=logf, stderr=subprocess.STDOUT, preexec_fn=os.setsid)


def stop_sitl(proc):
    log("stopping SITL ...")
    try:
        os.killpg(os.getpgid(proc.pid), signal.SIGTERM)
    except (ProcessLookupError, PermissionError):
        pass
    # belt-and-suspenders: sim_vehicle spawns a detached arducopter
    subprocess.call(["pkill", "-f", "sim_vehicle.py"])
    subprocess.call(["pkill", "-9", "arducopter"])


def wait_port(host="127.0.0.1", port=5760, timeout=240):
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            socket.create_connection((host, port), 2).close()
            return True
        except OSError:
            time.sleep(2)
    return False


def wait_ack(m, cmd, timeout):
    deadline = time.time() + timeout
    while time.time() < deadline:
        msg = m.recv_match(type="COMMAND_ACK", blocking=True, timeout=timeout)
        if msg and msg.command == cmd:
            return msg.result
    return None


def wait_ekf_ready(m, mavutil, timeout=150):
    """GUIDED takeoff needs a converged EKF (stable origin + horizontal
    position), which the SITL GPS reaches ~40s after boot. Force-arming
    bypasses prearm but NOT this, so a too-early takeoff is rejected."""
    ml = mavutil.mavlink
    need = (ml.ESTIMATOR_ATTITUDE | ml.ESTIMATOR_VELOCITY_HORIZ |
            ml.ESTIMATOR_POS_HORIZ_REL | ml.ESTIMATOR_POS_HORIZ_ABS |
            ml.ESTIMATOR_PRED_POS_HORIZ_ABS)
    deadline = time.time() + timeout
    while time.time() < deadline:
        e = m.recv_match(type="EKF_STATUS_REPORT", blocking=True, timeout=5)
        if e and (e.flags & need) == need:
            return True
    return False


def confirm_guided(m, tries=15):
    """Set GUIDED and confirm via the newest heartbeat (draining stale ones)."""
    for _ in range(tries):
        m.set_mode_apm("GUIDED")
        time.sleep(1)
        hb = None
        while True:
            x = m.recv_match(type="HEARTBEAT", blocking=(hb is None), timeout=5)
            if x is None:
                break
            hb = x
        if hb and hb.custom_mode == 4:  # 4 == GUIDED (ArduCopter)
            return True
    return False


def arm(m, mavutil, timeout=150):
    """Force-arm, retrying until accepted. Force does NOT bypass the
    position-estimate prearm, so retrying also waits out EKF/GPS convergence."""
    deadline = time.time() + timeout
    while time.time() < deadline:
        m.mav.command_long_send(
            m.target_system, m.target_component,
            mavutil.mavlink.MAV_CMD_COMPONENT_ARM_DISARM, 0,
            1, 21196, 0, 0, 0, 0, 0)  # param2=21196 -> force
        if wait_ack(m, mavutil.mavlink.MAV_CMD_COMPONENT_ARM_DISARM, 3) == \
                mavutil.mavlink.MAV_RESULT_ACCEPTED:
            return True
        time.sleep(2)
    return False


def takeoff(m, mavutil, alt, timeout=30):
    """Send NAV_TAKEOFF, re-asserting GUIDED and retrying until the command is
    accepted. Force-armed copters auto-disarm on the ground, so takeoff must be
    accepted promptly after arming."""
    deadline = time.time() + timeout
    while time.time() < deadline:
        m.set_mode_apm("GUIDED")
        m.mav.command_long_send(
            m.target_system, m.target_component,
            mavutil.mavlink.MAV_CMD_NAV_TAKEOFF, 0, 0, 0, 0, 0, 0, 0, alt)
        if wait_ack(m, mavutil.mavlink.MAV_CMD_NAV_TAKEOFF, 3) == \
                mavutil.mavlink.MAV_RESULT_ACCEPTED:
            return True
        time.sleep(1)
    return False


def wait_alt(m, min_alt, timeout=60):
    deadline = time.time() + timeout
    last = -1.0
    next_report = time.time() + 5
    while time.time() < deadline:
        msg = m.recv_match(type="GLOBAL_POSITION_INT", blocking=True, timeout=5)
        if msg:
            last = msg.relative_alt / 1000.0
            if last >= min_alt:
                return True
        if time.time() >= next_report:
            log("  climbing... alt=%.1f m" % last)
            next_report = time.time() + 5
    log("  last altitude seen: %.1f m" % last)
    return False


def run():
    from pymavlink import mavutil

    if not wait_port():
        log("SITL never opened TCP port")
        return 1
    m = mavutil.mavlink_connection(MASTER)
    if not m.wait_heartbeat(timeout=90):
        log("no heartbeat")
        return 1
    log("heartbeat OK (sys %d)" % m.target_system)
    m.mav.request_data_stream_send(
        m.target_system, m.target_component,
        mavutil.mavlink.MAV_DATA_STREAM_ALL, 5, 1)

    log("waiting for EKF to converge (GPS/origin) ...")
    if not wait_ekf_ready(m, mavutil):
        log("EKF never became ready")
        return 1
    log("EKF ready")
    if not confirm_guided(m):
        log("could not enter GUIDED")
        return 1
    if not arm(m, mavutil):
        log("arm FAILED")
        return 1
    log("armed, commanding takeoff to %.0f m" % TARGET_ALT)
    if not takeoff(m, mavutil, TARGET_ALT):
        log("takeoff command was not accepted")
        return 1
    if not wait_alt(m, TARGET_ALT * 0.95):
        log("did NOT reach target altitude")
        return 1
    log("reached ~%.0f m  PASS" % TARGET_ALT)
    return 0


def main():
    sitl = start_sitl()
    try:
        return run()
    finally:
        stop_sitl(sitl)


if __name__ == "__main__":
    sys.exit(main())
