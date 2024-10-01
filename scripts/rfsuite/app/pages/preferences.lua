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

        rfsuite.config.audioParam = rfsuite.app.preferences.interface.audio
        if rfsuite.config.audioParam == nil or rfsuite.config.audioParam == "" then rfsuite.config.audioParam = 0 end

        line = form.addLine("Audio")
        rfsuite.app.formFields[0] = form.addChoiceField(line, nil, {{"All", 0}, {"Alerts", 1}, {"Disable", 2}}, function()
                return rfsuite.config.audioParam
        end, function(newValue)
                rfsuite.config.audioParam = newValue
                rfsuite.app.preferences.interface.audio = newValue
                rfsuite.app.ini.save(rfsuite.config.suiteDir .. 'preferences.ini',rfsuite.app.preferences)
        end)

        rfsuite.config.iconsizeParam = rfsuite.app.preferences.interface.iconSize
        if rfsuite.config.iconsizeParam == nil or rfsuite.config.iconsizeParam == "" then rfsuite.config.iconsizeParam = 1 end

        line = form.addLine("Button style")
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

        line = form.addLine("Profile Switching")
        rfsuite.app.formFields[2] = form.addChoiceField(line, nil, {{"Enable", 0}, {"Disable", 1}}, function()
                return rfsuite.config.profileswitchParam
        end, function(newValue)
                rfsuite.config.profileswitchParam = newValue
                rfsuite.app.preferences.interface.profileSwitch = newValue
                rfsuite.app.ini.save(rfsuite.config.suiteDir .. 'preferences.ini',rfsuite.app.preferences)
        end)


        postLoad()

end

return {title = "Preferences", openPage = openPage}
