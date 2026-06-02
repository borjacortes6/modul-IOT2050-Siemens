#!/bin/bash
# setup-gpios.sh — Per a /etc/rc.local (arrencada automàtica)
# Siemens 6ES7647-0KA01-0AA2
# gpio355 (IO7) = DQ1, gpio360 (IO8) = DQ0

for gpio in 437 438 439 441 345 355 360 487 488; do
    [ ! -d /sys/class/gpio/gpio${gpio} ] && echo ${gpio} > /sys/class/gpio/export
done

echo in > /sys/class/gpio/gpio437/direction; echo in > /sys/class/gpio/gpio438/direction
echo in > /sys/class/gpio/gpio439/direction; echo in > /sys/class/gpio/gpio441/direction
echo in > /sys/class/gpio/gpio345/direction

echo 1 > /sys/class/gpio/gpio487/value   # IO7-direction = output (DQ1)
echo 1 > /sys/class/gpio/gpio488/value   # IO8-direction = output (DQ0)

echo out > /sys/class/gpio/gpio355/direction   # DQ1
echo out > /sys/class/gpio/gpio360/direction   # DQ0
echo 0 > /sys/class/gpio/gpio355/value; echo 0 > /sys/class/gpio/gpio360/value

exit 0
