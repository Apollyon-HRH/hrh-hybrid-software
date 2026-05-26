local M = {}
local vehicle = nil
local hybrid_system = nil
local SLIP_THRESHOLD = 0.15

function M.init(vehicle_obj, hybrid_obj)
    vehicle = vehicle_obj
    hybrid_system = hybrid_obj
    print("HRH TC: Inicializado.")
end

function M.update(dt)
    if not vehicle or not hybrid_system then return end

    local frontLeft = vehicle.electrics.values.wheelSpeed[0] or 0
    local frontRight = vehicle.electrics.values.wheelSpeed[1] or 0
    local rearLeft = vehicle.electrics.values.wheelSpeed[2] or 0
    local rearRight = vehicle.electrics.values.wheelSpeed[3] or 0
    local vehicleSpeed = vehicle:getSpeed() or 0

    local avgWheelSpeed = (frontLeft + frontRight + rearLeft + rearRight) / 4
    local slip = (vehicleSpeed > 1) and (avgWheelSpeed - vehicleSpeed) / vehicleSpeed or 0

    if slip > SLIP_THRESHOLD then
        local reduction = 1 - (slip - SLIP_THRESHOLD)
        reduction = math.max(0.2, math.min(1, reduction))
        local currentThrottle = vehicle.electrics.values.throttle_input or 0
        vehicle.electrics.values.throttle_input = currentThrottle * reduction
    end
end

return M
