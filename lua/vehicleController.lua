-- vehicleController.lua
-- Controller principal do veículo HRH - Team Apollyon

local M = {}

-- Carrega os módulos usando 'require' com caminhos relativos à pasta 'lua/vehicle/'
local hrh_hybrid = require('/lua/vehicle/extensions/auto/hrh_hybrid')
local data_logger = require('/lua/vehicle/extensions/auto/data_logger')
local traction_control = require('/lua/vehicle/extensions/auto/traction_control')
local regen_braking = require('/lua/vehicle/extensions/auto/regenerative_braking')
local pit_limiter = require('/lua/vehicle/extensions/auto/pit_limiter')
local abs_offroad = require('/lua/vehicle/extensions/auto/abs_offroad')

function M.onInit()
    print("HRH: Inicializando sistema...")

    -- Verifica se os módulos foram carregados com sucesso
    if hrh_hybrid then
        hrh_hybrid.setVehicle(vehicle)
    else
        print("HRH: ERRO - Módulo hrh_hybrid não encontrado!")
    end

    if data_logger then
        data_logger.start_logging(vehicle)
    else
        print("HRH: ERRO - Módulo data_logger não encontrado!")
    end

    if traction_control then
        traction_control.init(vehicle, hrh_hybrid)
    end

    if regen_braking then
        regen_braking.init(vehicle, hrh_hybrid)
    end

    if pit_limiter then
        pit_limiter.init(vehicle)
    end

    if abs_offroad then
        abs_offroad.init(vehicle)
    end

    print("HRH: Todos os sistemas inicializados.")
end

function M.update(dt)
    if hrh_hybrid then
        hrh_hybrid.update(dt)
    end

    if traction_control then
        traction_control.update(dt)
    end

    if regen_braking then
        regen_braking.update(dt)
    end

    if pit_limiter then
        pit_limiter.update(dt)
    end

    if abs_offroad then
        abs_offroad.update(dt)
    end
end

return M
