local utils = {}

-- this is used in multiple places - just gives easy way
-- to grab activeProfile or activeRateProfile in tmp var
-- you MUST set it to nil after you get it!
function utils.getCurrentProfile()

    
        if (rfsuite.app.sensors ~= nil)
            and (rfsuite.app.sensors.profileCRSF ~= nil and rfsuite.app.sensors.profileCRSF:state() == true) 
            and (rfsuite.app.sensors.rateCRSF ~= nil and rfsuite.app.sensors.rateCRSF:state() == true) 
            then
                -- crsf call for data              
                rfsuite.config.activeProfileLast = rfsuite.config.activeProfile
                rfsuite.config.activeProfile = math.floor(rfsuite.app.sensors.profileCRSF:value())
                
                rfsuite.config.activeRateProfileLast = rfsuite.config.activeRateProfile
                rfsuite.config.activeRateProfile = math.floor(rfsuite.app.sensors.rateCRSF:value())
    
        elseif (rfsuite.app.sensors ~= nil)
            and (rfsuite.app.sensors.profileSPORT ~= nil and rfsuite.app.sensors.profileSPORT:state() == true) 
            and (rfsuite.app.sensors.rateSPORT ~= nil and rfsuite.app.sensors.rateSPORT:state() == true) 
            then       
                -- call sport sensor data
                 
                rfsuite.config.activeProfileLast = rfsuite.config.activeProfile
                rfsuite.config.activeProfile = math.floor(rfsuite.app.sensors.profileSPORT:value())
                
                rfsuite.config.activeRateProfileLast = rfsuite.config.activeRateProfile
                rfsuite.config.activeRateProfile = math.floor(rfsuite.app.sensors.rateSPORT:value())
    
        else
                -- msp call to get data
                print("MSP Sensor - Switch Profile")

                local message = {
                        command = 101, -- MSP_SERVO_CONFIGURATIONS
                        processReply = function(self, buf)
                        
                                if #buf >= 30 then
                        
                                        buf.offset = 24
                                        local activeProfile = rfsuite.bg.msp.mspHelper.readU8(buf)
                                        buf.offset = 26
                                        local activeRate = rfsuite.bg.msp.mspHelper.readU8(buf)                                                          
                                
                                        rfsuite.config.activeProfileLast = rfsuite.config.activeProfile
                                        rfsuite.config.activeRateProfileLast = rfsuite.config.activeRateProfile  
                                         
                                        rfsuite.config.activeProfile = activeProfile + 1
                                        rfsuite.config.activeRateProfile = activeRate + 1

                                end 
                        end,
                        simulatorResponse = {240, 1, 124, 0, 35, 0, 0, 0, 0, 0, 0, 224, 1, 10, 1, 0, 26, 0, 0, 0, 0, 0, 2, 0, 6, 0, 6, 1, 4, 1},

                }
                rfsuite.bg.msp.mspQueue:add(message)
        
        end
end

function utils.ethosVersion()
           local environment = system.getVersion()
           return tonumber(environment.major .. environment.minor .. environment.revision)
end

function utils.getRssiSensor()
        local rssiSensor
        local rssiNames = {"RSSI", "RSSI 2.4G", "RSSI 900M", "Rx RSSI1", "Rx RSSI2", "RSSI Int", "RSSI Ext"}
        for i, name in ipairs(rssiNames) do
                rssiSensor = system.getSource(name)
                if rssiSensor then return rssiSensor end
        end
end

function utils.titleCase(str)
        return str:gsub("(%a)([%w_']*)", function(first, rest)
                return first:upper() .. rest:lower()
        end)
end


function utils.stringInArray(array, s)
        for i, value in ipairs(array) do if value == s then return true end end
        return false
end

function utils.wrapText(text, width)
        local lines = {}
        local line = ""

        local height
        for word in text:gmatch("%S+") do

                local lw, lh = lcd.getTextSize(line)
                local ww, wh = lcd.getTextSize(word)

                if lw + ww + 5 > width then
                        table.insert(lines, line)
                        line = word

                else
                        if lw > 0 then
                                line = line .. " " .. word
                        else
                                line = word
                        end
                end
        end

        if #line > 0 then table.insert(lines, line) end

        return table.concat(lines, "\n")
end

function utils.countCarriageReturns(text)
        local _, count = text:gsub("\r", "")
        return count
end

function utils.getSection(id, sections)
        for i, v in ipairs(sections) do if id ~= nil then if v.section == id then return v end end end
end

-- explode a string
function utils.explode(inputstr, sep)
        if sep == nil then sep = "%s" end
        local t = {}
        for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do table.insert(t, str) end
        return t
end

function utils.trim(s)
        s = tostring(s)
        return s:match("^%s*(.-)%s*$"):gsub("[\r\n]+$", "")
end

