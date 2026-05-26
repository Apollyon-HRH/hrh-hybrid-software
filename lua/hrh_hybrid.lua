-- HRH Hybrid Powertrain - Team Apollyon
-- Versão autónoma definitiva

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

-- Converte kW para Nm (aproximação linear)
local function power_to_torque(power_kw)
    return power_kw * (MAX_TORQUE_NM / MGUF_MAX_POWER_KW)
end

-- Aplica potência diretamente nos valores de throttle do motor elétrico
local function apply_throttle(motor_throttle_name, torque_nm)
    if not vehicle then
        log('W', 'HRH', 'apply_throttle: vehicle is nil')
        return
    end
    vehicle.electrics.values[motor_throttle_name] = torque_nm
    log('I', 'HRH', string.format('apply_throttle: %s = %.1f Nm', motor_throttle_name, torque_nm))
end

-- Função chamada quando a extensão é carregada
function M.onExtensionLoaded()
    print("HRH Hybrid: Sistema inicializado (autônomo).")
    
    -- Obtém a referência do veículo
    vehicle = extensions.getVehicle()
    if vehicle then
        print("HRH Hybrid: Veículo referenciado com sucesso.")
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
            if vehicle then
                print("throttle_input: " .. tostring(vehicle.electrics.values.throttle_input))
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

-- Kill switch
function M.emergency_kill()
    if kill_switch_activated then return end
    kill_switch_activated = true
    apply_throttle("mguf_throttle", 0)
    apply_throttle("mgur_throttle", 0)
    print("HRH Hybrid: KILL SWITCH ACTIVATED!")
end

-- Atualização periódica (chamada automaticamente pela extensão)
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
end

return M
