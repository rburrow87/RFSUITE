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