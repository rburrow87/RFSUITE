-- RotorFlight + ETHOS LUA configuration
local config = {}

-- LuaFormatter off
config.toolName = "ROTORFLIGHT"                                         -- name of the tool
config.suiteDir = "/scripts/rfsuite/"                                -- base path the script is installed into
config.Version = "0.0.1"                                            -- version number of this software release
config.logEnable = false                                            -- will log to: /scripts/rfsuite/rfsuite.log
config.logEnableScreen = false                                      -- if config.logEnable is true then also print to screen
config.mspTxRxDebug = false                                         -- simple print of full msp payload that is sent and received
config.reloadOnSave = false                                         -- trigger a reload on save
config.ethosVersion = 1515                                          -- min version of ethos supported by this script
config.ethosVersionString = "ETHOS < V1.5.15"                       -- string to print if ethos version error occurs
config.defaultRateTable = 4 -- ACTUAL                               -- default rate table - typically this will be ACTUAL, but can be changed if user always uses a different one
config.supportedMspApiVersion = {"12.06", "12.07"}                  -- supported msp versions
config.simulateOnTransmitter = false                                -- make the transmitter run as if its running in the SIM (no fbl required)
config.skipRssiSensorCheck = false                                  -- skip checking for a valid signal when loading connecting to the fbl
config.icon = lcd.loadMask(config.suiteDir .. "app/gfx/icon.png")        -- icon

-- tasks
config.bgTaskName = config.toolName .. " [Background Tasks]"                     -- background task name for msp services etc
config.bgTaskKey = "rf2bg"                                        -- key id used for msp services


-- widgets
config.rf2govName = "Rotorflight Governor"                          -- RF2Gov Name
config.rf2govKey = "rf2gov"                                         -- RF2Gov Key
config.rf2statusName = "Rotorflight Status"                         -- RF2Status name
config.rf2statusKey = "bkshss"                                      -- RF2Status key

-- LuaFormatter on

local compile = assert(loadfile(config.suiteDir .. "compile.lua"))(config)

-- main
rfsuite = {}
rfsuite.config = config
rfsuite.app = assert(compile.loadScript(config.suiteDir .. "app/app.lua"))(config, compile)
rfsuite.utils = assert(compile.loadScript(config.suiteDir .. "lib/utils.lua"))(config, compile)


-- tasks
rfsuite.tasks = {}
rfsuite.bg = assert(compile.loadScript(config.suiteDir .. "tasks/bg.lua"))(config,compile)

-- widgets
rfsuite.rf2gov = assert(compile.loadScript(config.suiteDir .. "widgets/governor/governor.lua"))(config,compile)
rfsuite.rf2status = assert(compile.loadScript(config.suiteDir .. "widgets/status/status.lua"))(config,compile)

-- LuaFormatter off

local function init()
        system.registerSystemTool({event = rfsuite.app.event, name = config.toolName, icon = config.icon, create = rfsuite.app.create, wakeup = rfsuite.app.wakeup, paint = rfsuite.app.paint, close = rfsuite.app.close})
        system.registerTask({name = config.bgTaskName, key = config.bgTaskKey, wakeup = rfsuite.bg.wakeup, event = rfsuite.bg.event})
        system.registerWidget({name = config.rf2govName,key = config.rf2govKey, create = rfsuite.rf2gov.create, paint = rfsuite.rf2gov.paint, wakeup = rfsuite.rf2gov.wakeup, persistent = false})        
        system.registerWidget({name = config.rf2statusName,key = config.rf2statusKey, menu = rfsuite.rf2status.menu, event = rfsuite.rf2status.event, write = rfsuite.rf2status.write, read = rfsuite.rf2status.read, configure = rfsuite.rf2status.configure, create = rfsuite.rf2status.create, paint = rfsuite.rf2status.paint, wakeup = rfsuite.rf2status.wakeup, persistent = false})        
end

-- LuaFormatter on

return {init = init}



