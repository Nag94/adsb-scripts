#!/bin/bash


if ! dpkg -s rtl-sdr 2>/dev/null | grep 'Status.*installed' &>/dev/null
then
    if ! apt-get install --no-install-recommends --no-install-suggests --reinstall -y rtl-sdr
    then
        echo "Couldn't install rtl-sdr!"
        exit 1
    fi
fi

stop="piaware dump1090-fa dump1090-mutability dump1090 dump978-fa readsb"

systemctl stop fr24feed &>/dev/null


if pgrep -a dump1090 || pgrep -a dump978 || pgrep -a readsb
then
    restart=yes
    for i in $stop
    do
        systemctl stop $i 2>/dev/null
    done
    pkill -9 dump1090
    pkill -9 readsb
    for i in $stop
    do
        systemctl stop $i 2>/dev/null
    done
    pkill -9 dump1090
    pkill -9 readsb
    sleep 1
fi

if pgrep -l dump1090 || pgrep -l readsb
then
    echo "dump1090 is still running, can't test the rtl-sdr receiver, please reboot and try again!"
    for i in $stop
    do
        systemctl restart $i 2>/dev/null
    done
    systemctl restart fr24feed &>/dev/null
    exit 1
fi


echo "-----"
echo "Lost samples in the first 2 seconds after starting the test are common and not a problem!"
echo "Starting 30 second rtl_test, standby!"
echo "-----"

timeout 30 rtl_test -s 2400000

echo "-------"
echo "Test finished!"
echo "More than 2 lost samples per million or other errors probably mean the receiver isn't working correctly."
echo "Try another power supply before condemning the receiver though!"
echo "-------"

systemctl restart fr24feed &>/dev/null

if [[ $restart == yes ]]
then
    for i in $stop
    do
        systemctl restart $i 2>/dev/null
    done
fi


if dmesg --ctime | grep voltage
then
    echo "-------"
    dmesg --ctime | grep voltage | tail -n15
    echo "-------"
    echo "Your power supply is not adequate, consider the Official Raspberry Pi power supply."
    echo "Any constant voltage supply with 5.1 to 5.2 Volts and 2.5A capability is also a good choice."
    echo "Inadequate power supplies can lead to many different problems!"
    echo "-------"
else
    echo "-------"
    echo "No undervoltage detected, looking fine!"
    echo "If the dongle is not directly plugged into the Raspberry Pi, lack of power/voltage could still be an issue."
    echo "Even without detected undervoltage a better power supply can often improve reception!"
    echo "For optimum performance i would recommend the Official Raspberry Pi power supply."
    echo "-------"
fi
