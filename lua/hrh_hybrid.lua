-- HRH Hybrid Powertrain - Team Apollyon
-- Versão final com controlo via electricsThrottleName

local M = {}

-- Parâmetros (Apêndice C5.1)
local BATTERY_CAPACITY_KWH = 8.0
local MGUF_MAX_POWER_KW = 325
local MGUR_MAX_POWER_KW = 325
local REGEN_MAX_POWER_KW = 250
local MAX_TORQUE_NM = 500

local soc = 1.0
local kill_switch_activated = false
local vehicle = nil

-- Converte kW para Nm (simplificado)
local function power_to_torque(power_kw)
    return power_kw * (MAX_TORQUE_NM / MGUF_MAX_POWER_KW)
end

-- Aplica o binário usando o novo método via electricsThrottleName
local function apply_motor_power(motor_throttle_name, power_kw)
    if not vehicle then return end
    local torque_nm = power_to_torque(power_kw)
    -- O módulo do motor no .pc foi configurado para responder a este valor.
    vehicle.electrics.values[motor_throttle_name] = torque_nm
end

function M.onExtensionLoaded()
    print("HRH Hybrid: Sistema inicializado (versão final).")
end

function M.setVehicle(vehicle_obj)
    vehicle = vehicle_obj
    print("HRH Hybrid: Veículo registrado.")

    -- Torna funções de depuração acessíveis globalmente na consola (F8)
    _G.hrh_debug = {
        get_soc = function() return soc end,
        kill = function() M.emergency_kill() end,
        status = function()
            print("SOC: " .. string.format("%.2f", soc * 100) .. "%")
            print("Kill switch: " .. tostring(kill_switch_activated))
            print("mguf torque: " .. tostring(vehicle.electrics.values.mguf_throttle))
            print("mgur torque: " .. tostring(vehicle.electrics.values.mgur_throttle))
        end,
        set_throttle = function(value)
            value = math.min(1, math.max(0, value))
            apply_motor_power("mguf_throttle", value * MGUF_MAX_POWER_KW)
            apply_motor_power("mgur_throttle", value * MGUR_MAX_POWER_KW)
        end
    }
    print("HRH: Debug functions available. Type 'hrh_debug.status()' in console.")
end

function M.emergency_kill()
    if kill_switch_activated then return end
    kill_switch_activated = true
    apply_motor_power("mguf_throttle", 0)
    apply_motor_power("mgur_throttle", 0)
    print("HRH Hybrid: KILL SWITCH ACTIVATED!")
end

function M.update(dt)
    if not vehicle or kill_switch_activated then return end

    local throttle_input = vehicle.electrics.values.throttle_input or 0
    local brake_input = vehicle.electrics.values.brake_input or 0

    -- Controlo de Potência
    local desired_power_front = throttle_input * MGUF_MAX_POWER_KW
    local desired_power_rear = throttle_input * MGUR_MAX_POWER_KW
    apply_motor_power("mguf_throttle", desired_power_front)
    apply_motor_power("mgur_throttle", desired_power_rear)

    -- Gestão da Bateria (simples)
    local total_power_kw = (desired_power_front + desired_power_rear) * throttle_input
    local energy_used_kwh = total_power_kw * (dt / 3600)
    soc = soc - (energy_used_kwh / BATTERY_CAPACITY_KWH)
    soc = math.max(0, math.min(1, soc))

    -- Travagem Regenerativa (simples)
    if brake_input > 0 then
        local regen_power = brake_input * REGEN_MAX_POWER_KW
        apply_motor_power("mguf_throttle", -regen_power)
        apply_motor_power("mgur_throttle", -regen_power)
    end
end

function M.get_soc() return soc end
function M.is_kill_switch_active() return kill_switch_activated end

return M
