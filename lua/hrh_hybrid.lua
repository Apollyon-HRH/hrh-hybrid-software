-- HRH Hybrid Powertrain - Team Apollyon (UNIFIED VERSION)
-- Contains the main controller and hybrid logic

local M = {}

-- ==============================================
-- PARÂMETROS DO SISTEMA HÍBRIDO (Apêndice C5.1)
-- ==============================================
local BATTERY_CAPACITY_KWH = 8.0        -- 8 kWh
local MGUF_MAX_POWER_KW = 325           -- 325 kW
local MGUR_MAX_POWER_KW = 325           -- 325 kW (total 650 kW)
local REGEN_MAX_POWER_KW = 250          -- regeneração máxima
local MAX_TORQUE_NM = 500               -- Binário máximo de referência (500 Nm)

-- ==============================================
-- ESTADO INTERNO
-- ==============================================
local soc = 1.0                         -- State of Charge (0 a 1)
local kill_switch_activated = false
local vehicle = nil

-- ==============================================
-- FUNÇÕES AUXILIARES
-- ==============================================
local function power_to_torque(power_kw)
    return power_kw * (MAX_TORQUE_NM / MGUF_MAX_POWER_KW)
end

local function apply_throttle(motor_throttle_name, torque_nm)
    if not vehicle then return end
    vehicle.electrics.values[motor_throttle_name] = torque_nm
end

-- ==============================================
-- CARREGAMENTO DOS MÓDULOS DE CONTROLO (antigos ficheiros .lua)
-- ==============================================
-- Nota: Estes require assumem que os ficheiros estão na mesma pasta (auto)
local data_logger = require('/lua/vehicle/extensions/auto/data_logger')
local traction_control = require('/lua/vehicle/extensions/auto/traction_control')
local regen_braking = require('/lua/vehicle/extensions/auto/regenerative_braking')
local pit_limiter = require('/lua/vehicle/extensions/auto/pit_limiter')
local abs_offroad = require('/lua/vehicle/extensions/auto/abs_offroad')

-- ==============================================
-- FUNÇÃO DE INICIALIZAÇÃO (ANTIGO vehicleController.onInit)
-- ==============================================
local function init_modules()
    print("HRH: Inicializando sistema unificado...")

    -- Inicializa o data logger
    if data_logger and data_logger.start_logging then
        data_logger.start_logging(vehicle)
    end

    -- Inicializa o controlo de tração (passa o próprio M como hybrid_system)
    if traction_control and traction_control.init then
        traction_control.init(vehicle, M)
    end

    -- Inicializa a travagem regenerativa
    if regen_braking and regen_braking.init then
        regen_braking.init(vehicle, M)
    end

    -- Inicializa o Pit Limiter
    if pit_limiter and pit_limiter.init then
        pit_limiter.init(vehicle)
    end

    -- Inicializa o ABS off-road
    if abs_offroad and abs_offroad.init then
        abs_offroad.init(vehicle)
    end

    print("HRH: Todos os sistemas inicializados.")
end

local function update_modules(dt)
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

-- ==============================================
-- FUNÇÕES PRINCIPAIS DA EXTENSÃO (hrh_hybrid)
-- ==============================================
function M.onExtensionLoaded()
    print("HRH Hybrid: Sistema inicializado (versão unificada).")
    vehicle = extensions.getVehicle()
    if vehicle then
        print("HRH Hybrid: Veículo referenciado com sucesso.")
        init_modules()
    else
        print("HRH Hybrid: ERRO - Não foi possível obter referência do veículo.")
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
            else
                print("Vehicle reference is nil")
            end
        end,
        set_throttle = function(value)
            value = math.min(1, math.max(0, value))
            local torque = power_to_torque(value * MGUF_MAX_POWER_KW)
            apply_throttle("mguf_throttle", torque)
            apply_throttle("mgur_throttle", torque)
            print("Set throttle to " .. value .. " -> torque " .. torque .. " Nm")
        end
    }
    print("HRH: Debug functions available. Type 'hrh_debug.status()' in console.")
end

function M.emergency_kill()
    if kill_switch_activated then return end
    kill_switch_activated = true
    apply_throttle("mguf_throttle", 0)
    apply_throttle("mgur_throttle", 0)
    print("HRH Hybrid: KILL SWITCH ACTIVATED!")
end

function M.update(dt)
    if not vehicle or kill_switch_activated then return end

    local throttle_input = vehicle.electrics.values.throttle_input or 0
    local brake_input = vehicle.electrics.values.brake_input or 0

    -- Potência desejada
    local desired_power_front = throttle_input * MGUF_MAX_POWER_KW
    local desired_power_rear = throttle_input * MGUR_MAX_POWER_KW
    local front_torque = power_to_torque(desired_power_front)
    local rear_torque = power_to_torque(desired_power_rear)

    apply_throttle("mguf_throttle", front_torque)
    apply_throttle("mgur_throttle", rear_torque)

    -- Simulação simples da bateria
    local total_power_kw = (desired_power_front + desired_power_rear) * throttle_input
    local energy_used_kwh = total_power_kw * (dt / 3600)
    soc = soc - (energy_used_kwh / BATTERY_CAPACITY_KWH)
    soc = math.max(0, math.min(1, soc))

    -- Travagem regenerativa
    if brake_input > 0 then
        local regen_power = brake_input * REGEN_MAX_POWER_KW
        local regen_torque = power_to_torque(regen_power)
        apply_throttle("mguf_throttle", -regen_torque)
        apply_throttle("mgur_throttle", -regen_torque)
    end

    -- Atualiza os módulos de controlo
    update_modules(dt)
end

-- Funções de acesso para os outros módulos (traction_control, regen_braking)
function M.get_soc() return soc end
function M.set_throttle_front(value) apply_throttle("mguf_throttle", power_to_torque(value * MGUF_MAX_POWER_KW)) end
function M.set_throttle_rear(value) apply_throttle("mgur_throttle", power_to_torque(value * MGUR_MAX_POWER_KW)) end
function M.set_regeneration_front(value) apply_throttle("mguf_throttle", -power_to_torque(value * REGEN_MAX_POWER_KW)) end
function M.set_regeneration_rear(value) apply_throttle("mgur_throttle", -power_to_torque(value * REGEN_MAX_POWER_KW)) end

return M
