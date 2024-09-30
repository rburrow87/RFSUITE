local function postLoad(self)
        rfsuite.app.triggers.closeProgressLoader = true
end

local function openPage(idx, title, script)
        rfsuite.app.uiState = rfsuite.app.uiStatus.pages
        rfsuite.app.triggers.isReady = false

        rfsuite.app.lastIdx = idx
        rfsuite.app.lastTitle = title
        rfsuite.app.lastScript = script
        -- rfsuite.app.Page = nil

        form.clear()

        local w, h = rfsuite.utils.getWindowSize()

        -- column starts at 59.4% of w
        padding = 5
        colStart = math.floor((w * 59.4) / 100)
        if rfsuite.app.radio.navButtonOffset ~= nil then colStart = colStart - rfsuite.app.radio.navButtonOffset end

        if rfsuite.app.radio.buttonWidth == nil then
                buttonW = (w - colStart) / 3 - padding
        else
                buttonW = rfsuite.app.radio.buttonWidth
        end
        buttonH = rfsuite.app.radio.navbuttonHeight

        local x = w

        line = form.addLine("Preferences")

        rfsuite.app.formNavigationFields['menu'] = form.addButton(line, {x = x - (buttonW + padding) * 1, y = rfsuite.app.radio.linePaddingTop, w = buttonW, h = buttonH}, {
                text = "MENU",
                icon = nil,
                options = FONT_S,
                paint = function()
                end,
                press = function()
                        rfsuite.app.lastIdx = nil
                        rfsuite.lastPage = nil

                        if rfsuite.app.Page and rfsuite.app.Page.onNavMenu then rfsuite.app.Page.onNavMenu(rfsuite.app.Page) end

                        rfsuite.app.ui.openMainMenu()
                end
        })
        rfsuite.app.formNavigationFields['menu']:focus()

        local uipanel = form.addExpansionPanel("User interface")
        uipanel:open(true)

        rfsuite.config.audioParam = rfsuite.app.preferences.interface.audio
        if rfsuite.config.audioParam == nil or rfsuite.config.audioParam == "" then rfsuite.config.audioParam = 0 end

        line = uipanel:addLine("Audio")
        rfsuite.app.formFields[0] = form.addChoiceField(line, nil, {{"All", 0}, {"Alerts", 1}, {"Disable", 2}}, function()
                return rfsuite.config.audioParam
        end, function(newValue)
                rfsuite.config.audioParam = newValue
                rfsuite.app.preferences.interface.audio = newValue
                rfsuite.app.ini.save(rfsuite.config.suiteDir .. 'preferences.ini',rfsuite.app.preferences)
        end)

        rfsuite.config.iconsizeParam = rfsuite.app.preferences.interface.iconSize
        if rfsuite.config.iconsizeParam == nil or rfsuite.config.iconsizeParam == "" then rfsuite.config.iconsizeParam = 1 end

        line = uipanel:addLine("Button style")
        rfsuite.app.formFields[1] = form.addChoiceField(line, nil, {{"Text", 0}, {"Small image", 1}, {"Large images", 2}}, function()
                return rfsuite.config.iconsizeParam
        end, function(newValue)
                rfsuite.config.iconsizeParam = newValue
                rfsuite.app.preferences.interface.iconSize = newValue
                rfsuite.app.ini.save(rfsuite.config.suiteDir .. 'preferences.ini',rfsuite.app.preferences)
        end)

        -- PROFILE
        rfsuite.config.profileswitchParam = rfsuite.app.preferences.interface.profileSwitch
        if rfsuite.config.profileswitchParam == nil or rfsuite.config.profileswitchParam == "" then rfsuite.config.profileswitchParam = 0 end

        line = uipanel:addLine("Profile Switching")
        rfsuite.app.formFields[2] = form.addChoiceField(line, nil, {{"Enable", 0}, {"Disable", 1}}, function()
                return rfsuite.config.profileswitchParam
        end, function(newValue)
                rfsuite.config.profileswitchParam = newValue
                rfsuite.app.preferences.interface.profileSwitch = newValue
                rfsuite.app.ini.save(rfsuite.config.suiteDir .. 'preferences.ini',rfsuite.app.preferences)
        end)


        local advpanel = form.addExpansionPanel("Advanced")
        advpanel:open(true)

        -- TIMEOUT
        rfsuite.config.watchdogParam = rfsuite.app.preferences.advanced.watchdog
        if rfsuite.config.watchdogParam == nil or rfsuite.config.watchdogParam == "" then rfsuite.config.watchdogParam = 15 end
        line = advpanel:addLine("Timeout")
        rfsuite.app.formFields[4] = form.addChoiceField(line, nil, {{"Default", 15}, {"10s", 10}, {"15s", 15}, {"20s", 20}, {"25s", 25}, {"30s", 30}}, function()
                return rfsuite.config.watchdogParam
        end, function(newValue)
                rfsuite.config.watchdogParam = newValue
                rfsuite.app.preferences.advanced.watchdog = newValue
                rfsuite.app.ini.save(rfsuite.config.suiteDir .. 'preferences.ini',rfsuite.app.preferences)
        end)

        -- DEMO MODE
        rfsuite.config.demoswitchParamPreference = rfsuite.app.preferences.advanced.demoSwitch
        if rfsuite.config.demoswitchParamPreference ~= nil then
                local s = rfsuite.utils.explode(rfsuite.config.demoswitchParamPreference, ",")
                rfsuite.config.demoswitchParam = system.getSource({category = s[1], member = s[2]})
        end

        line = advpanel:addLine("Demo mode")
        rfsuite.app.formFields[7] = form.addSwitchField(line, nil, function()
                return rfsuite.config.demoswitchParam
        end, function(newValue)
                rfsuite.config.demoswitchParam = newValue
                local member = rfsuite.config.demoswitchParam:member()
                local category = rfsuite.config.demoswitchParam:category()
                rfsuite.app.preferences.advanced.demoSwitch = category .. "," .. member                 
                rfsuite.app.ini.save(rfsuite.config.suiteDir .. 'preferences.ini',rfsuite.app.preferences)
        end)

        postLoad()

end

return {title = "Preferences", openPage = openPage}
