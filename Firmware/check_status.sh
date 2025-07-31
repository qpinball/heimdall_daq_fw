#!/bin/bash
#
# Quick Heimdall DAQ and Kraken SDR Status Checker
#
# This script provides a quick overview of:
# 1. Heimdall DAQ processes
# 2. Kraken SDR device connections
# 3. Network ports
# 4. Basic system status

echo "=== Heimdall DAQ & Kraken SDR Status Check ==="
echo "Timestamp: $(date)"
echo

# Check Heimdall DAQ processes
echo "🔧 Heimdall DAQ Processes:"
# Core processes that should always be running
core_processes=("rtl_daq.out" "rebuffer.out" "decimate.out" "delay_sync.py" "hw_controller.py")
# Optional processes (only needed for Ethernet mode)
optional_processes=("iq_server.out")

all_core_processes_running=true
for process in "${core_processes[@]}"; do
    if pgrep -f "$process" > /dev/null; then
        echo "   ✅ $process"
    else
        echo "   ❌ $process"
        all_core_processes_running=false
    fi
done

# Check optional processes
for process in "${optional_processes[@]}"; do
    if pgrep -f "$process" > /dev/null; then
        echo "   ✅ $process (Ethernet mode)"
    else
        echo "   ⚪ $process (not needed in shared memory mode)"
    fi
done

echo

# Check Kraken SDR devices
echo "📡 Kraken SDR Devices:"
device_count=$(lsusb | grep -c "RTL2838 DVB-T")
echo "   Devices Found: $device_count/5"

if [ $device_count -ge 5 ]; then
    echo "   ✅ All devices connected"
    kraken_connected=true
else
    echo "   ❌ Missing devices"
    kraken_connected=false
fi

echo

# Check network ports
echo "🌐 Network Ports:"
port_5000_active=false
port_5001_active=false

if lsof -i:5000 >/dev/null 2>&1; then
    echo "   ✅ Port 5000 (IQ Server) - Active (Ethernet mode)"
    port_5000_active=true
else
    echo "   ⚪ Port 5000 (IQ Server) - Not needed in shared memory mode"
fi

if lsof -i:5001 >/dev/null 2>&1 || ss -tlnp | grep -q ":5001"; then
    echo "   ✅ Port 5001 (HW Controller) - Active"
    port_5001_active=true
else
    echo "   ❌ Port 5001 (HW Controller) - Not active"
fi

echo



# Overall status
echo "📊 Overall Status:"
if [ "$all_core_processes_running" = true ] && [ "$kraken_connected" = true ] && [ "$port_5001_active" = true ]; then
    echo "   🟢 ALL SYSTEMS GO - Heimdall is running and Kraken is connected!"
    echo "   📡 Mode: Shared Memory (local processing)"
else
    echo "   🔴 SYSTEM ISSUES DETECTED:"
    if [ "$all_core_processes_running" = false ]; then
        echo "      - Some core Heimdall processes are not running"
    fi
    if [ "$kraken_connected" = false ]; then
        echo "      - Kraken SDR devices not fully connected"
    fi
    if [ "$port_5001_active" = false ]; then
        echo "      - Hardware controller service is not active"
    fi
fi

echo
echo "=========================================="

# Optional: Show detailed device information
if [ "$1" = "--verbose" ] || [ "$1" = "-v" ]; then
    echo
    echo "📋 Detailed Device Information:"
    lsusb | grep "Realtek"
    
    echo
    echo "🔍 Process Details:"
    ps aux | grep -E "(rtl_daq|rebuffer|decimate|delay_sync|hw_controller|iq_server)" | grep -v grep
fi 