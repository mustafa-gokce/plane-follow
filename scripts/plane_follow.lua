local LOOP_UPDATE_RATE_HZ = 20 -- main loop update interval

-- main function that will be called within loop
function update()
    gcs:send_text(0, "Iteration")
end

-- loop function to call main update function
function loop()
   update()
   return loop, 1000 // LOOP_UPDATE_RATE_HZ
end

-- protected loop function to call main update function
function protected_wrapper()
  local success, err = pcall(update)
  if not success then
     gcs:send_text(0, "Internal Error: " .. err)
     return protected_wrapper, 1000
  end
  return protected_wrapper, 1000 // LOOP_UPDATE_RATE_HZ
end

-- initial call for protected loop function
return protected_wrapper()
