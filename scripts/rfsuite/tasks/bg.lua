--
-- background processing of system tasks
--
local arg = {...}
local config = arg[1]
local compile = arg[2]

-- declare vars
local bg = {}
bg.init = true

bg.heartbeat = nil

bg.init = false                
-- tasks
bg.telemetry = assert(compile.loadScript(config.suiteDir .. "tasks/telemetry/telemetry.lua"))(config,compile)
bg.msp = assert(compile.loadScript(config.suiteDir .. "tasks/msp/msp.lua"))(config,compile)
bg.adjfunctions = assert(compile.loadScript(config.suiteDir .. "tasks/adjfunctions/adjfunctions.lua"))(config,compile)
bg.sensors = assert(compile.loadScript(config.suiteDir .. "tasks/sensors/sensors.lua"))(config,compile)

rfsuite.rssiSensorChanged = true

local rssiCheckScheduler = os.clock()
local lastRssiSensorName = nil

function bg.active()

 
        if bg.heartbeat == nil then
                return false
        end

        -- if msp is busy.. we are 100% ok
        if rfsuite.app.triggers.mspBusy == true then
                return true
        end
        
        if (os.clock() - bg.heartbeat) <= 5 then
                return true
        else
                return false
        end

        
end


function bg.wakeup()

        bg.heartbeat = os.clock()


       -- this should be before msp.hecks
        -- doing this is heavy - lets run it every few seconds only
        local now = os.clock()
        if (now - rssiCheckScheduler) >= 2 then
                        local currentRssiSensor = rfsuite.utils.getRssiSensor()
                        
                        if currentRssiSensor ~= nil then
                        
                                if lastRssiSensorName ~= currentRssiSensor.name then
                                      rfsuite.rssiSensorChanged = true  
                                else
                                      rfsuite.rssiSensorChanged = false 
                                end
                        
                                lastRssiSensorName = currentRssiSensor.name
                                rfsuite.rssiSensor = currentRssiSensor.sensor
                        end
                        rssiCheckScheduler = now
        end
        

        -- high priority and must alway run regardless of tlm state
        bg.msp.wakeup()
        bg.telemetry.wakeup() 
        bg.sensors.wakeup()
        bg.adjfunctions.wakeup()


end

function bg.event(widget, category, value)

        if bg.msp.event then
                bg.msp.event(widget, category, value)
        end
        if bg.adjfunctions.event then
                bg.adjfunctions.event(widget, category, value)
        end
end




return bg