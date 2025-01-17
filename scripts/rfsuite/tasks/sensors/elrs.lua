--
-- Rotorflight Custom Telemetry Decoder for ELRS
--
--
local arg = {...}
local config = arg[1]
local compile = arg[2]


local elrs = {}

local sensors = {}
sensors['uid'] = {}
sensors['lastvalue'] = {}

local rssiSensor = nil

local CRSF_FRAME_CUSTOM_TELEM = 0x88

local function createTelemetrySensor(uid, name, unit, dec, value, min, max)
        sensors['uid'][uid] = model.createSensor()
        sensors['uid'][uid]:name(name)
        sensors['uid'][uid]:appId(uid)
        sensors['uid'][uid]:module(1)
        sensors['uid'][uid]:minimum(min or -2147483647)
        sensors['uid'][uid]:maximum(max or 2147483647)
        if dec then
                sensors['uid'][uid]:decimals(dec)
                sensors['uid'][uid]:protocolDecimals(dec)
        end
        if unit then
                sensors['uid'][uid]:unit(unit)
                sensors['uid'][uid]:protocolUnit(unit)
        end
        if value then sensors['uid'][uid]:value(value) end
end

local function setTelemetryValue(uid, subid, instance, value, unit, dec, name, min, max)

        if sensors['uid'][uid] == nil then
                sensors['uid'][uid] = system.getSource({category = CATEGORY_TELEMETRY_SENSOR, appId = uid})
                if sensors['uid'][uid] == nil then
                        print("Create sensor: " .. uid)
                        createTelemetrySensor(uid, name, unit, dec, value, min, max)
                end
        else
                if sensors['uid'][uid] then
                        if sensors['lastvalue'][uid] == nil or sensors['lastvalue'][uid] ~= value then sensors['uid'][uid]:value(value) end

                        -- detect if sensor has been deleted or is missing after initial creation
                        if sensors['uid'][uid]:state() == false then
                                sensors['uid'][uid] = nil
                                sensors['lastvalue'][uid] = nil
                        end

                end
        end
end

local function decNil(data, pos)
        return nil, pos
end

local function decU8(data, pos)
        return data[pos], pos + 1
end

local function decS8(data, pos)
        local val, ptr = decU8(data, pos)
        return val < 0x80 and val or val - 0x100, ptr
end

local function decU16(data, pos)
        return (data[pos] << 8) | data[pos + 1], pos + 2
end

local function decS16(data, pos)
        local val, ptr = decU16(data, pos)
        return val < 0x8000 and val or val - 0x10000, ptr
end

local function decU12U12(data, pos)
        local a = ((data[pos] & 0x0F) << 8) | data[pos + 1]
        local b = ((data[pos] & 0xF0) << 4) | data[pos + 2]
        return a, b, pos + 3
end

local function decS12S12(data, pos)
        local a, b, ptr = decU12U12(data, pos)
        return a < 0x0800 and a or a - 0x1000, b < 0x0800 and b or b - 0x1000, ptr
end

local function decU24(data, pos)
        return (data[pos] << 16) | (data[pos + 1] << 8) | data[pos + 2], pos + 3
end

local function decS24(data, pos)
        local val, ptr = decU24(data, pos)
        return val < 0x800000 and val or val - 0x1000000, ptr
end

local function decU32(data, pos)
        return (data[pos] << 24) | (data[pos + 1] << 16) | (data[pos + 2] << 8) | data[pos + 3], pos + 4
end

local function decS32(data, pos)
        local val, ptr = decU32(data, pos)
        return val < 0x80000000 and val or val - 0x100000000, ptr
end

local function decCellV(data, pos)
        local val, ptr = decU8(data, pos)
        return val > 0 and val + 200 or 0, ptr
end

