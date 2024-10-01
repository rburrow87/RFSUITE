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

function bg.active()

        if bg.heartbeat == nil then
                return false
        end

        if (os.clock() - bg.heartbeat) <= 1 then

                return true
        else
                return false
        end

        
end


function bg.wakeup()

        bg.heartbeat = os.clock()

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

        -- high priority and must alway run regardless of tlm state
        bg.msp.wakeup()
        
        if bg.telemetry.active() then
        
                bg.sensors.wakeup()
                bg.adjfunctions.wakeup()
                bg.telemetry.wakeup()

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