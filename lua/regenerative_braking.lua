local M = {}
local vehicle = nil
local hybrid_system = nil

function M.init(vehicle_obj, hybrid_obj)
    vehicle = vehicle_obj
    hybrid_system = hybrid_obj
    print("HRH Regen Brake: Inicializado.")
end

function M.update(dt)
    if not vehicle or not hybrid_system then return end
    local brake_input = vehicle.electrics.values.brake_input or 0
    if brake_input > 0 then
        local max_regen = 250000 -- 250 kW em Watts
        local regen_power = brake_input * max_regen
        vehicle.electrics.values.regen_power_front = regen_power
        vehicle.electrics.values.regen_power_rear = regen_power
    end
end

return M
