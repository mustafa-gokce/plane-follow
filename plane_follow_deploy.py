import time
import threading
import dronekit

# configurations
TOTAL_VEHICLE_COUNT = 5
RELAY_PORT_START = 10000

# global variables
vehicles = []
receive_telemetry_threads = []


# get position messages from other vehicles and send to the vehicle
def receive_telemetry(vehicle):
    while True:
        if vehicle.home_location is not None:
            if vehicle.mode != "TAKEOFF":
                vehicle.mode = "TAKEOFF"
            if not vehicle.armed:
                vehicle.armed = True
            if vehicle.parameters["SIM_SPEEDUP"] > 1:
                vehicle.parameters["SIM_SPEEDUP"] = 1
            if vehicle.parameters["SCR_ENABLE"] > 0:
                vehicle.parameters["SCR_ENABLE"] = 0
        time.sleep(1)


# connect to vehicles
for i in range(1, TOTAL_VEHICLE_COUNT + 1):
    vehicle = dronekit.connect(ip=f"udpin:127.0.0.1:{RELAY_PORT_START + i * 10}", wait_ready=True)
    vehicles.append(vehicle)

# run telemetry receiver threads
for vehicle in vehicles[1:]:
    receive_telemetry_thread = threading.Thread(target=receive_telemetry, args=(vehicle,))
    receive_telemetry_threads.append(receive_telemetry_thread)
    receive_telemetry_threads[-1].start()
