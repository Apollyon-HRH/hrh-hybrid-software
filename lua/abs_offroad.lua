-- HRH ABS Off-Road - Team Apollyon
-- Conforme Art. C9.4.1, ativo apenas em terrenos de terra/lama.

local M = {}
local vehicle = nil
local ABS_ACTIVE = false  -- Só será ativado em off-road
local last_surface = "asphalt"

function M.init(vehicle_obj)
    vehicle = vehicle_obj
    print("HRH ABS Off-Road: Inicializado.")
end

function M.update(dt)
    if not vehicle then return end

    -- Determina o tipo de superfície (placeholder - a implementação real pode variar)
    -- Este é um exemplo simplificado. Uma abordagem mais robusta usaria raycasts.
    local current_surface = "asphalt"  -- Substituir por lógica real
    if current_surface ~= "asphalt" and current_surface ~= "road" then
        if not ABS_ACTIVE then
            ABS_ACTIVE = true
            print("HRH ABS Off-Road: Ativado (superfície: " .. current_surface .. ")")
        end
    else
        if ABS_ACTIVE then
            ABS_ACTIVE = false
            print("HRH ABS Off-Road: Desativado (superfície: asfalto)")
        end
        return
    end

    if not ABS_ACTIVE then return end

    -- Lógica de ABS: se a roda bloquear, reduz a pressão do travão
    local brake_input = vehicle.electrics.values.brake_input or 0
    if brake_input > 0 then
        local wheel_speeds = vehicle.electrics.values.wheelSpeed
        local any_wheel_locked = false
        for i = 0, 3 do
            if wheel_speeds[i] < 0.5 and brake_input > 0.5 then
                any_wheel_locked = true
                break
            end
        end

        if any_wheel_locked then
            -- Reduz o input do travão para evitar o bloqueio
            vehicle.electrics.values.brake_input = brake_input * 0.7
        end
    end
end

return M