function utils.round(number, precision)
        if precision == nil then precision = 0 end
        local fmtStr = string.format("%%0.%sf", precision)
        number = string.format(fmtStr, number)
        number = tonumber(number)
        return number
end

-- clear the screen when using lcd functions
function utils.clearScreen()
        local w = LCD_W
        local h = LCD_H
        if isDARKMODE then
                lcd.color(lcd.RGB(40, 40, 40))
        else
                lcd.color(lcd.RGB(240, 240, 240))
        end
        lcd.drawFilledRectangle(0, 0, w, h)
end

-- prevent value going to high or too low
function utils.clipValue(val, min, max)
        if val < min then
                val = min
        elseif val > max then
                val = max
        end
        return val
end

-- return current window size
function utils.getWindowSize()
        return lcd.getWindowSize()
        -- return 784, 406
        -- return 472, 288
        -- return 472, 240
end

-- simple wrapper - long term will enable 
-- dynamic compilation
function utils.loadScript(script)
        -- system.compile(script)
        return compile.loadScript(script)
end

-- return the time
function utils.getTime()
        return os.clock() * 100
end

function utils.joinTableItems(table, delimiter)
        if table == nil or #table == 0 then return "" end
        delimiter = delimiter or ""
        local result = table[1]
        for i = 2, #table do result = result .. delimiter .. table[i] end
        return result
end


-- GET FIELD VALUE FOR ETHOS FORMS.  FUNCTION TAKES THE VALUE AND APPLIES RULES BASED
-- ON THE PARAMETERS ON THE rfsuite.pages TABLE
function utils.getFieldValue(f)

        local v

        if f.value == nil then f.value = 0 end
        if f.t == nil then f.t = "N/A" end

        if f.value ~= nil then
                if f.decimals ~= nil then
                        v = rfsuite.utils.round(f.value * rfsuite.utils.decimalInc(f.decimals))
                else
                        v = f.value
                end
        else
                v = 0
        end

        if f.offset ~= nil then
                v = v + f.offset
        end
        if f.mult ~= nil then v = math.floor(v * f.mult + 0.5) end

        return v
end

-- SAVE FIELD VALUE FOR ETHOS FORMS.  FUNCTION TAKES THE VALUE AND APPLIES RULES BASED
-- ON THE PARAMETERS ON THE rfsuite.pages TABLE
function utils.saveFieldValue(f, value)
        if value ~= nil then
                if f.offset ~= nil then
                        value = value - f.offset
                end        
                if f.decimals ~= nil then
                        f.value = value / rfsuite.utils.decimalInc(f.decimals)
                else
                        f.value = value
                end
                if f.postEdit then f.postEdit(rfsuite.app.Page) end
        end

        if f.mult ~= nil then f.value = f.value / f.mult end

        return f.value
end

function utils.scaleValue(value, f)
        local v
        if value ~= nil then
                v = value * utils.decimalInc(f.decimals)
                if f.scale ~= nil then v = v / f.scale end
                v = utils.round(v)
                return v
        else
                return nil
        end
end

function utils.decimalInc(dec)
        local decTable = {10, 100, 1000, 10000, 100000, 1000000, 10000000, 100000000, 1000000000, 10000000000, 100000000000}

        if dec == nil then
                return 1
        else
                return decTable[dec]
        end
end

-- set positions of form elements
function utils.getInlinePositions(f, lPage)
        local tmp_inline_size = utils.getInlineSize(f.label, lPage)
        local inline_multiplier = rfsuite.app.radio.inlinesize_mult

        local inline_size = tmp_inline_size * inline_multiplier

        LCD_W, LCD_H = utils.getWindowSize()

        local w = LCD_W
        local h = LCD_H
        local colStart

        local padding = 5
        local fieldW = (w * inline_size) / 100

        local eX
        local eW = fieldW - padding
        local eH = rfsuite.app.radio.navbuttonHeight
        local eY = rfsuite.app.radio.linePaddingTop
        local posX
        lcd.font(FONT_STD)
        tsizeW, tsizeH = lcd.getTextSize(f.t)

        if f.inline == 5 then
                posX = w - fieldW * 9 - tsizeW - padding
                posText = {x = posX, y = eY, w = tsizeW, h = eH}

                posX = w - fieldW * 9
                posField = {x = posX, y = eY, w = eW, h = eH}
        elseif f.inline == 4 then
                posX = w - fieldW * 7 - tsizeW - padding
                posText = {x = posX, y = eY, w = tsizeW, h = eH}

                posX = w - fieldW * 7
                posField = {x = posX, y = eY, w = eW, h = eH}
        elseif f.inline == 3 then
                posX = w - fieldW * 5 - tsizeW - padding
                posText = {x = posX, y = eY, w = tsizeW, h = eH}

                posX = w - fieldW * 5
                posField = {x = posX, y = eY, w = eW, h = eH}
        elseif f.inline == 2 then
                posX = w - fieldW * 3 - tsizeW - padding
                posText = {x = posX, y = eY, w = tsizeW, h = eH}

                posX = w - fieldW * 3
                posField = {x = posX, y = eY, w = eW, h = eH}
        elseif f.inline == 1 then
                posX = w - fieldW - tsizeW - padding - padding
                posText = {x = posX, y = eY, w = tsizeW, h = eH}

                posX = w - fieldW - padding
                posField = {x = posX, y = eY, w = eW, h = eH}
        end

        ret = {posText = posText, posField = posField}

        return ret
