-- HRH Hybrid Powertrain - Team Apollyon
-- Conforme Art. C3.2, C17.1, C17.2
-- MGU-KF (dianteiro) + MGU-KR (traseiro)

local M = {}

-- Parâmetros de configuração (Apêndice C5.1)
local BATTERY_CAPACITY_KWH = 8.0        -- 8 kWh
local MGUF_MAX_POWER_KW = 325           -- 325 kW
local MGUR_MAX_POWER_KW = 325           -- 325 kW (total 650 kW)
local REGEN_MAX_POWER_KW = 250          -- regeneração máxima
local MAX_TORQUE_NM = 500               -- Binário máximo de referência (500 Nm)

-- Estado interno
local soc = 1.0
local kill_switch_activated = false
local vehicle = nil

-- Função para converter kW em binário (Nm)
local function power_to_torque(power_kw)
    return power_kw * (MAX_TORQUE_NM / MGUF_MAX_POWER_KW)
end

-- Chamado quando a extensão é carregada
function M.onExtensionLoaded()
    print("HRH Hybrid: Sistema inicializado.")
end

-- Função para registrar o veículo (chamado pelo vehicleController)
function M.setVehicle(vehicle_obj)
    vehicle = vehicle_obj
    print("HRH Hybrid: Veículo registrado.")
end

-- Função de emergência (kill switch)
function M.emergency_kill()
    kill_switch_activated = true
    print("HRH Hybrid: KILL SWITCH ACTIVATED!")
end

-- Lógica principal de controle, chamada a cada frame
function M.update(dt)
    if not vehicle then return end
    if kill_switch_activated then return end

    -- Lê inputs do jogador
    local throttle_input = vehicle.electrics.values.throttle_input or 0
    local brake_input = vehicle.electrics.values.brake_input or 0

    -- Calcula a potência desejada
    local desired_power_front = throttle_input * MGUF_MAX_POWER_KW
    local desired_power_rear = throttle_input * MGUR_MAX_POWER_KW

    -- Aplica a potência (aqui você integrará com o torque real no futuro)
    local mguf_torque_nm = power_to_torque(desired_power_front)
    local mgur_torque_nm = power_to_torque(desired_power_rear)

    -- Simulação simples da bateria
    local total_power_kw = mguf_torque_nm + mgur_torque_nm
    local energy_used_kwh = total_power_kw * (dt / 3600)
    soc = math.max(0, math.min(1, soc - (energy_used_kwh / BATTERY_CAPACITY_KWH)))

    -- Placeholder para onde o binário real será aplicado
    -- No futuro, isso atualizará electrics.values.mguf_torque, etc.
end

-- Funções de acesso público
function M.get_soc() return soc end
function M.is_kill_switch_active() return kill_switch_activated end

return M
