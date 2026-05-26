-- vehicleController.lua
-- Controller principal do veículo HRH - Team Apollyon

local M = {}

-- Não precisamos de 'require' aqui. As extensões já estão carregadas.
-- Vamos apenas obter as referências.
local hrh_hybrid
local data_logger
local traction_control
local regen_braking
local pit_limiter
local abs_offroad

function M.onInit()
    print("HRH: Inicializando sistema...")

    -- Obtém referências para as extensões carregadas
    hrh_hybrid = extensions.hrh_hybrid
    data_logger = extensions.data_logger
    traction_control = extensions.traction_control
    regen_braking = extensions.regenerative_braking
    pit_limiter = extensions.pit_limiter
    abs_offroad = extensions.abs_offroad

    if hrh_hybrid then
        hrh_hybrid.setVehicle(vehicle)
    else
        print("HRH: ERRO - Módulo hrh_hybrid não encontrado!")
    end

    if data_logger then data_logger.start_logging(vehicle) end
    if traction_control then traction_control.init(vehicle, hrh_hybrid) end
    if regen_braking then regen_braking.init(vehicle, hrh_hybrid) end
    if pit_limiter then pit_limiter.init(vehicle) end
    if abs_offroad then abs_offroad.init(vehicle) end

    print("HRH: Todos os sistemas inicializados.")
end

function M.update(dt)
    if hrh_hybrid then hrh_hybrid.update(dt) end
    if traction_control then traction_control.update(dt) end
    if regen_braking then regen_braking.update(dt) end
    if pit_limiter then pit_limiter.update(dt) end
    if abs_offroad then abs_offroad.update(dt) end
end

return M
