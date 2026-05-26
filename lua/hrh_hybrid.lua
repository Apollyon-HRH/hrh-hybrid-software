-- HRH Hybrid Powertrain - Team Apollyon
-- (código completo com setVehicle e debug global)
local M = {}

local BATTERY_CAPACITY_KWH = 8.0
local MGUF_MAX_POWER_KW = 325
local MGUR_MAX_POWER_KW = 325
local REGEN_MAX_POWER_KW = 250
local MAX_TORQUE_NM = 500

local soc = 1.0
local kill_switch_activated = false
local vehicle = nil

local function power_to_torque(power_kw)
    return power_kw * (MAX_TORQUE_NM / MGUF_MAX_POWER_KW)
end

-- NOVA função para aplicar torque, usando a API nativa do BeamNG
local function apply_motor_torque(motor_name, torque_nm)
    if not vehicle then return end
    if vehicle.electrics and vehicle.electrics.setMotorTorque then
        vehicle.electrics:setMotorTorque(motor_name, torque_nm)
    else
        -- Fallback: escreve diretamente no valor
        vehicle.electrics.values[motor_name] = torque_nm
    end
end

function M.onExtensionLoaded()
    print("HRH Hybrid: Sistema inicializado.")
end

function M.setVehicle(vehicle_obj)
    vehicle = vehicle_obj
    print("HRH Hybrid: Veículo registrado.")
    -- Torna o debug global acessível na consola
    _G.hrh_debug = {
        get_soc = function() return soc end,
        kill = function() M.emergency_kill() end,
        status = function()
            print("SOC: " .. string.format("%.2f", soc * 100) .. "%")
            print("Kill switch: " .. tostring(kill_switch_activated))
            print("mguf torque: " .. tostring(vehicle and vehicle.electrics and vehicle.electrics.values.mguf))
            print("mgur torque: " .. tostring(vehicle and vehicle.electrics and vehicle.electrics.values.mgur))
        end,
        set_throttle = function(val)
            val = math.min(1, math.max(0, val))
            local t = power_to_torque(val * MGUF_MAX_POWER_KW)
            apply_motor_torque("mguf", t)
            apply_motor_torque("mgur", t)
        end
    }
    print("HRH: Debug functions available. Type 'hrh_debug.status()' in console.")
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
    local throttle = vehicle.electrics.values.throttle_input or 0
    local brake = vehicle.electrics.values.brake_input or 0

    local front_torque = power_to_torque(throttle * MGUF_MAX_POWER_KW)
    local rear_torque = power_to_torque(throttle * MGUR_MAX_POWER_KW)
    apply_motor_torque("mguf", front_torque)
    apply_motor_torque("mgur", rear_torque)

    -- Simulação simples da bateria
    local total_power = (front_torque + rear_torque) * 0.001
    local energy_used = total_power * (dt / 3600)
    soc = soc - (energy_used / BATTERY_CAPACITY_KWH)
    soc = math.max(0, math.min(1, soc))

    if brake > 0 then
        local regen_torque = power_to_torque(brake * REGEN_MAX_POWER_KW)
        apply_motor_torque("mguf", -regen_torque)
        apply_motor_torque("mgur", -regen_torque)
    end
end

function M.get_soc() return soc end
function M.is_kill_switch_active() return kill_switch_activated end

return M
