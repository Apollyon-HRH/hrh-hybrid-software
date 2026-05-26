-- HRH Traction Control - Team Apollyon
-- Conforme Art. C3.8.1, atuando exclusivamente nos MGU-Ks.
-- A lógica: se a derrapagem (wheel slip) for alta, reduz a potência do motor.

local M = {}
local vehicle = nil
local hybrid_system = nil  -- Referência ao módulo híbrido (hrh_hybrid.lua)
local TC_ACTIVE = true

-- Limiares de controlo
local SLIP_THRESHOLD = 0.15    -- 15% de derrapagem
local POWER_REDUCTION_FACTOR = 0.7  -- Reduz para 70% da potência

function M.init(vehicle_obj, hybrid_obj)
    vehicle = vehicle_obj
    hybrid_system = hybrid_obj
    print("HRH Traction Control: Inicializado.")
end

function M.update(dt)
    if not vehicle or not hybrid_system or not TC_ACTIVE then return end

    -- Obtém a velocidade das rodas e a velocidade do veículo
    local frontLeftSpeed = vehicle.electrics.values.wheelSpeed[0] or 0
    local frontRightSpeed = vehicle.electrics.values.wheelSpeed[1] or 0
    local rearLeftSpeed = vehicle.electrics.values.wheelSpeed[2] or 0
    local rearRightSpeed = vehicle.electrics.values.wheelSpeed[3] or 0
    local vehicleSpeed = vehicle:getSpeed() or 0

    -- Calcula a derrapagem média (simplificado)
    local avgWheelSpeed = (frontLeftSpeed + frontRightSpeed + rearLeftSpeed + rearRightSpeed) / 4
    local slip = (vehicleSpeed > 1) and (avgWheelSpeed - vehicleSpeed) / vehicleSpeed or 0

    -- Aplica o controlo de tração se a derrapagem exceder o limiar
    if slip > SLIP_THRESHOLD then
        local powerReduction = 1 - (POWER_REDUCTION_FACTOR * (slip - SLIP_THRESHOLD))
        powerReduction = math.max(0.1, math.min(1, powerReduction))  -- Limita entre 0.1 e 1

        -- Reduz a potência dos MGU-Ks através do módulo híbrido
        local currentThrottle = vehicle.electrics.values.throttle_input or 0
        hybrid_system.set_throttle_front(currentThrottle * powerReduction)
        hybrid_system.set_throttle_rear(currentThrottle * powerReduction)
    end
end

function M.set_active(active)
    TC_ACTIVE = active
    print("HRH Traction Control: " .. (active and "Ativado" or "Desativado"))
end

return M
