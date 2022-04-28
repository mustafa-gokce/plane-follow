import pymavlink.mavutil as utility
import pymavlink.dialects.v20.all as dialect

# connect to leader
vehicle_leader = utility.mavlink_connection(device="udpin:127.0.0.1:20030")
vehicle_leader.wait_heartbeat()

# connect to follower
vehicle_follower = utility.mavlink_connection(device="udpin:127.0.0.1:10030",
                                              source_system=vehicle_leader.target_system)
vehicle_follower.wait_heartbeat()

# inform user
print("Connected to leader:", vehicle_leader.target_system, ", component:", vehicle_leader.target_component)
print("Connected to follower:", vehicle_follower.target_system, ", component:", vehicle_follower.target_component)

# do below always
while True:
    # catch position message
    message_raw = vehicle_leader.recv_match(type=dialect.MAVLink_global_position_int_message.name,
                                            blocking=True)

    # relay the position message
    vehicle_follower.mav.send(message_raw)

    # convert the message to dictionary
    message_dict = message_raw.to_dict()
