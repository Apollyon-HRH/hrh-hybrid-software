local M = {}
local vehicle = nil
local active = false

function M.init(vehicle_obj)
    vehicle = vehicle_obj
    print("HRH ABS Off-Road: Inicializado.")
end

function M.update(dt)
    if not vehicle then return end

    local surfaceMaterial = vehicle:getContactMaterial()
    if surfaceMaterial and (surfaceMaterial:find("dirt") or surfaceMaterial:find("mud")) then
        active = true
    else
        active = false
        return
    end

    if not active then return end

    local brake_input = vehicle.electrics.values.brake_input or 0
    if brake_input > 0 then
        local wheel_speeds = vehicle.electrics.values.wheelSpeed
        for i = 0, 3 do
            if wheel_speeds[i] < 0.5 and brake_input > 0.5 then
                vehicle.electrics.values.brake_input = brake_input * 0.7
                break
            end
        end
    end
end

return M
