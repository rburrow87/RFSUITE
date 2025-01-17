--
-- background processing of msp traffic
--
local arg = {...}
local config = arg[1]
local compile = arg[2]

msp = {}

msp.activeProtocol = nil
msp.onConnectChecksInit = true



local protocol = assert(compile.loadScript(config.suiteDir .. "tasks/msp/protocols.lua"))()

msp.sensor = sport.getSensor({primId = 0x32})
msp.mspQueue = mspQueue
if rfsuite.rssiSensor then
        rfsuite.sensor:module(rfsuite.rssiSensor:module())
end
msp.mspQueue = mspQueue


-- set active protocol to use
msp.protocol = protocol.getProtocol()

-- preload all transport methods
msp.protocolTransports = {}
for i,v in pairs(protocol.getTransports()) do
        msp.protocolTransports[i] = assert(compile.loadScript(config.suiteDir .. v))()
end

-- set active transport table to use
local transport = msp.protocolTransports[msp.protocol.mspProtocol]
msp.protocol.mspRead = transport.mspRead
msp.protocol.mspSend = transport.mspSend
msp.protocol.mspWrite = transport.mspWrite
msp.protocol.mspPoll = transport.mspPoll


msp.mspQueue = assert(compile.loadScript(config.suiteDir .. "tasks/msp/mspQueue.lua"))()
msp.mspQueue.maxRetries = msp.protocol.maxRetries
msp.mspHelper = assert(compile.loadScript(config.suiteDir .. "tasks/msp/mspHelper.lua"))()
assert(compile.loadScript(config.suiteDir .. "tasks/msp/common.lua"))()       

