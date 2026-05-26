local M = {}
local vehicle = nil
local active = false
local PIT_LIMIT_SPEED_KPH = 60

function M.init(vehicle_obj)
    vehicle = vehicle_obj
    print("HRH Pit Limiter: Inicializado.")
end

function M.update(dt)
    if not vehicle or not active then return end
    local speed_kph = vehicle:getSpeed() * 3.6
    if speed_kph > PIT_LIMIT_SPEED_KPH then
        vehicle.electrics.values.throttle_input = 0
        vehicle.electrics.values.brake_input = 1
    end
end

function M.toggle()
    active = not active
    print("HRH Pit Limiter: " .. (active and "Ativado" or "Desativado"))
    return active
end

return M
