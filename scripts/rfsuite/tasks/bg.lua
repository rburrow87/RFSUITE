--
-- background processing of system tasks
--
local arg = {...}
local config = arg[1]
local compile = arg[2]

-- declare vars
local bg = {}
bg.init = true

local initTime



function bg.wakeup()

        -- tasks dont have a create function
        -- so we handle this here with a loop that
        -- runs only once
        if bg.init == true then
                bg.init = false                
                -- tasks
                bg.telemetry = assert(compile.loadScript(config.suiteDir .. "tasks/telemetry/telemetry.lua"))(config,compile)
                bg.msp = assert(compile.loadScript(config.suiteDir .. "tasks/msp/msp.lua"))(config,compile)
                bg.adjfunctions = assert(compile.loadScript(config.suiteDir .. "tasks/adjfunctions/adjfunctions.lua"))(config,compile)
                bg.sensors = assert(compile.loadScript(config.suiteDir .. "tasks/sensors/sensors.lua"))(config,compile)
        end

        if rfsuite.rssiSensor == nil then
                initTime = os.clock()
        end

        

        -- high priority and must alway run regardless of tlm state
        bg.msp.wakeup()
        
        if bg.telemetry.active() then

                -- high priority tasks        
                bg.sensors.wakeup()
                
                -- we only want these to kick in maybe 5s after connection has come up. this allows things to stabilize
                if (os.clock() - initTime) > 5 then
                        bg.adjfunctions.wakeup()
                end
        end

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