-- BACKGROUND checks
function msp.onConnectBgChecks()

        if msp.mspQueue ~= nil and msp.mspQueue:isProcessed()then


                if rfsuite.config.apiVersion == nil and msp.mspQueue:isProcessed() then

                        local message = {
                                command = 1, -- MIXER
                                processReply = function(self, buf)
                                        if #buf >= 3 then
                                                local version = buf[2] + buf[3] / 100
                                                rfsuite.config.apiVersion = version
                                                rfsuite.utils.log("MSP Version: " .. rfsuite.config.apiVersion)
                                        end
                                end,
                                simulatorResponse = {0, 12, 7}
                        }
                        msp.mspQueue:add(message)
                elseif rfsuite.config.clockSet == nil and msp.mspQueue:isProcessed() then

                        rfsuite.utils.log("Sync clock: " .. os.clock())
                        
                         local message = {
                                command = 246, -- MSP_SET_RTC
                                payload = {},
                                processReply = function(self, buf)
                                        rfsuite.utils.log("RTC set.")
                                        
                                        if #buf >= 0 then
                                                rfsuite.config.clockSet = true       
                                                -- we do the beep later to avoid a double beep
                                        end
                                        
                                end,
                                simulatorResponse = {}
                        }

                        -- generate message to send
                        local now = os.time()
                        -- format: seconds after the epoch / milliseconds
                        for i = 1, 4 do
                                rfsuite.bg.msp.mspHelper.writeU8(message.payload, now & 0xFF)
                                now = now >> 8
                        end
                        rfsuite.bg.msp.mspHelper.writeU16(message.payload, 0)

                        -- add msg to queue
                        rfsuite.bg.msp.mspQueue:add(message)                       
                elseif rfsuite.config.clockSet == true and rfsuite.config.clockSetAlart ~= true then   
                        -- this is unsual but needed because the clock sync does not return anything usefull
                        -- to confirm its done! 
                        system.playFile(rfsuite.config.suiteDir .. "app/sounds/beep.wav")
                        rfsuite.config.clockSetAlart = true
                elseif (rfsuite.config.tailMode == nil or rfsuite.config.swashMode == nil) and msp.mspQueue:isProcessed() then
                                local message = {
                                        command = 42, -- MIXER
                                        processReply = function(self, buf)
                                                if #buf >= 19 then

                                                        local tailMode = buf[2]
                                                        local swashMode = buf[6]
                                                        rfsuite.config.swashMode = swashMode
                                                        rfsuite.config.tailMode = tailMode
                                                        rfsuite.utils.log("Tail mode: " .. rfsuite.config.tailMode)
                                                        rfsuite.utils.log("Swash mode: " .. rfsuite.config.swashMode)
                                                end
                                        end,
                                        simulatorResponse = {0, 1, 0, 0, 0, 2, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
                                }
                                msp.mspQueue:add(message)
                elseif ( rfsuite.config.activeProfile == nil or rfsuite.config.activeRateProfile == nil) then   
                
                        rfsuite.utils.getCurrentProfile()
                        
                elseif (rfsuite.config.servoCount == nil) and msp.mspQueue:isProcessed() then
                                local message = {
                                        command = 120, -- MSP_SERVO_CONFIGURATIONS
                                        processReply = function(self, buf)
                                                 if #buf >= 20 then
                                                                local servoCount = msp.mspHelper.readU8(buf)
                                                                
                                                                -- update master one in case changed
                                                                rfsuite.config.servoCount = servoCount
                                                end
                                        end,
                                        simulatorResponse = {
                                                4, 180, 5, 12, 254, 244, 1, 244, 1, 244, 1, 144, 0, 0, 0, 1, 0, 160, 5, 12, 254, 244, 1, 244, 1, 244, 1, 144, 0, 0, 0, 1, 0, 14, 6, 12, 254, 244, 1, 244, 1, 244, 1, 144, 0, 0, 0, 0, 0,
                                                120, 5, 212, 254, 44, 1, 244, 1, 244, 1, 77, 1, 0, 0, 0, 0
                                        }
                                }
                                msp.mspQueue:add(message)
                                
                elseif (rfsuite.config.servoOverride == nil) and msp.mspQueue:isProcessed() then
                                local message = {
                                        command = 192, -- MSP_SERVO_OVERIDE
                                        processReply = function(self, buf)
                                                 if #buf >= 16 then
                                                 
                                                                for i = 0, rfsuite.config.servoCount do
                                                                        buf.offset = i
                                                                        local servoOverride = msp.mspHelper.readU8(buf)
                                                                        if servoOverride == 0 then
                                                                                rfsuite.utils.log("Servo overide: true")
                                                                                rfsuite.config.servoOverride = true
                                                                        end
                                                                end          
                                                                if rfsuite.config.servoOverride == nil then
                                                                        rfsuite.config.servoOverride = false 
                                                                end          
                                                end
                                        end,
                                        simulatorResponse = {209, 7, 209, 7, 209, 7, 209, 7, 209, 7, 209, 7, 209, 7, 209, 7}
                                }
                                msp.mspQueue:add(message)
                                
                                -- do this at end of last one
                                msp.onConnectChecksInit = false
                end        
        end

  
end

function msp.resetState()
        rfsuite.config.servoOverride = nil
        rfsuite.config.servoCount = nil
        rfsuite.config.tailMode = nil
        rfsuite.config.apiVersion = nil
        rfsuite.config.clockSet = nil
        rfsuite.config.clockSetAlart = nil
end

function msp.wakeup()

        -- check what protocol is in use
        local telemetrySOURCE = system.getSource("Rx RSSI1")
        if telemetrySOURCE ~= nil then
           msp.activeProtocol = "crsf"
        else
           msp.activeProtocol = "smartPort"
        end


        if rfsuite.bg.wasOn == true then
                rfsuite.rssiSensorChanged = true
        end
        
        if rfsuite.rssiSensorChanged == true then
        
                rfsuite.utils.log("Switching protocol: " .. msp.activeProtocol)
                
                msp.protocol = protocol.getProtocol()
                
                -- set active transport table to use
                local transport = msp.protocolTransports[msp.protocol.mspProtocol]
                msp.protocol.mspRead = transport.mspRead
                msp.protocol.mspSend = transport.mspSend
                msp.protocol.mspWrite = transport.mspWrite
                msp.protocol.mspPoll = transport.mspPoll  

                msp.resetState()                
                msp.onConnectChecksInit = true         
        end  
        
        if rfsuite.rssiSensor ~= nil and rfsuite.bg.telemetry.active() == false then
                msp.resetState()
                msp.onConnectChecksInit = true 
        end
 
 

        -- run the msp.checks
        
        local state

        if system:getVersion().simulation == true then
                state = true                
        elseif rfsuite.rssiSensor then
                state = rfsuite.bg.telemetry.active()
        else
                state = false
        end
             
        if state == true then     
                msp.mspQueue:processQueue()  
                
                -- checks that run on each connection to the fbl
                if msp.onConnectChecksInit == true then
                        msp.onConnectBgChecks()
                end                             
        else              
                msp.mspQueue:clear()
        end        
end



return msp