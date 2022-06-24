#!/bin/bash

# initial configurations
TOTAL_VEHICLE_COUNT=5

# clear previous run
sudo rm -r logs*
sudo rm -r terrain*
sudo rm eeprom.bin

# update binary permission
sudo chmod +x arduplane

# mavproxy screen command
command="mavproxy.py --state-basedir logs --console --map"

# start firmwares
for i in $(seq 1 $TOTAL_VEHICLE_COUNT); do
  command+=" --master=127.0.0.1:$((10200 + i * 10)) "
  screen -S plane_follow_vehicle_$((i)) -d -m bash -c "./arduplane -w -S -I$((i - 1)) --model plane --speedup 10 --defaults plane.parm --sysid $((i))"
done

# start proxies
for i in $(seq 1 $TOTAL_VEHICLE_COUNT); do
  screen -S plane_follow_proxy_$((i)) -d -m bash -c "mavproxy.py --state-basedir logs --aircraft vehicle_$((i)) --master tcp:127.0.0.1:$((5750 + i * 10)) --out udp:127.0.0.1:$((10000 + i * 10)) --out udp:127.0.0.1:$((10100 + i * 10)) --out udp:127.0.0.1:$((10200 + i * 10)) --daemon"
done

# run relay
screen -S plane_follow_relay -d -m bash -c "/usr/bin/python3 plane_follow_relay.py"

# run deploy
screen -S plane_follow_deploy -d -m bash -c "/usr/bin/python3 plane_follow_deploy.py"

# open MAVProxy
screen -S plane_follow_mavproxy -d -m bash -c "$command"
