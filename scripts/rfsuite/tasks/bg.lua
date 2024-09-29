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
                bg.msp = assert(compile.loadScript(config.suiteDir .. "tasks/msp/msp.lua"))(config,compile)
                bg.adjfunctions = assert(compile.loadScript(config.suiteDir .. "tasks/adjfunctions/adjfunctions.lua"))(config,compile)
                bg.clocksync = assert(compile.loadScript(config.suiteDir .. "tasks/clocksync/clocksync.lua"))(config,compile)
                bg.sensors = assert(compile.loadScript(config.suiteDir .. "tasks/sensors/sensors.lua"))(config,compile)
        end

        if rfsuite.rssiSensor == nil then
                initTime = os.clock()
        end

        -- high priority tasks
        bg.msp.wakeup()
        bg.sensors.wakeup()
        
        -- we only want these to kick in maybe 5s after connection has come up. this allows things to stabilize
        if (os.clock() - initTime) > 5 then
                bg.clocksync.wakeup()
                bg.adjfunctions.wakeup()
        end


end

return bg