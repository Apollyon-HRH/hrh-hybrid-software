-- HRH Hybrid Powertrain - Team Apollyon
-- Conforme Art. C3.2, C17.1, C17.2
-- MGU-KF (dianteiro) + MGU-KR (traseiro)

local M = {}

-- Parâmetros configuráveis (Apêndice C5.1)
M.BATTERY_CAPACITY_KWH = 8.0   -- 8 kWh
M.BATTERY_VOLTAGE = 800        -- 800 V
M.MGUF_MAX_POWER_KW = 325      -- 325 kW
M.MGUR_MAX_POWER_KW = 325      -- 325 kW (total combinado 650 kW)
M.REGEN_MAX_POWER_KW = 250     -- regeneração máxima

-- Estado interno
local soc = 1.0                -- State of Charge (0..1)
local mguf_power_kw = 0
local mgur_power_kw = 0
local kill_switch_activated = false

-- Função de emergência (kill switch)
function M.emergency_kill()
    kill_switch_activated = true
    mguf_power_kw = 0
    mgur_power_kw = 0
    print("HRH Hybrid: KILL SWITCH activated")
end

-- Verifica colisão (chamado pelo BeamNG em cada tick)
function M.check_crash(g_force)
    if g_force > 15 then
        M.emergency_kill()
    end
end

-- API pública
function M.set_throttle_front(normalized)
    if kill_switch_activated then return end
    mguf_power_kw = math.min(normalized * M.MGUF_MAX_POWER_KW, M.MGUF_MAX_POWER_KW)
end

function M.set_throttle_rear(normalized)
    if kill_switch_activated then return end
    mgur_power_kw = math.min(normalized * M.MGUR_MAX_POWER_KW, M.MGUR_MAX_POWER_KW)
end

function M.set_regeneration_front(normalized)
    if kill_switch_activated then return end
    local regen = math.min(normalized * M.REGEN_MAX_POWER_KW, M.REGEN_MAX_POWER_KW)
    mguf_power_kw = -regen
end

function M.set_regeneration_rear(normalized)
    if kill_switch_activated then return end
    local regen = math.min(normalized * M.REGEN_MAX_POWER_KW, M.REGEN_MAX_POWER_KW)
    mgur_power_kw = -regen
end

function M.get_soc()
    return soc
end

function M.get_power_kw_front()
    return mguf_power_kw
end

function M.get_power_kw_rear()
    return mgur_power_kw
end

return M
