-- main settings
local LOOP_UPDATE_RATE_HZ = 20 -- main loop update interval

-- global variable declarations
local follow_target_exist = false
local follow_target_position = Location()
local follow_target_velocity = Vector3f()
local follow_target_heading = 0.0
local vehicle_reference_position = Location()
local vehicle_current_position = Location()
local vehicle_setpoint_airspeed = 0.0
local vehicle_current_airspeed = 0.0
local vehicle_target_airspeed = 20.0

-- global enumerations and definitions
local ENUM_MODE_GUIDED = 15

function check_parameters() -- check key parameters

    local key_params = {
        FOLL_ENABLE = 1,
        FOLL_OFS_TYPE = 1,
        FOLL_ALT_TYPE = 0,
    } -- parameters to check

    for p, v in pairs(key_params) do -- check and set parameters
        local current = param:get(p)
        assert(current, string.format("parameter %s not found", p))
        if math.abs(v - current) > 0.001 then
            param:set_and_save(p, v)
            gcs:send_text(0, string.format("parameter %s set to %.2f was %.2f", p, v, current))
        end
    end
end

function update_target() -- update target state
    if not follow:have_target() then
        if follow_target_exist then
            gcs:send_text(0, "lost leader")
        end
        follow_target_exist = false -- vehicle does not have a leader
        return
    end
    if not follow_target_exist then
        gcs:send_text(0, "found leader")
    end
    follow_target_exist = true -- vehicle has a leader

    follow_target_position, follow_target_velocity = follow:get_target_location_and_velocity_ofs() -- get location and velocity of the leader
    follow_target_position:change_alt_frame(0) -- altitude frame type of the target position should be absolute
    follow_target_heading = follow:get_target_heading_deg() -- -- get heading of the leader
end

function update() -- main function that will be called within loop
    if not (vehicle:get_mode() == ENUM_MODE_GUIDED) then
        return -- do not proceed if vehicle is not in GUIDED mode
    end

    vehicle_current_position = ahrs:get_position() -- update current position
    if not vehicle_current_position then
        return -- do not proceed if vehicle does not have position yet
    end

    vehicle_current_airspeed = ahrs:airspeed_estimate() -- get current airspeed of the vehicle
    if not vehicle_current_airspeed then
        return -- do not proceed if vehicle does not have an acceptable current airspeed
    end

    vehicle_setpoint_airspeed = vehicle:get_target_airspeed() -- get airspeed setpoint of the vehicle
    if not vehicle_setpoint_airspeed then
        return -- do not proceed if vehicle does not have an acceptable airspeed setpoint
    end

    update_target() -- update target data
    if not follow_target_exist then
        return -- do not proceed if vehicle does not have a target yet
    end

    vehicle_reference_position = follow_target_position:copy() -- copy target position to reference position
    vehicle_reference_position:offset_bearing(follow_target_heading + 180, 1000) -- calculate reference position
    vehicle_reference_position:change_alt_frame(0) -- change altitude frame of the reference position to absolute

    vehicle:update_target_airspeed(vehicle_target_airspeed) -- update target airspeed of the vehicle
    vehicle:update_target_location(vehicle_reference_position, follow_target_position) -- update target location of the vehicle
end

function loop() -- loop function to call main update function
    update() -- call update function
    return loop, 1000 // LOOP_UPDATE_RATE_HZ
end

function protected_wrapper() -- protected loop function to call main update function
    local success, err = pcall(update)
    if not success then
        gcs:send_text(0, "Internal Error: " .. err)
        return protected_wrapper, 1000
    end
    return protected_wrapper, 1000 // LOOP_UPDATE_RATE_HZ
end

check_parameters() -- check parameters before starting the main loop

return protected_wrapper() -- initial call for protected loop function
