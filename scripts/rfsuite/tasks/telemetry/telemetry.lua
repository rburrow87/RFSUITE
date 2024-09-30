--
local arg = {...}
local config = arg[1]
local compile = arg[2]


local telemetry = {}

function telemetry.active()
    
        local tlm = system.getSource( { category=CATEGORY_SYSTEM_EVENT, member=TELEMETRY_ACTIVE, options=nil } )
        
        if tlm:value() == 100 then
                return true
        end


        return false
end

return telemetry