local function decCells(data, pos)
        local cnt, val, vol
        cnt, pos = decU8(data, pos)
        setTelemetryValue(0x1020, 0, 0, cnt, UNIT_RAW, 0, "Cel#", 0, 15)
        for i = 1, cnt do
                val, pos = decU8(data, pos)
                val = val > 0 and val + 200 or 0
                vol = (cnt << 24) | ((i - 1) << 16) | val
                setTelemetryValue(0x102F, 0, 0, vol, UNIT_CELLS, 2, "Cels", 0, 455)
        end
        return nil, pos
end

local function decControl(data, pos)
        local r, p, y, c
        p, r, pos = decS12S12(data, pos)
        y, c, pos = decS12S12(data, pos)
        setTelemetryValue(0x1031, 0, 0, p, UNIT_DEGREE, 2, "CPtc", -4500, 4500)
        setTelemetryValue(0x1032, 0, 0, r, UNIT_DEGREE, 2, "CRol", -4500, 4500)
        setTelemetryValue(0x1033, 0, 0, y, UNIT_DEGREE, 2, "CYaw", -9000, 9000)
        setTelemetryValue(0x1034, 0, 0, c, UNIT_DEGREE, 2, "CCol", -4500, 4500)
        return nil, pos
end

local function decAttitude(data, pos)
        local p, r, y
        p, pos = decS16(data, pos)
        r, pos = decS16(data, pos)
        y, pos = decS16(data, pos)
        setTelemetryValue(0x1101, 0, 0, p, UNIT_DEGREE, 1, "Ptch", -1800, 3600)
        setTelemetryValue(0x1102, 0, 0, r, UNIT_DEGREE, 1, "Roll", -1800, 3600)
        setTelemetryValue(0x1103, 0, 0, y, UNIT_DEGREE, 1, "Yaw", -1800, 3600)
        return nil, pos
end

local function decAccel(data, pos)
        local x, y, z
        x, pos = decS16(data, pos)
        y, pos = decS16(data, pos)
        z, pos = decS16(data, pos)
        setTelemetryValue(0x1111, 0, 0, x, UNIT_G, 2, "AccX", -4000, 4000)
        setTelemetryValue(0x1112, 0, 0, y, UNIT_G, 2, "AccY", -4000, 4000)
        setTelemetryValue(0x1113, 0, 0, z, UNIT_G, 2, "AccZ", -4000, 4000)
        return nil, pos
end

local function decLatLong(data, pos)
        local lat, lon
        lat, pos = decS32(data, pos)
        lon, pos = decS32(data, pos)
        setTelemetryValue(0x1125, 0, 0, 0, UNIT_GPS, 0, "GPS")
        setTelemetryValue(0x1125, 0, 0, lat, UNIT_GPS_LATITUDE)
        setTelemetryValue(0x1125, 0, 0, lon, UNIT_GPS_LONGITUDE)
        return nil, pos
end

local function decAdjFunc(data, pos)
        local fun, val
        fun, pos = decU16(data, pos)
        val, pos = decS32(data, pos)
        setTelemetryValue(0x1221, 0, 0, fun, UNIT_RAW, 0, "AdjF", 0, 255)
        setTelemetryValue(0x1222, 0, 0, val, UNIT_RAW, 0, "AdjV")
        return nil, pos
end

