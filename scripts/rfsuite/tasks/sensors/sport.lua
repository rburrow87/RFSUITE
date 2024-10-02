--
local arg = {...}
local config = arg[1]
local compile = arg[2]


local sport = {}


local customSensors = {}
customSensors[0x5450] = {name  = "Governor", unit = UNIT_RAW}
customSensors[0x5110] = {name  = "Adj. Source", unit = UNIT_RAW}
customSensors[0x5111] = {name  = "Adj. Value", unit = UNIT_RAW}
customSensors[0x5250] = {name  = "Consumption", unit=UNIT_MILLIAMPERE_HOUR}
customSensors[0x5460] = {name  = "Model ID", unit = UNIT_RAW}
customSensors[0x5471] = {name  = "PID Profile", unit = UNIT_RAW}
customSensors[0x5472] = {name  = "Rate Profile", unit = UNIT_RAW}
customSensors[0x5473] = {name  = "LED Profile", unit = UNIT_RAW}
customSensors[0x5230] = {name  = "Pitch Angle", unit = UNIT_DEGREE}
customSensors[0x5240] = {name  = "Roll Angle", unit = UNIT_DEGREE}

sport.sensors = {}


local function createSensor(physId, primId, appId, frameValue)

        -- check for custom sensors and create them if they dont exist
        if customSensors[appId] ~= nil then
        
         
                v = customSensors[appId]
                           
                if sport.sensors[v.name] == nil then
                        sport.sensors[v.name] = system.getSource({category = CATEGORY_TELEMETRY_SENSOR, appId = appId})
                        if sport.sensors[v.name] == nil then
                        
                                print("Creating sensor: " .. v.name)
                        
                                sport.sensors[v.name] = model.createSensor()
                                sport.sensors[v.name]:name(v.name)
                                sport.sensors[v.name]:appId(appId)
                                sport.sensors[v.name]:physId(physId)
                                
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
    
end    

local function telemetryPop()
        -- Pops a received SPORT packet from the queue. Please note that only packets using a data ID within 0x5000 to 0x50FF (frame ID == 0x10), as well as packets with a frame ID equal 0x32 (regardless of the data ID) will be passed to the LUA telemetry receive queue.
        local frame = rfsuite.bg.msp.sensor:popFrame()
        if frame == nil then return false end

        createSensor(frame:physId(), frame:primId(), frame:appId(), frame:value())
        
        return true
end

function sport.wakeup()

    -- kill bad temp1 sensor
    sport.badTemp1 = system.getSource({category = CATEGORY_TELEMETRY_SENSOR, appId = 0x0400})
    if sport.badTemp1 ~= nil then
        sport.badTemp1:drop()
    end   
     
    -- flush sensor list if we kill the sensors
    if not rfsuite.bg.telemetry.active() then
          sport.sensors = {}
    end

   -- if gui or queue is busy.. do not do this!
   if rfsuite.app.guiIsRunning == false and rfsuite.bg.msp.mspQueue:isProcessed() then
        while telemetryPop() do end
   end 

end

return sport
