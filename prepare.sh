#!/bin/bash

# Disable TurboBoost.
cpuvendor=$(lscpu | grep 'Vendor ID' | egrep -o '[^ ]*$')
case "$cpuvendor" in
	"GenuineIntel") sudo echo 1 > /sys/devices/system/cpu/intel_pstate/no_turbo ;;
	"AuthenticAMD") sudo echo 0 > /sys/devices/system/cpu/cpufreq/boost ;;
esac

# Disable other cpu for avoid thread mitigation.
cpus=$(lscpu | grep '^CPU(s):' | egrep -o '[^ ]*$')
for i in $(seq 1 $((cpus-1))); do
	echo 0 | sudo tee /sys/devices/system/cpu/cpu$i/online
done

# Set scaling_governor to ‘performance’.
sudo cpupower -c 0 frequency-set -g powersave

# Drop file system cache.
echo 3 | sudo tee /proc/sys/vm/drop_caches
sync

# Disable address space randomization.
# echo 0 | sudo tee /proc/sys/kernel/randomize_va_space
# Recommeted disable per process:
#   setarch -R ...

# Run benchmarks
# sudo nice -n -5 taskset -c 1 setarch -R ...

