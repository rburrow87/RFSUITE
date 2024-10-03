--
local arg = {...}
local config = arg[1]
local compile = arg[2]


local telemetry = {}

local sensors = {}
local protocol = nil

local telemetrySOURCE
local crsfSOURCE
local tgt

local sensorRateLimit = os.clock()
local sensorRate = 2 -- how fast can we call the rssi sensor

local telemetryState = false


local sensorTable = {}
sensorTable["voltage"]  = {sport={category = CATEGORY_TELEMETRY_SENSOR, appId = 0x0210}, ccrsf = "Vbat", lcrsf = "Rx Batt"}
sensorTable["rpm"]      = {sport={category = CATEGORY_TELEMETRY_SENSOR, appId = 0x0500}, ccrsf = "Hspd", lcrsf = "GPS Alt"}
sensorTable["current"]  = {sport={category = CATEGORY_TELEMETRY_SENSOR, appId = 0x0200}, ccrsf = "Curr", lcrsf = "Rx Curr"}
sensorTable["tempESC"]  = {sport={category = CATEGORY_TELEMETRY_SENSOR, appId = 0x0B70}, ccrsf = "Tesc", lcrsf = "GPS Speed"}
sensorTable["tempMCU"]  = {sport={category = CATEGORY_TELEMETRY_SENSOR, appId = 0x0401}, ccrsf = "Tmcu", lcrsf = "GPS Sats"}
sensorTable["fuel"]     = {sport={category = CATEGORY_TELEMETRY_SENSOR, appId = 0x0600}, ccrsf = "Bat%", lcrsf = "Rx Batt%"}
sensorTable["capacity"] = {sport={category = CATEGORY_TELEMETRY_SENSOR, appId = 0x5250}, ccrsf = "Capa", lcrsf = "Rx Cons"}
sensorTable["governor"] = {sport={category = CATEGORY_TELEMETRY_SENSOR, appId = 0x5450}, ccrsf = "Gov", lcrsf = "Flight mode"}
sensorTable["rssi"]     = {sport=rfsuite.utils.getRssiSensor(), ccrsf = rfsuite.utils.getRssiSensor(), rfsuite.utils.getRssiSensor()}
sensorTable["adjF"]     = {sport={category = CATEGORY_TELEMETRY_SENSOR, appId = 0x5110}, ccrsf = "AdjF" , lcrsf = nil}
sensorTable["adjV"]     = {sport={category = CATEGORY_TELEMETRY_SENSOR, appId = 0x5111}, ccrsf = "AdjV", lcrsf = nil}

local tlm = system.getSource( { category=CATEGORY_SYSTEM_EVENT, member=TELEMETRY_ACTIVE, options=nil } )


function telemetry.getSensorProtocol()
        return protocol
end


function telemetry.getSensorSource(name)
        local src
        if sensorTable[name] ~= nil then
                if sensors[name] == nil then

                        if telemetrySOURCE == nil then
                                telemetrySOURCE = system.getSource("Rx RSSI1")
                        end     

                        -- find type we are targetting
                        if telemetrySOURCE ~= nil then
                           if  crsfSOURCE == nil then
                                crsfSOURCE = system.getSource("*Cnt")
                           end
                           
                           if crsfSOURCE ~= nil then
                                protocol = 'ccrsf'
                                src = system.getSource(sensorTable[name].ccrsf)
                           else 
                                protocol = 'lcrsf'
                                src = system.getSource(sensorTable[name].lcrsf)
                           end
                        else
                                protocol = 'sport'
                                src = system.getSource(sensorTable[name].sport)
                        end                  
                                                
                else
                        src = sensors[name]
                end
                return src
        end

        return nil
end


function telemetry.active()     
        return telemetryState    
end

function telemetry.wakeup()


        -- we need to rate limit these calls to save issues
        
        if rfsuite.app.triggers.mspBusy ~= true then
                local now = os.clock()
                if (now - sensorRateLimit) >= sensorRate then
                        sensorRateLimit = now       

                        if tlm:state() == true then
                                telemetryState = true
                        else
                                telemetryState = false
                        end

                end        
        end

        if not telemetry.active() then
                telemetrySOURCE = nil
                crsfSOURCE = nil
                protocol = nil
                sensors = {}
        end

end

return telemetry