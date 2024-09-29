--
local arg = {...}
local config = arg[1]
local compile = arg[2]


local sport = {}


local customSensors = {}
customSensors[#customSensors + 1] = {name  = "Governor", appId = 0x5450}
customSensors[#customSensors + 1] = {name  = "Adj. Source", appId = 0x5110}
customSensors[#customSensors + 1] = {name  = "Adj. Value", appId = 0x5111}
customSensors[#customSensors + 1] = {name  = "Capacity", appId = 0x5250}
customSensors[#customSensors + 1] = {name  = "Model ID", appId = 0x5460}
customSensors[#customSensors + 1] = {name  = "PID Profile", appId = 0x5471}
customSensors[#customSensors + 1] = {name  = "Rate Profile", appId = 0x5472}
customSensors[#customSensors + 1] = {name  = "LED Profile", appId = 0x5473}

local sensors = {}

function sport.wakeup()
    
    -- check for custom sensors and create them if they dont exist

    for x,v in pairs(customSensors) do


        if sensors[v.name] == nil then
                sensors[v.name] = system.getSource({category = CATEGORY_TELEMETRY_SENSOR, appId = v.appId})
                if sensors[v.name] == nil then
                        sensors[v.name] = model.createSensor()
                        sensors[v.name]:name(v.name)
                        sensors[v.name]:appId(v.appId)
                        sensors[v.name]:physId(0)
                end   
        
        end


    end

end

return sport