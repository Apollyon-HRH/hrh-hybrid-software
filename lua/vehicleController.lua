-- vehicleController.lua
-- Controller principal do veículo HRH - Team Apollyon

local M = {}

-- Carrega os módulos da pasta 'extensions/auto'
-- O caminho correto é relativo à raiz do veículo
local hrh_hybrid = require('lua/vehicle/extensions/auto/hrh_hybrid')
local data_logger = require('lua/vehicle/extensions/auto/data_logger')
local traction_control = require('lua/vehicle/extensions/auto/traction_control')
local regen_braking = require('lua/vehicle/extensions/auto/regenerative_braking')
local pit_limiter = require('lua/vehicle/extensions/auto/pit_limiter')
local abs_offroad = require('lua/vehicle/extensions/auto/abs_offroad')

function M.onInit()
    print("HRH: Inicializando sistema...")

    -- Registra o veículo no sistema híbrido
    hrh_hybrid.setVehicle(vehicle)
    
    -- Inicializa os outros sistemas
    data_logger.start_logging(vehicle)
    traction_control.init(vehicle, hrh_hybrid)
    regen_braking.init(vehicle, hrh_hybrid)
    pit_limiter.init(vehicle)
    abs_offroad.init(vehicle)

    print("HRH: Todos os sistemas inicializados.")
end

function M.update(dt)
    -- Atualiza todos os sistemas em cada frame
    hrh_hybrid.update(dt)
    traction_control.update(dt)
    regen_braking.update(dt)
    pit_limiter.update(dt)
    abs_offroad.update(dt)
end

return M
