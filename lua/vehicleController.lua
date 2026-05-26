-- vehicleController.lua
-- Controller principal do veículo HRH - Team Apollyon

local M = {}

-- Caminho relativo à raiz da pasta 'lua/vehicle/'
local hrh_hybrid = require('vehicle/extensions/auto/hrh_hybrid')
local data_logger = require('vehicle/extensions/auto/data_logger')
local traction_control = require('vehicle/extensions/auto/traction_control')
local regen_braking = require('vehicle/extensions/auto/regenerative_braking')
local pit_limiter = require('vehicle/extensions/auto/pit_limiter')
local abs_offroad = require('vehicle/extensions/auto/abs_offroad')

function M.onInit()
    print("HRH: Inicializando sistema...")

    hrh_hybrid.setVehicle(vehicle)

    data_logger.start_logging(vehicle)
    traction_control.init(vehicle, hrh_hybrid)
    regen_braking.init(vehicle, hrh_hybrid)
    pit_limiter.init(vehicle)
    abs_offroad.init(vehicle)

    print("HRH: Todos os sistemas inicializados.")
end

function M.update(dt)
    hrh_hybrid.update(dt)
    traction_control.update(dt)
    regen_braking.update(dt)
    pit_limiter.update(dt)
    abs_offroad.update(dt)
end

return M