elrs.RFSensors = {
        -- No data
        [0x1000] = {name = "NULL", unit = UNIT_RAW, prec = 0, min = nil, max = nil, dec = decNil},
        -- Heartbeat (millisecond uptime % 60000)
        [0x1001] = {name = "BEAT", unit = UNIT_RAW, prec = 0, min = 0, max = 60000, dec = decU16},

        -- Main battery voltage
        [0x1011] = {name = "Vbat", unit = UNIT_VOLT, prec = 2, min = 0, max = 6500, dec = decU16},
        -- Main battery current
        [0x1012] = {name = "Curr", unit = UNIT_AMPERE, prec = 2, min = 0, max = 65000, dec = decU16},
        -- Main battery used capacity
        [0x1013] = {name = "Capa", unit = UNIT_MILLIAMPERE_HOUR, prec = 0, min = 0, max = 65000, dec = decU16},
        -- Main battery charge / fuel level
        [0x1014] = {name = "Bat%", unit = UNIT_PERCENT, prec = 0, min = 0, max = 100, dec = decU8},

        -- Main battery cell count
        [0x1020] = {name = "Cel#", unit = UNIT_RAW, prec = 0, min = 0, max = 16, dec = decU8},
        -- Main battery cell voltage (minimum/average)
        [0x1021] = {name = "Vcel", unit = UNIT_VOLT, prec = 2, min = 0, max = 455, dec = decCellV},
        -- Main battery cell voltages
        [0x102F] = {name = "Cels", unit = UNIT_VOLT, prec = 2, min = nil, max = nil, dec = decCells},

        -- Control Combined (hires)
        [0x1030] = {name = "Ctrl", unit = UNIT_RAW, prec = 0, min = nil, max = nil, dec = decControl},
        -- Pitch Control angle
        [0x1031] = {name = "CPtc", unit = UNIT_DEGREE, prec = 1, min = -450, max = 450, dec = decS16},
        -- Roll Control angle
        [0x1032] = {name = "CRol", unit = UNIT_DEGREE, prec = 1, min = -450, max = 450, dec = decS16},
        -- Yaw Control angle
        [0x1033] = {name = "CYaw", unit = UNIT_DEGREE, prec = 1, min = -900, max = 900, dec = decS16},
        -- Collective Control angle
        [0x1034] = {name = "CCol", unit = UNIT_DEGREE, prec = 1, min = -450, max = 450, dec = decS16},
        -- Throttle output %
        [0x1035] = {name = "Thr", unit = UNIT_PERCENT, prec = 0, min = -100, max = 100, dec = decS8},

        -- ESC#1 voltage
        [0x1041] = {name = "EscV", unit = UNIT_VOLT, prec = 2, min = 0, max = 6500, dec = decU16},
        -- ESC#1 current
        [0x1042] = {name = "EscI", unit = UNIT_AMPERE, prec = 2, min = 0, max = 65000, dec = decU16},
        -- ESC#1 capacity/consumption
        [0x1043] = {name = "EscC", unit = UNIT_MILLIAMPERE_HOUR, prec = 0, min = 0, max = 65000, dec = decU16},
        -- ESC#1 eRPM
        [0x1044] = {name = "EscR", unit = UNIT_RPM, prec = 0, min = 0, max = 65535, dec = decU16},
        -- ESC#1 PWM/Power
        [0x1045] = {name = "EscP", unit = UNIT_PERCENT, prec = 1, min = 0, max = 1000, dec = decU16},
        -- ESC#1 throttle
        [0x1046] = {name = "Esc%", unit = UNIT_PERCENT, prec = 1, min = 0, max = 1000, dec = decU16},
        -- ESC#1 temperature
        [0x1047] = {name = "EscT", unit = UNIT_CELSIUS, prec = 0, min = 0, max = 255, dec = decU8},
        -- ESC#1 / BEC temperature
        [0x1048] = {name = "BecT", unit = UNIT_CELSIUS, prec = 0, min = 0, max = 255, dec = decU8},
        -- ESC#1 / BEC voltage
        [0x1049] = {name = "BecV", unit = UNIT_VOLT, prec = 2, min = 0, max = 1500, dec = decU16},
        -- ESC#1 / BEC current
        [0x104A] = {name = "BecI", unit = UNIT_AMPERE, prec = 2, min = 0, max = 10000, dec = decU16},
        -- ESC#1 Status Flags
        [0x104E] = {name = "EscF", unit = UNIT_RAW, prec = 0, min = 0, max = 2147483647, dec = decU32},
        -- ESC#1 Model Id
        [0x104F] = {name = "Esc#", unit = UNIT_RAW, prec = 0, min = 0, max = 255, dec = decU8},

        -- ESC#2 voltage
        [0x1051] = {name = "Es2V", unit = UNIT_VOLT, prec = 2, min = 0, max = 6500, dec = decU16},
        -- ESC#2 current
        [0x1052] = {name = "Es2I", unit = UNIT_AMPERE, prec = 2, min = 0, max = 65000, dec = decU16},
        -- ESC#2 capacity/consumption
        [0x1053] = {name = "Es2C", unit = UNIT_MILLIAMPERE_HOUR, prec = 0, min = 0, max = 65000, dec = decU16},
        -- ESC#2 eRPM
        [0x1054] = {name = "Es2R", unit = UNIT_RPM, prec = 0, min = 0, max = 65535, dec = decU16},
        -- ESC#2 temperature
        [0x1057] = {name = "Es2T", unit = UNIT_CELSIUS, prec = 0, min = 0, max = 255, dec = decU8},
        -- ESC#2 Model Id
        [0x105F] = {name = "Es2#", unit = UNIT_RAW, prec = 0, min = 0, max = 255, dec = decU8},

        -- Combined ESC voltage
        [0x1080] = {name = "Vesc", unit = UNIT_VOLT, prec = 2, min = 0, max = 6500, dec = decU16},
        -- BEC voltage
        [0x1081] = {name = "Vbec", unit = UNIT_VOLT, prec = 2, min = 0, max = 1600, dec = decU16},
        -- BUS voltage
        [0x1082] = {name = "Vbus", unit = UNIT_VOLT, prec = 2, min = 0, max = 1200, dec = decU16},
        -- MCU voltage
        [0x1083] = {name = "Vmcu", unit = UNIT_VOLT, prec = 2, min = 0, max = 500, dec = decU16},

        -- Combined ESC current
        [0x1090] = {name = "Iesc", unit = UNIT_AMPERE, prec = 2, min = 0, max = 65000, dec = decU16},
        -- BEC current
        [0x1091] = {name = "Ibec", unit = UNIT_AMPERE, prec = 2, min = 0, max = 10000, dec = decU16},
        -- BUS current
        [0x1092] = {name = "Ibus", unit = UNIT_AMPERE, prec = 2, min = 0, max = 1000, dec = decU16},
        -- MCU current
        [0x1093] = {name = "Imcu", unit = UNIT_AMPERE, prec = 2, min = 0, max = 1000, dec = decU16},

        -- Combined ESC temeperature
        [0x10A0] = {name = "Tesc", unit = UNIT_CELSIUS, prec = 0, min = 0, max = 255, dec = decU8},
        -- BEC temperature
        [0x10A1] = {name = "Tbec", unit = UNIT_CELSIUS, prec = 0, min = 0, max = 255, dec = decU8},
        -- MCU temperature
        [0x10A3] = {name = "Tmcu", unit = UNIT_CELSIUS, prec = 0, min = 0, max = 255, dec = decU8},

        -- Heading (combined gyro+mag+GPS)
        [0x10B1] = {name = "Hdg", unit = UNIT_DEGREE, prec = 1, min = -1800, max = 3600, dec = decS16},
        -- Altitude (combined baro+GPS)
        [0x10B2] = {name = "Alt", unit = UNIT_METER, prec = 2, min = -100000, max = 100000, dec = decS24},
        -- Variometer (combined baro+GPS)
        [0x10B3] = {name = "Var", unit = UNIT_METER_PER_SECOND, prec = 2, min = -10000, max = 10000, dec = decS16},

        -- Headspeed
        [0x10C0] = {name = "Hspd", unit = UNIT_RPM, prec = 0, min = 0, max = 65535, dec = decU16},
        -- Tailspeed
        [0x10C1] = {name = "Tspd", unit = UNIT_RPM, prec = 0, min = 0, max = 65535, dec = decU16},

        -- Attitude (hires combined)
        [0x1100] = {name = "Attd", unit = UNIT_DEGREE, prec = 1, min = nil, max = nil, dec = decAttitude},
        -- Attitude pitch
        [0x1101] = {name = "Ptch", unit = UNIT_DEGREE, prec = 0, min = -180, max = 360, dec = decS16},
        -- Attitude roll
        [0x1102] = {name = "Roll", unit = UNIT_DEGREE, prec = 0, min = -180, max = 360, dec = decS16},
        -- Attitude yaw
        [0x1103] = {name = "Yaw", unit = UNIT_DEGREE, prec = 0, min = -180, max = 360, dec = decS16},

        -- Acceleration (hires combined)
        [0x1110] = {name = "Accl", unit = UNIT_G, prec = 2, min = nil, max = nil, dec = decAccel},
        -- Acceleration X
        [0x1111] = {name = "AccX", unit = UNIT_G, prec = 1, min = -4000, max = 4000, dec = decS16},
        -- Acceleration Y
        [0x1112] = {name = "AccY", unit = UNIT_G, prec = 1, min = -4000, max = 4000, dec = decS16},
        -- Acceleration Z
        [0x1113] = {name = "AccZ", unit = UNIT_G, prec = 1, min = -4000, max = 4000, dec = decS16},

        -- GPS Satellite count
        [0x1121] = {name = "Sats", unit = UNIT_RAW, prec = 0, min = 0, max = 255, dec = decU8},
        -- GPS PDOP
        [0x1122] = {name = "PDOP", unit = UNIT_RAW, prec = 0, min = 0, max = 255, dec = decU8},
        -- GPS HDOP
        [0x1123] = {name = "HDOP", unit = UNIT_RAW, prec = 0, min = 0, max = 255, dec = decU8},
        -- GPS VDOP
        [0x1124] = {name = "VDOP", unit = UNIT_RAW, prec = 0, min = 0, max = 255, dec = decU8},
        -- GPS Coordinates
        [0x1125] = {name = "GPS", unit = UNIT_RAW, prec = 0, min = nil, max = nil, dec = decLatLong},
        -- GPS altitude
        [0x1126] = {name = "GAlt", unit = UNIT_METER, prec = 1, min = -10000, max = 10000, dec = decS16},
        -- GPS heading
        [0x1127] = {name = "GHdg", unit = UNIT_DEGREE, prec = 1, min = -1800, max = 3600, dec = decS16},
        -- GPS ground speed
        [0x1128] = {name = "GSpd", unit = UNIT_METER_PER_SECOND, prec = 2, min = 0, max = 10000, dec = decU16},
        -- GPS home distance
        [0x1129] = {name = "GDis", unit = UNIT_METER, prec = 1, min = 0, max = 65535, dec = decU16},
        -- GPS home direction
        [0x112A] = {name = "GDir", unit = UNIT_METER, prec = 1, min = 0, max = 3600, dec = decU16},

        -- CPU load
        [0x1141] = {name = "CPU%", unit = UNIT_PERCENT, prec = 0, min = 0, max = 100, dec = decU8},
        -- System load
        [0x1142] = {name = "SYS%", unit = UNIT_PERCENT, prec = 0, min = 0, max = 10, dec = decU8},
        -- Realtime CPU load
        [0x1143] = {name = "RT%", unit = UNIT_PERCENT, prec = 0, min = 0, max = 200, dec = decU8},

        -- Model ID
        [0x1200] = {name = "MDL#", unit = UNIT_RAW, prec = 0, min = 0, max = 255, dec = decU8},
        -- Flight mode flags
        [0x1201] = {name = "Mode", unit = UNIT_RAW, prec = 0, min = 0, max = 65535, dec = decU16},
        -- Arming flags
        [0x1202] = {name = "ARM", unit = UNIT_RAW, prec = 0, min = 0, max = 255, dec = decU8},
        -- Arming disable flags
        [0x1203] = {name = "ARMD", unit = UNIT_RAW, prec = 0, min = 0, max = 2147483647, dec = decU32},
        -- Rescue state
        [0x1204] = {name = "Resc", unit = UNIT_RAW, prec = 0, min = 0, max = 255, dec = decU8},
        -- Governor state
        [0x1205] = {name = "Gov", unit = UNIT_RAW, prec = 0, min = 0, max = 255, dec = decU8},

        -- Current PID profile
        [0x1211] = {name = "PID#", unit = UNIT_RAW, prec = 0, min = 1, max = 6, dec = decU8},
        -- Current Rate profile
        [0x1212] = {name = "RTE#", unit = UNIT_RAW, prec = 0, min = 1, max = 6, dec = decU8},
        -- Current LED profile
        [0x1213] = {name = "LED#", unit = UNIT_RAW, prec = 0, min = 1, max = 6, dec = decU8},

        -- Adjustment function
        [0x1220] = {name = "ADJ", unit = UNIT_RAW, prec = 0, min = nil, max = nil, dec = decAdjFunc},

        -- Debug
        [0xDB00] = {name = "DBG0", unit = UNIT_RAW, prec = 0, min = nil, max = nil, dec = decS32},
        [0xDB01] = {name = "DBG1", unit = UNIT_RAW, prec = 0, min = nil, max = nil, dec = decS32},
        [0xDB02] = {name = "DBG2", unit = UNIT_RAW, prec = 0, min = nil, max = nil, dec = decS32},
        [0xDB03] = {name = "DBG3", unit = UNIT_RAW, prec = 0, min = nil, max = nil, dec = decS32},
        [0xDB04] = {name = "DBG4", unit = UNIT_RAW, prec = 0, min = nil, max = nil, dec = decS32},
        [0xDB05] = {name = "DBG5", unit = UNIT_RAW, prec = 0, min = nil, max = nil, dec = decS32},
        [0xDB06] = {name = "DBG6", unit = UNIT_RAW, prec = 0, min = nil, max = nil, dec = decS32},
        [0xDB07] = {name = "DBG7", unit = UNIT_RAW, prec = 0, min = nil, max = nil, dec = decS32}
}

