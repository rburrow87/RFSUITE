--
local arg = {...}
local config = arg[1]
local compile = arg[2]


local sport = {}


local customSensors = {}
customSensors[#customSensors + 1] = {name  = "Governor", appId = 0x5450, unit = UNIT_RAW}
customSensors[#customSensors + 1] = {name  = "Adj. Source", appId = 0x5110, unit = UNIT_RAW}
customSensors[#customSensors + 1] = {name  = "Adj. Value", appId = 0x5111, unit = UNIT_RAW}
customSensors[#customSensors + 1] = {name  = "Capacity", appId = 0x5250, unit=UNIT_MILLIAMPERE_HOUR}
customSensors[#customSensors + 1] = {name  = "Model ID", appId = 0x5460, unit = UNIT_RAW}
customSensors[#customSensors + 1] = {name  = "PID Profile", appId = 0x5471, unit = UNIT_RAW}
customSensors[#customSensors + 1] = {name  = "Rate Profile", appId = 0x5472, unit = UNIT_RAW}
customSensors[#customSensors + 1] = {name  = "LED Profile", appId = 0x5473, unit = UNIT_RAW}
customSensors[#customSensors + 1] = {name  = "Pitch Angle", appId = 0x5230, unit = UNIT_DEGREE}
customSensors[#customSensors + 1] = {name  = "Roll Angle", appId = 0x5240, unit = UNIT_DEGREE}

sport.sensors = {}

function sport.wakeup()

    -- kill bad temp1 sensor
    sport.badTemp1 = system.getSource({category = CATEGORY_TELEMETRY_SENSOR, appId = 0x0400})
    if sport.badTemp1 ~= nil then
        sport.badTemp1:drop()
    end
    
    -- check for custom sensors and create them if they dont exist
    for x,v in pairs(customSensors) do


        if sport.sensors[v.name] == nil then
                sport.sensors[v.name] = system.getSource({category = CATEGORY_TELEMETRY_SENSOR, appId = v.appId})
                if sport.sensors[v.name] == nil then
                        sport.sensors[v.name] = model.createSensor()
                        sport.sensors[v.name]:name(v.name)
                        sport.sensors[v.name]:appId(v.appId)
                        sport.sensors[v.name]:physId(0)
                        
                        sport.sensors[v.name]:minimum(min or -2147483647)
                        sport.sensors[v.name]:maximum(max or 2147483647)
                        if v.unit ~= nil then
                                sport.sensors[v.name]:unit(v.unit)
                                sport.sensors[v.name]:protocolUnit(v.unit)
                        end
                        if v.minimum ~= nil then
                                sport.sensors[v.name]:minimum(v.minimum)
                        end
                        if v.maximum ~= nil then
                                sport.sensors[v.name]:maximum(v.maximum)
                        end
                        
                end   
        
        end


    end
    
    -- flush sensor list if we kill the sensors
    if not rfsuite.rssiSensor then
          sport.sensors = {}
    end
    

end

return sport