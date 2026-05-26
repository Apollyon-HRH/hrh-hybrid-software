-- Data logger conforme Art. C3.9
-- Regista sensores a 20 Hz (frequência configurável)

local M = {}
local log_file = nil
local last_tick = 0

function M.start_logging(filename)
    -- Abre ficheiro CSV e escreve cabeçalho
end

function M.log_data(tps, rpm, speed, soc, power_front, power_rear, temp_water, temp_oil)
    -- Escreve linha no formato CSV
end

function M.stop_logging()
    -- Fecha ficheiro
end

return M
