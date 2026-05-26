-- HRH Hybrid Powertrain - Team Apollyon (UNIFIED & DEFINITIVE)
-- Este script é a única extensão necessária. Ele carrega e coordena todos os outros módulos.

local M = {}

-- ==============================================
-- PARÂMETROS (Apêndice C5.1)
-- ==============================================
local BATTERY_CAPACITY_KWH = 8.0
local MGUF_MAX_POWER_KW = 325
local MGUR_MAX_POWER_KW = 325
local REGEN_MAX_POWER_KW = 250
local MAX_TORQUE_NM = 500

-- ==============================================
-- ESTADO INTERNO
-- ==============================================
local soc = 1.0
local kill_switch_activated = false
local vehicle = nil

-- ==============================================
-- MÓDULOS SECUNDÁRIOS (carregados com require)
-- ==============================================
local abs_offroad
local data_logger
local pit_limiter
local regen_braking
local traction_control

-- ==============================================
-- FUNÇÕES AUXILIARES
-- ==============================================
local function power_to_torque(power_kw)
    return power_kw * (MAX_TORQUE_NM / MGUF_MAX_POWER_KW)
end

-- Aplica potência/torque diretamente nos valores de throttle do motor elétrico
local function apply_throttle(motor_throttle_name, torque_nm)
    if not vehicle then
        log('W', 'HRH', 'apply_throttle: vehicle is nil')
        return
    end
    vehicle.electrics.values[motor_throttle_name] = torque_nm
end

-- ==============================================
-- FUNÇÕES PÚBLICAS (usadas pelos outros módulos)
-- ==============================================
function M.set_throttle_front(value)      -- value 0..1
    if kill_switch_activated then return end
    local torque = power_to_torque(value * MGUF_MAX_POWER_KW)
    apply_throttle("mguf_throttle", torque)
end

function M.set_throttle_rear(value)
    if kill_switch_activated then return end
    local torque = power_to_torque(value * MGUR_MAX_POWER_KW)
    apply_throttle("mgur_throttle", torque)
end

function M.set_regeneration_front(value)   -- valor positivo = regeneração
    if kill_switch_activated then return end
    local torque = power_to_torque(value * REGEN_MAX_POWER_KW)
    apply_throttle("mguf_throttle", -torque)
end

function M.set_regeneration_rear(value)
    if kill_switch_activated then return end
    local torque = power_to_torque(value * REGEN_MAX_POWER_KW)
    apply_throttle("mgur_throttle", -torque)
end

function M.get_soc()
    return soc
end

function M.get_power_kw_front()
    return (vehicle and vehicle.electrics.values.mguf_throttle) or 0
end

function M.get_power_kw_rear()
    return (vehicle and vehicle.electrics.values.mgur_throttle) or 0
end

function M.emergency_kill()
    if kill_switch_activated then return end
    kill_switch_activated = true
    apply_throttle("mguf_throttle", 0)
    apply_throttle("mgur_throttle", 0)
    print("HRH Hybrid: KILL SWITCH ACTIVATED!")
end