end

-- find size of elements
function utils.getInlineSize(id, lPage)
        for i, v in ipairs(lPage.labels) do
                if id ~= nil then
                        if v.label == id then
                                local size
                                if v.inline_size == nil then
                                        size = 13.6
                                else
                                        size = v.inline_size
                                end
                                return size

                        end
                end
        end
end

-- write text at given ordinates on screen
function utils.writeText(x, y, str)
        if lcd.darkMode() then
                lcd.color(lcd.RGB(255, 255, 255))
        else
                lcd.color(lcd.RGB(90, 90, 90))
        end
        lcd.drawText(x, y, str)
end

function utils.log(msg)

        if rfsuite.config.logEnable == true then

                if rfsuite.config.logEnableScreen == true then print(msg) end

                local f = io.open(rfsuite.config.suiteDir .. "/logs/rfsuite.log", 'a')
                io.write(f, tostring(msg) .. "\n")
                io.close(f)

        end
end

-- print a table out to debug console
function utils.print_r(node)
        local cache, stack, output = {}, {}, {}
        local depth = 1
        local output_str = "{\n"

        while true do
                local size = 0
                for k, v in pairs(node) do size = size + 1 end

                local cur_index = 1
                for k, v in pairs(node) do
                        if (cache[node] == nil) or (cur_index >= cache[node]) then
                                if (string.find(output_str, "}", output_str:len())) then
                                        output_str = output_str .. ",\n"
                                elseif not (string.find(output_str, "\n", output_str:len())) then
                                        output_str = output_str .. "\n"
                                end

                                -- This is necessary for working with HUGE tables otherwise we run out of memory using concat on huge strings
                                table.insert(output, output_str)
                                output_str = ""

                                local key
                                if (type(k) == "number" or type(k) == "boolean") then
                                        key = "[" .. tostring(k) .. "]"
                                else
                                        key = "['" .. tostring(k) .. "']"
                                end

                                if (type(v) == "number" or type(v) == "boolean") then
                                        output_str = output_str .. string.rep("\t", depth) .. key .. " = " .. tostring(v)
                                elseif (type(v) == "table") then
                                        output_str = output_str .. string.rep("\t", depth) .. key .. " = {\n"
                                        table.insert(stack, node)
                                        table.insert(stack, v)
                                        cache[node] = cur_index + 1
                                        break
                                else
                                        output_str = output_str .. string.rep("\t", depth) .. key .. " = '" .. tostring(v) .. "'"
                                end

                                if (cur_index == size) then
                                        output_str = output_str .. "\n" .. string.rep("\t", depth - 1) .. "}"
                                else
                                        output_str = output_str .. ","
                                end
                        else
                                -- close the table
                                if (cur_index == size) then output_str = output_str .. "\n" .. string.rep("\t", depth - 1) .. "}" end
                        end

                        cur_index = cur_index + 1
                end

                if (size == 0) then output_str = output_str .. "\n" .. string.rep("\t", depth - 1) .. "}" end

                if (#stack > 0) then
                        node = stack[#stack]
                        stack[#stack] = nil
                        depth = cache[node] == nil and depth + 1 or depth - 1
                else
                        break
                end
        end

        -- This is necessary for working with HUGE tables otherwise we run out of memory using concat on huge strings
        table.insert(output, output_str)
        output_str = table.concat(output)

        print(output_str)
end

-- convert a string to a nunber
function utils.makeNumber(x)
        if x == nil or x == "" then x = 0 end

        x = string.gsub(x, "%D+", "")
        x = tonumber(x)
        if x == nil or x == "" then x = 0 end

        return x
end

-- used to take tables from format used in pages
-- and convert them to an ethos forms format
function utils.convertPageValueTable(tbl, inc)
        local thetable = {}

        if inc == nil then inc = 0 end

        if tbl[0] ~= nil then
                thetable[0] = {}
                thetable[0][1] = tbl[0]
                thetable[0][2] = 0
        end
        for idx, value in ipairs(tbl) do
                thetable[idx] = {}
                thetable[idx][1] = value
                thetable[idx][2] = idx + inc
        end

        return thetable
end


return utils