elrs.telemetryFrameId = 0
elrs.telemetryFrameSkip = 0
elrs.telemetryFrameCount = 0



function elrs.crossfirePop()

        if (CRSF_PAUSE_TELEMETRY == true or rfsuite.app.triggers.mspBusy == true) then
                return false
        else

                local command, data = crsf.popFrame()
                if command and data then

                        if command == CRSF_FRAME_CUSTOM_TELEM then
                                local fid, sid, val
                                local ptr = 3
                                fid, ptr = decU8(data, ptr)
                                local delta = (fid - elrs.telemetryFrameId) & 0xFF
                                if delta > 1 then elrs.telemetryFrameSkip = elrs.telemetryFrameSkip + 1 end
                                elrs.telemetryFrameId = fid
                                elrs.telemetryFrameCount = elrs.telemetryFrameCount + 1
                                while ptr < #data  do
                                                                      
                                        sid, ptr = decU16(data, ptr)
                                        local sensor = elrs.RFSensors[sid]
                                        if sensor then
                                                val, ptr = sensor.dec(data, ptr)
                                                if val then setTelemetryValue(sid, 0, 0, val, sensor.unit, sensor.prec, sensor.name, sensor.min, sensor.max) end
                                        else
                                                break
                                        end
                                end
                                setTelemetryValue(0xEE01, 0, 0, elrs.telemetryFrameCount, UNIT_RAW, 0, "*Cnt", 0, 2147483647)
                                setTelemetryValue(0xEE02, 0, 0, elrs.telemetryFrameSkip, UNIT_RAW, 0, "*Skp", 0, 2147483647)
                                -- setTelemetryValue(0xEE03, 0, 0, elrs.telemetryFrameId, UNIT_RAW, 0, "*Frm", 0, 255)
                        end
                  
                        return true
                end
                 

                return false
       end         
end

function elrs.wakeup()


        if rfsuite.bg.telemetry.active() and rfsuite.rssiSensor  then
                while elrs.crossfirePop() do 
                        if (CRSF_PAUSE_TELEMETRY == true or rfsuite.app.triggers.mspBusy == true) then
                                break
                        end              
                end
        end
end

return elrs
