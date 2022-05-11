#!/bin/bash

# start firmware
screen -S firmware_follower -d -m bash -c "./arduplane -w -S -I0 --model plane --speedup 1 --defaults plane.parm --sysid 1"
screen -S firmware_leader -d -m bash -c "./arduplane -w -S -I1 --model plane --speedup 10 --defaults plane.parm --sysid 2"

# setup proxy
screen -S proxy_follower -d -m bash -c "mavproxy.py --state-basedir logs --aircraft follower --master tcp:127.0.0.1:5760 --out udp:127.0.0.1:10010 --out udp:127.0.0.1:10020 --out udp:127.0.0.1:10030 --daemon"
screen -S proxy_leader -d -m bash -c "mavproxy.py --state-basedir logs --aircraft leader --master tcp:127.0.0.1:5770 --out udp:127.0.0.1:20010 --out udp:127.0.0.1:20020 --out udp:127.0.0.1:20030 --daemon"

# run relay
screen -S telemetry_relay -d -m bash -c "/usr/bin/python3 plane_follow_relay.py"

# deploy leader
screen -S wp_loader_proxy -d -m bash -c "mavproxy.py --state-basedir logs --master 127.0.0.1:20020 --cmd='set requireexit true'"
command=""
command+="sleep 3;"
command+="screen -S wp_loader_proxy -X stuff 'scripting stop^M';"
command+="sleep 3;"
command+="screen -S wp_loader_proxy -X stuff 'wp load way.txt^M';"
command+="sleep 3;"
command+="screen -S wp_loader_proxy -X stuff 'mode AUTO^M';"
command+="sleep 3;"
command+="screen -S wp_loader_proxy -X stuff 'arm throttle^M';"
command+="sleep 3;"
command+="screen -S wp_loader_proxy -X stuff 'param set SIM_SPEEDUP 1^M';"
command+="sleep 3;"
command+="screen -S wp_loader_proxy -X stuff 'exit^M';"
command+="screen -S wp_loader_proxy -X stuff '^M'"
screen -S wp_loader_screen -d -m bash -c "$command"

# open MAVProxy
screen -S mavproxy -d -m bash -c "mavproxy.py --state-basedir logs --master=127.0.0.1:10010 --master=127.0.0.1:20010 --console --map"