-- ==============================================
-- EXTENSÃO PRINCIPAL (chamada automaticamente pelo BeamNG)
-- ==============================================
function M.onExtensionLoaded()
    print("HRH Hybrid: Sistema inicializado (unificado).")

    -- Obtém referência do veículo
    vehicle = extensions.getVehicle()
    if vehicle then
        print("HRH Hybrid: Veículo referenciado com sucesso.")
    else
        print("HRH Hybrid: ERRO - Não foi possível obter referência do veículo.")
    end

    -- Carrega os outros módulos (eles ficam na mesma pasta)
    local ok, err
    ok, abs_offroad = pcall(require, 'lua/vehicle/extensions/auto/abs_offroad')
    if not ok then print("HRH: abs_offroad não carregado: " .. tostring(err)) end

    ok, data_logger = pcall(require, 'lua/vehicle/extensions/auto/data_logger')
    if not ok then print("HRH: data_logger não carregado: " .. tostring(err)) end

    ok, pit_limiter = pcall(require, 'lua/vehicle/extensions/auto/pit_limiter')
    if not ok then print("HRH: pit_limiter não carregado: " .. tostring(err)) end

    ok, regen_braking = pcall(require, 'lua/vehicle/extensions/auto/regenerative_braking')
    if not ok then print("HRH: regenerative_braking não carregado: " .. tostring(err)) end

    ok, traction_control = pcall(require, 'lua/vehicle/extensions/auto/traction_control')
    if not ok then print("HRH: traction_control não carregado: " .. tostring(err)) end

    -- Inicializa cada módulo
    if abs_offroad and abs_offroad.init then
        abs_offroad.init(vehicle)
    end
    if data_logger and data_logger.start_logging then
        data_logger.start_logging(vehicle)
    end
    if pit_limiter and pit_limiter.init then
        pit_limiter.init(vehicle)
    end
    if regen_braking and regen_braking.init then
        regen_braking.init(vehicle, M)   -- passa o próprio módulo híbrido
    end
    if traction_control and traction_control.init then
        traction_control.init(vehicle, M)
    end

    -- Cria a tabela de debug global
    _G.hrh_debug = {
        get_soc = function() return soc end,
        kill = function() M.emergency_kill() end,
        status = function()
            print("SOC: " .. string.format("%.2f", soc * 100) .. "%")
            print("Kill switch: " .. tostring(kill_switch_activated))
            if vehicle then
                print("mguf throttle: " .. tostring(vehicle.electrics.values.mguf_throttle))
                print("mgur throttle: " .. tostring(vehicle.electrics.values.mgur_throttle))
                print("throttle_input: " .. tostring(vehicle.electrics.values.throttle_input))
            else
                print("Vehicle reference is nil")
            end
        end,
        set_throttle = function(value)
            value = math.min(1, math.max(0, value))
            M.set_throttle_front(value)
            M.set_throttle_rear(value)
            print("Set throttle to " .. value)
        end
    }
    print("HRH: Debug functions available. Type 'hrh_debug.status()' in console.")
end

-- ==============================================
-- ACTUALIZAÇÃO PERIÓDICA (chamada automaticamente)
-- ==============================================
function M.update(dt)
    if not vehicle or kill_switch_activated then return end

    local throttle_input = vehicle.electrics.values.throttle_input or 0
    local brake_input = vehicle.electrics.values.brake_input or 0

    -- Potência desejada (mapeamento linear do acelerador)
    local front_torque = power_to_torque(throttle_input * MGUF_MAX_POWER_KW)
    local rear_torque  = power_to_torque(throttle_input * MGUR_MAX_POWER_KW)

    apply_throttle("mguf_throttle", front_torque)
    apply_throttle("mgur_throttle", rear_torque)

    -- Simulação simples da bateria
    local total_power_kw = (throttle_input * MGUF_MAX_POWER_KW + throttle_input * MGUR_MAX_POWER_KW) * throttle_input
    local energy_used_kwh = total_power_kw * (dt / 3600)
    soc = soc - (energy_used_kwh / BATTERY_CAPACITY_KWH)
    soc = math.max(0, math.min(1, soc))

    -- Travagem regenerativa (se necessário)
    if brake_input > 0 then
        local regen_power = brake_input * REGEN_MAX_POWER_KW
        local regen_torque = power_to_torque(regen_power)
        apply_throttle("mguf_throttle", -regen_torque)
        apply_throttle("mgur_throttle", -regen_torque)
    end

    -- Atualiza os módulos secundários
    if traction_control and traction_control.update then
        traction_control.update(dt)
    end
    if regen_braking and regen_braking.update then
        regen_braking.update(dt)
    end
    if pit_limiter and pit_limiter.update then
        pit_limiter.update(dt)
    end
    if abs_offroad and abs_offroad.update then
        abs_offroad.update(dt)
    end
end

return M
