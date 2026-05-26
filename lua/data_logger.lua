local M = {}
local vehicle = nil
local log_file = nil

function M.start_logging(vehicle_obj)
    vehicle = vehicle_obj
    if not vehicle then return end
    local timestamp = os.date("%Y%m%d_%H%M%S")
    log_file = "HRH_Log_" .. timestamp .. ".csv"
    local header = "timestamp,throttle_input,rpm,speed_kph,soc,mguf_torque,mgur_torque,brake_input\n"
    FS:writeFile(log_file, header)
    print("HRH Logger: Gravando em " .. log_file)
    return true
end

function M.stop_logging()
    log_file = nil
    print("HRH Logger: Logging parado.")
end

return M
