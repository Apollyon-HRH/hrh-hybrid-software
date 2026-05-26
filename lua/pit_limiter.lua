-- HRH Pit Limiter - Team Apollyon
-- Conforme Art. C7.7, limitando a velocidade a 60 km/h.

local M = {}
local vehicle = nil
local pit_limiter_active = false
local PIT_LIMIT_SPEED_MS = 16.67  -- 60 km/h em m/s

function M.init(vehicle_obj)
    vehicle = vehicle_obj
    print("HRH Pit Limiter: Inicializado.")
end

function M.update(dt)
    if not vehicle or not pit_limiter_active then return end

    local current_speed_ms = vehicle:getSpeed()
    if current_speed_ms > PIT_LIMIT_SPEED_MS then
        -- Força o throttle a 0 se a velocidade exceder o limite
        -- Nota: Isto pode ser melhorado com um controlo PID para maior suavidade
        vehicle.electrics.values.throttle_input = 0
        vehicle.electrics.values.throttle = 0
    end
end

function M.toggle()
    pit_limiter_active = not pit_limiter_active
    print("HRH Pit Limiter: " .. (pit_limiter_active and "Ativado" or "Desativado"))
    return pit_limiter_active
end

function M.set_active(active)
    pit_limiter_active = active
    print("HRH Pit Limiter: " .. (pit_limiter_active and "Ativado" or "Desativado"))
end

return M
