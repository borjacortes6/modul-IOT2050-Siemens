#!/bin/bash
# export-gpios.sh — Exporta i configura tots els GPIOs del shield IO
# Siemens 6ES7647-0KA01-0AA2 en IoT2050
#
# Mapping verificat:
#   gpio355 (IO7) = DQ1 (Borne 8)
#   gpio360 (IO8) = DQ0 (Borne 9)
#   gpio487 (IO7-direction) = controla direcció DQ1
#   gpio488 (IO8-direction) = controla direcció DQ0

echo "=== Exportant GPIOs del shield IO ==="

# Entrades digitals (DI0-DI4)
for gpio in 437 438 439 441 345; do
    [ ! -d /sys/class/gpio/gpio${gpio} ] && echo ${gpio} > /sys/class/gpio/export 2>/dev/null && echo "✅ gpio${gpio} (DI)"
    echo in > /sys/class/gpio/gpio${gpio}/direction 2>/dev/null
done

# Sortides digitals (DQ1 = gpio355, DQ0 = gpio360)
for gpio in 355 360; do
    [ ! -d /sys/class/gpio/gpio${gpio} ] && echo ${gpio} > /sys/class/gpio/export 2>/dev/null && echo "✅ gpio${gpio} (DQ)"
    echo out > /sys/class/gpio/gpio${gpio}/direction 2>/dev/null
done

# Direcció del PCAL9535 (IMPRESCINDIBLE!)
# IO7-direction = gpio487 (DQ1), IO8-direction = gpio488 (DQ0)
for gpio in 487 488; do
    [ ! -d /sys/class/gpio/gpio${gpio} ] && echo ${gpio} > /sys/class/gpio/export 2>/dev/null && echo "✅ gpio${gpio} (PCAL9535 direction)"
    echo 1 > /sys/class/gpio/gpio${gpio}/value 2>/dev/null
done

echo ""
echo "=== Estat ==="
echo "DQ1 (gpio355): $(cat /sys/class/gpio/gpio355/value 2>/dev/null)"
echo "DQ0 (gpio360): $(cat /sys/class/gpio/gpio360/value 2>/dev/null)"
for i in 0 1 2 3 4; do
    gpio=$([ $i -eq 4 ] && echo 345 || echo $((437+i)))
    echo "DI${i} (gpio${gpio}): $(cat /sys/class/gpio/gpio${gpio}/value 2>/dev/null)"
done
echo "IO7-dir (gpio487): $(cat /sys/class/gpio/gpio487/value 2>/dev/null) (1=out) DQ1"
echo "IO8-dir (gpio488): $(cat /sys/class/gpio/gpio488/value 2>/dev/null) (1=out) DQ0"
