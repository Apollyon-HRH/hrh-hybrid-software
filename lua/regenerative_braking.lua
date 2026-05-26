-- HRH Regenerative Braking - Team Apollyon
-- Conforme Art. C9.3, misturando regeneração (MGU-KR) e fricção.

local M = {}
local vehicle = nil
local hybrid_system = nil
local REGEN_ACTIVE = true

-- Constantes de controlo
local MAX_REGEN_BRAKING = 0.7  -- 70% da travagem pode ser regenerativa

function M.init(vehicle_obj, hybrid_obj)
    vehicle = vehicle_obj
    hybrid_system = hybrid_obj
    print("HRH Regenerative Braking: Inicializado.")
end

function M.update(dt)
    if not vehicle or not hybrid_system or not REGEN_ACTIVE then return end

    local brake_input = vehicle.electrics.values.brake_input or 0
    if brake_input <= 0 then return end

    -- Calcula a potência de regeneração com base no input do travão e no SOC
    local regen_power = brake_input * MAX_REGEN_BRAKING * hybrid_system.MGUF_MAX_POWER_KW
    local soc = hybrid_system.get_soc()

    -- Reduz a regeneração se a bateria estiver cheia
    if soc > 0.95 then
        regen_power = regen_power * (1 - (soc - 0.95) / 0.05)
    end

    -- Aplica a regeneração (o sinal negativo indica travagem regenerativa)
    local regen_throttle = regen_power / hybrid_system.MGUF_MAX_POWER_KW
    regen_throttle = math.min(1, math.max(0, regen_throttle))

    hybrid_system.set_regeneration_front(regen_throttle)
    hybrid_system.set_regeneration_rear(regen_throttle)

    -- A força de travagem de fricção é automaticamente gerida pelo modelo do veículo
    -- Este script apenas define a porção regenerativa
end

function M.set_active(active)
    REGEN_ACTIVE = active
    print("HRH Regenerative Braking: " .. (active and "Ativado" or "Desativado"))
end

return M
