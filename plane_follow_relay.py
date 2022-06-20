import threading
import pymavlink.mavutil as utility
import pymavlink.dialects.v20.all as dialect

TOTAL_VEHICLE_COUNT = 5
RELAY_PORT_START = 20000

vehicles = []
receive_telemetry_threads = []


def receive_telemetry(this, that):
    while True:
        message_raw = that.recv_match(type=dialect.MAVLink_global_position_int_message.name, blocking=True)
        this.mav.send(message_raw)
        # message_dict = message_raw.to_dict()
        # print("Routed", message_dict["mavpackettype"], "message from", that.target_system, "to", this.target_system)


# connect to vehicles
for i in range(1, TOTAL_VEHICLE_COUNT + 1):
    vehicle = utility.mavlink_connection(device=f"udpin:127.0.0.1:{RELAY_PORT_START + i * 10}")
    vehicle.wait_heartbeat()
    print("Connected to vehicle:", vehicle.target_system, ", component:", vehicle.target_component)
    vehicles.append(vehicle)

for vehicle in vehicles[1:]:
    receive_telemetry_thread = threading.Thread(target=receive_telemetry, args=(vehicles[0], vehicle))
    receive_telemetry_threads.append(receive_telemetry_thread)
    receive_telemetry_threads[-1].start()
