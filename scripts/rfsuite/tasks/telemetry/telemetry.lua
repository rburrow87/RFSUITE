--
local arg = {...}
local config = arg[1]
local compile = arg[2]


local telemetry = {}

local sensors = {}
local telemetrySOURCE
local crsfSOURCE
local tgt


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
                                src = system.getSource(sensorTable[name].ccrsf)
                           else 
                                src = system.getSource(sensorTable[name].lcrsf)
                           end
                        else
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
    
        local tlm = system.getSource( { category=CATEGORY_SYSTEM_EVENT, member=TELEMETRY_ACTIVE, options=nil } )
        
        if tlm:value() == 100 then
                return true
        end


        return false
end

function telemetry.wakeup()

   
        if not telemetry.active() then
                telemetrySOURCE = nil
                crsfSOURCE = nil
                sensors = {}
        end

end

return telemetry