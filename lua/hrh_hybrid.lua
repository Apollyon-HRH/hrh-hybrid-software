-- HRH Hybrid Powertrain - Team Apollyon
-- Conforme Art. C3.2, C17.1, C17.2
-- Versão final com API setMotorTorque

local M = {}

-- Parâmetros (Apêndice C5.1)
local BATTERY_CAPACITY_KWH = 8.0
local MGUF_MAX_POWER_KW = 325
local MGUR_MAX_POWER_KW = 325
local REGEN_MAX_POWER_KW = 250
local MAX_TORQUE_NM = 500

-- Estado interno
local soc = 1.0
local kill_switch_activated = false
local vehicle = nil

-- Converte kW para Nm a uma rotação de referência (simplificado)
local function power_to_torque(power_kw)
    return power_kw * (MAX_TORQUE_NM / MGUF_MAX_POWER_KW)
end

-- Aplica binário usando a API nativa do BeamNG
local function apply_motor_torque(motor_name, torque_nm)
    if not vehicle then return end
    -- O comando é executado no contexto do veículo, garantindo que a API existe
    vehicle:queueLuaCommand(string.format(
        "if vehicle and vehicle.electrics then vehicle.electrics:setMotorTorque('%s', %f) end",
        motor_name, torque_nm
    ))
end

function M.onExtensionLoaded()
    print("HRH Hybrid: Sistema inicializado.")
end

function M.setVehicle(vehicle_obj)
    vehicle = vehicle_obj
    print("HRH Hybrid: Veículo registrado.")
end

function M.emergency_kill()
    if kill_switch_activated then return end
    kill_switch_activated = true
    apply_motor_torque("mguf", 0)
    apply_motor_torque("mgur", 0)
    print("HRH Hybrid: KILL SWITCH ACTIVATED!")
end

function M.update(dt)
    if not vehicle or kill_switch_activated then return end

    local throttle_input = vehicle.electrics.values.throttle_input or 0
    local brake_input = vehicle.electrics.values.brake_input or 0

    -- Potência desejada (kW)
    local desired_power_front = throttle_input * MGUF_MAX_POWER_KW
    local desired_power_rear = throttle_input * MGUR_MAX_POWER_KW

    -- Binário correspondente
    local mguf_torque = power_to_torque(desired_power_front)
    local mgur_torque = power_to_torque(desired_power_rear)

    apply_motor_torque("mguf", mguf_torque)
    apply_motor_torque("mgur", mgur_torque)

    -- Gestão simples da bateria
    local total_power_kw = (desired_power_front + desired_power_rear) * (mguf_torque / MAX_TORQUE_NM)
    local energy_used_kwh = total_power_kw * (dt / 3600)
    soc = soc - (energy_used_kwh / BATTERY_CAPACITY_KWH)
    soc = math.max(0, math.min(1, soc))

    -- Travagem regenerativa (simples)
    if brake_input > 0 then
        local regen_power = brake_input * REGEN_MAX_POWER_KW
        local regen_torque = power_to_torque(regen_power)
        apply_motor_torque("mguf", -regen_torque)
        apply_motor_torque("mgur", -regen_torque)
    end
end

-- Funções de acesso (para debug e outros módulos)
function M.get_soc() return soc end
function M.is_kill_switch_active() return kill_switch_activated end

-- Função global para debug na consola (F8)
_G.hrh_debug = {
    get_soc = function() return soc end,
    kill = function() M.emergency_kill() end,
    status = function() 
        print("SOC: " .. string.format("%.2f", soc * 100) .. "%")
        print("Kill switch: " .. tostring(kill_switch_activated))
    end
}

return M
