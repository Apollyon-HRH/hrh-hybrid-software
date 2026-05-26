-- vehicleController.lua (na raiz do veículo)
-- Controller principal do veículo HRH - Team Apollyon

local M = {}

-- CORREÇÃO AQUI: Carrega os módulos com 'require' e caminhos absolutos!
local hrh_hybrid = require('lua/vehicle/extensions/auto/hrh_hybrid')
local data_logger = require('lua/vehicle/extensions/auto/data_logger')
local traction_control = require('lua/vehicle/extensions/auto/traction_control')
local regen_braking = require('lua/vehicle/extensions/auto/regenerative_braking')
local pit_limiter = require('lua/vehicle/extensions/auto/pit_limiter')
local abs_offroad = require('lua/vehicle/extensions/auto/abs_offroad')

function M.onInit()
    print("HRH: Inicializando sistema...")

    -- 1. Inicializa o sistema híbrido (passa a referência do veículo)
    if hrh_hybrid and hrh_hybrid.setVehicle then
        hrh_hybrid.setVehicle(vehicle)
    else
        print("HRH: ERRO - Módulo hrh_hybrid não encontrado!")
    end

    -- 2. Inicializa os outros sistemas
    if data_logger and data_logger.start_logging then data_logger.start_logging(vehicle) end
    if traction_control and traction_control.init then traction_control.init(vehicle, hrh_hybrid) end
    if regen_braking and regen_braking.init then regen_braking.init(vehicle, hrh_hybrid) end
    if pit_limiter and pit_limiter.init then pit_limiter.init(vehicle) end
    if abs_offroad and abs_offroad.init then abs_offroad.init(vehicle) end

    print("HRH: Todos os sistemas inicializados. Digite 'hrh_debug.status()' no console.")
end

function M.update(dt)
    -- Atualiza todos os sistemas a cada frame
    if hrh_hybrid and hrh_hybrid.update then hrh_hybrid.update(dt) end
    if traction_control and traction_control.update then traction_control.update(dt) end
    if regen_braking and regen_braking.update then regen_braking.update(dt) end
    if pit_limiter and pit_limiter.update then pit_limiter.update(dt) end
    if abs_offroad and abs_offroad.update then abs_offroad.update(dt) end
end

return M
