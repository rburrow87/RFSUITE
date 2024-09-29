--
-- background processing of system tasks
--
local arg = {...}
local config = arg[1]
local compile = arg[2]

-- declare vars
local bg = {}
bg.init = true

function bg.wakeup()

        -- tasks dont have a create function
        -- so we handle this here with a loop that
        -- runs only once
        if bg.init == true then
                bg.init = false
                
                -- tasks
                bg.msp = assert(compile.loadScript(config.suiteDir .. "tasks/msp/msp.lua"))(config,compile)
                bg.adjfunctions = assert(compile.loadScript(config.suiteDir .. "tasks/adjfunctions/adjfunctions.lua"))(config,compile)
                bg.clocksync = assert(compile.loadScript(config.suiteDir .. "tasks/clocksync/clocksync.lua"))(config,compile)
                bg.sensors = assert(compile.loadScript(config.suiteDir .. "tasks/sensors/sensors.lua"))(config,compile)
        end


        -- high priority tasks
        bg.msp.wakeup()
        bg.sensors.wakeup()
        bg.clocksync.wakeup()
        bg.adjfunctions.wakeup()        


end

return bg