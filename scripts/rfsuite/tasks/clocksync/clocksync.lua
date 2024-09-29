--
-- Rotorflight Clock Sync
-- this syncs the flight controllers clock with the radio
--
local arg = {...}
local config = arg[1]
local compile = arg[2]

-- declare vars
local clocksync = {}
clocksync.init = true
clocksync.sensor = nil
clocksync.protocol = {}
clocksync.rssiSensor = nil
clocksync.config = config
clocksync.timeIsSet = false
clocksync.timeIsSetProtocol = nil


function clocksync.setRtc(callback, callbackParam)
        local message = {
                command = 246, -- MSP_SET_RTC
                payload = {},
                processReply = function(self, buf)
                        rfsuite.utils.log("RTC set.")
                        if callback then callback(callbackParam) end
                end,
                simulatorResponse = {}
        }

        local now = os.time()
        -- format: seconds after the epoch / milliseconds
        for i = 1, 4 do
                rfsuite.bg.msp.mspHelper.writeU8(message.payload, now & 0xFF)
                now = now >> 8
        end
        -- we don't have milliseconds

        rfsuite.bg.msp.mspHelper.writeU16(message.payload, 0)

        rfsuite.bg.msp.mspQueue:add(message)
end

function clocksync.onRtcSet()
        system.playTone(1600, 500, 0)
        clocksync.timeIsSetProtocol = rfsuite.bg.msp.protocol.mspProtocol
        clocksync.timeIsSet = true
        ELRS_PAUSE_TELEMETRY = false
        CRSF_PAUSE_TELEMETRY = false
        collectgarbage()
end

function clocksync.wakeup()


        if system:getVersion().simulation == true then
                return
        end
        
        if rfsuite.bg.msp.backgroundMsp ~= true then
                if clocksync.init == true then
                        print("not running as msp not active")
                        clocksync.init = false
                end        
                return
        end

        if rfsuite.rssiSensor ~= nil and rfsuite.rssiSensor:state() == true then
                -- set the time
                if clocksync.timeIsSet == false and rfsuite.bg.msp.mspQueue:isProcessed() then 
                        clocksync.setRtc(clocksync.onRtcSet) 
                end
        else
                -- link was lost.  assume need to resync clock
                clocksync.timeIsSet = false
                ELRS_PAUSE_TELEMETRY = false
                CRSF_PAUSE_TELEMETRY = false                
        end
        

end


return clocksync

