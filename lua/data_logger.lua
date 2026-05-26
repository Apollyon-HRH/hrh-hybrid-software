-- Data logger conforme Art. C3.9
-- Regista sensores a 20 Hz (frequência configurável)
local M = {}
local log_file = nil
local logger_active = false
local timer_id = nil
local vehicle = nil

function M.start_logging(vehicle_obj)
    vehicle = vehicle_obj
    if logger_active then return end

    -- Cria o nome do ficheiro com timestamp
    local timestamp = os.date("%Y%m%d_%H%M%S")
    local filename = string.format("HRH_Log_%s.csv", timestamp)
    local filepath = "logs/" .. filename

    -- Tenta criar/abrir o ficheiro
    local f, err = FS:openFile(filepath, "w")
    if not f then
        print("Erro ao criar ficheiro de log: " .. (err or "desconhecido"))
        return
    end

    -- Escreve o cabeçalho do CSV
    local header = "timestamp,throttle_input,rpm,speed,soc,mguf_power_kw,mgur_power_kw,water_temp,oil_temp\n"
    f:write(header)
    f:close()

    log_file = filepath
    logger_active = true

    -- Inicia o timer para amostragem periódica (20 Hz = 0.05 segundos)
    timer_id = Timer:new(0.05, function()
        if logger_active and vehicle and vehicle.electrics then
            local data = M.log_data()
            local f_append, err = FS:openFile(log_file, "a")
            if f_append then
                f_append:write(data)
                f_append:close()
            else
                print("Erro ao escrever no log: " .. (err or "desconhecido"))
            end
        end
    end)
    timer_id:start()

    print("Iniciou logging para: " .. log_file)
end

function M.log_data()
    -- Recolhe os valores atuais do veículo
    local tps = (vehicle.electrics.values.throttle_input or 0)
    local rpm = (vehicle.powertrain and vehicle.powertrain.getRPM and vehicle.powertrain:getRPM()) or 0
    local speed_kph = (vehicle:getSpeed() * 3.6) or 0
    -- Placeholders para os valores que ainda serão implementados no híbrido
    local soc = 0.85
    local mguf_power = 0
    local mgur_power = 0
    local water_temp = (vehicle.electrics.values.water_temperature or 0)
    local oil_temp = (vehicle.electrics.values.oil_temperature or 0)

    -- Formata a linha do CSV
    local timestamp = os.clock()
    local data_line = string.format("%.3f,%.2f,%.0f,%.1f,%.2f,%.1f,%.1f,%.1f,%.1f\n",
        timestamp, tps, rpm, speed_kph, soc, mguf_power, mgur_power, water_temp, oil_temp)

    return data_line
end

function M.stop_logging()
    if not logger_active then return end
    if timer_id then
        timer_id:stop()
        timer_id = nil
    end
    logger_active = false
    print("Logging parado. Ficheiro guardado em: " .. (log_file or "desconhecido"))
end

return M
