# Start the test

To start simulation firmwares, proxies, helper scripts, run: 

```shell
/bin/bash plane_follow_start.sh
```

To observe the vehicles during the test, run:

```shell
mavproxy.py --master=127.0.0.1:10010 --master=127.0.0.1:20010 --console --map
```
