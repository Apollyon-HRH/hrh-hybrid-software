-- HRH Hybrid Powertrain - Team Apollyon
-- Conforme Art. C3.2, C17.1, C17.2
-- MGU-KF (dianteiro) + MGU-KR (traseiro)
-- Este script deve ser colocado na pasta do veículo: lua/vehicle/hrh_hybrid.lua

local M = {}

-- Parâmetros de configuração (Apêndice C5.1)
local BATTERY_CAPACITY_KWH = 8.0        -- 8 kWh
local MGUF_MAX_POWER_KW = 325           -- 325 kW
local MGUR_MAX_POWER_KW = 325           -- 325 kW (total 650 kW)
local REGEN_MAX_POWER_KW = 250          -- regeneração máxima
local MAX_TORQUE_NM = 500               -- Binário máximo de referência (500 Nm)

-- Estado interno (não modifique)
local soc = 1.0                         -- State of Charge (0 a 1)
local mguf_torque_nm = 0
local mgur_torque_nm = 0
local kill_switch_activated = false
local vehicle = nil                     -- Referência ao objeto do veículo
local last_tick_time = 0                -- Para cálculo de delta time

-- Função para converter kW em binário (Nm) com base na rotação.
-- Fórmula: Torque (Nm) = (Potência (kW) * 1000) / (2 * pi * RPM / 60)
-- Esta é uma simplificação. Idealmente, usaríamos uma tabela RPM->Torque.
-- Para este script, vamos usar uma relação linear simples: Torque = Potência_Desejada * (MAX_TORQUE_NM / MAX_POWER_KW)
local function power_to_torque(power_kw)
    return power_kw * (MAX_TORQUE_NM / MGUF_MAX_POWER_KW)
end

-- Função para inicializar o módulo
function M.init(vehicle_obj)
    vehicle = vehicle_obj
    print("HRH Hybrid: Sistema inicializado.")
end

-- Função de emergência (kill switch)
function M.emergency_kill()
    kill_switch_activated = true
    mguf_torque_nm = 0
    mgur_torque_nm = 0
    print("HRH Hybrid: KILL SWITCH ACTIVATED!")
end

-- Lógica principal de controlo. Esta função deve ser chamada a cada frame.
function M.update(dt)
    if not vehicle then return end
    if kill_switch_activated then
        -- Se o kill switch estiver ativo, garante que os motores estão desligados.
        mguf_torque_nm = 0
        mgur_torque_nm = 0
        return
    end

    -- 1. LER INPUTS DO JOGADOR
    local throttle_input = vehicle.electrics.values.throttle_input or 0
    local brake_input = vehicle.electrics.values.brake_input or 0

    -- 2. LÓGICA DE GESTÃO DE POTÊNCIA (SIMPLIFICADA PARA DEMONSTRAÇÃO)
    -- AQUI IMPLEMENTAREMOS A LÓGICA DE GESTÃO ENERGÉTICA DEFINITIVA MAIS TARDE.
    -- Por enquanto, vamos apenas mapear o acelerador diretamente na potência dos MGUs.
    local desired_power_front = throttle_input * MGUF_MAX_POWER_KW
    local desired_power_rear = throttle_input * MGUR_MAX_POWER_KW

    -- 3. SIMULAÇÃO SIMPLES DE BATERIA
    -- Potência total usada/regenerada (kW)
    local total_power_kw = mguf_torque_nm + mgur_torque_nm -- Placeholder
    -- Energia usada (kWh) = Potência (kW) * tempo (h)
    local energy_used_kwh = total_power_kw * (dt / 3600)
    soc = soc - (energy_used_kwh / BATTERY_CAPACITY_KWH)
    soc = math.max(0, math.min(1, soc)) -- Limita SOC entre 0 e 1

    -- Limita a potência se a bateria estiver muito baixa
    if soc < 0.1 then
        desired_power_front = desired_power_front * (soc / 0.1)
        desired_power_rear = desired_power_rear * (soc / 0.1)
    end

    -- 4. APLICAR BINÁRIO AOS MOTORES ELÉTRICOS NO BEAMNG
    -- O binário desejado é baseado na potência desejada.
    mguf_torque_nm = power_to_torque(desired_power_front)
    mgur_torque_nm = power_to_torque(desired_power_rear)

    -- AVISO: A aplicação prática do binário no BeamNG depende de como os
    -- componentes elétricos são definidos no ficheiro .pc e JBeam.
    -- A integração final será feita ao configurar o ficheiro .pc.
    -- Neste script, estamos calculando o binário alvo, que será usado
    -- pela ferramenta de conversão .pc para configurar os motores.
end

-- Funções de acesso público
function M.set_throttle_front(value) end -- Placeholder
function M.set_throttle_rear(value) end  -- Placeholder
function M.get_soc() return soc end
function M.get_power_kw_front() return mguf_torque_nm end
function M.get_power_kw_rear() return mgur_torque_nm end

return M
