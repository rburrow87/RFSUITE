local pages = {}

pages[#pages + 1] = {title = "SCORPION", folder = "scorp", image = "scorpion.png"}
pages[#pages + 1] = {title = "HOBBYWING 5", folder = "hw5", image = "hobbywing.png"}
pages[#pages + 1] = {title = "YGE", folder = "yge", image = "yge.png"}
pages[#pages + 1] = {title = "FLYROTOR", folder = "flrtr", image = "flrtr.png"}
pages[#pages + 1] = {title = "XDFLY", folder = "flrtr", image = "xdfly.png", disabled = true}

local function openPage(pidx, title, script)

        rfsuite.bg.msp.protocol.mspIntervalOveride = nil

        if tonumber(rfsuite.utils.makeNumber(rfsuite.config.environment.major .. rfsuite.config.environment.minor .. rfsuite.config.environment.revision)) < rfsuite.config.ethosVersion then return end

        rfsuite.app.triggers.isReady = false
        rfsuite.app.uiState = rfsuite.app.uiStatus.mainMenu

        form.clear()

        rfsuite.app.lastIdx = idx
        rfsuite.app.lastTitle = title
        rfsuite.app.lastScript = script

        ESC = {}

        -- size of buttons
        rfsuite.config.iconsizeParam = rfsuite.app.preferences.interface.iconSize
        if rfsuite.config.iconsizeParam == nil or rfsuite.config.iconsizeParam == "" then
                rfsuite.config.iconsizeParam = 1
        else
                rfsuite.config.iconsizeParam = tonumber(rfsuite.config.iconsizeParam)
        end

        local w, h = rfsuite.utils.getWindowSize()
        local windowWidth = w
        local windowHeight = h
        local padding = rfsuite.app.radio.buttonPadding

        local sc
        local panel

        form.addLine(title)

        buttonW = 100
        local x = windowWidth - buttonW - 10

        rfsuite.app.formNavigationFields['menu'] = form.addButton(line, {x = x, y = rfsuite.app.radio.linePaddingTop, w = buttonW, h = rfsuite.app.radio.navbuttonHeight}, {
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

        local buttonW
        local buttonH
        local padding
        local numPerRow

        -- TEXT ICONS
        -- TEXT ICONS
        if rfsuite.config.iconsizeParam == 0 then
                padding = rfsuite.app.radio.buttonPaddingSmall
                buttonW = (rfsuite.config.lcdWidth - padding) / rfsuite.app.radio.buttonsPerRow - padding
                buttonH = rfsuite.app.radio.navbuttonHeight
                numPerRow = rfsuite.app.radio.buttonsPerRow
        end
        -- SMALL ICONS
        if rfsuite.config.iconsizeParam == 1 then

                padding = rfsuite.app.radio.buttonPaddingSmall
                buttonW = rfsuite.app.radio.buttonWidthSmall
                buttonH = rfsuite.app.radio.buttonHeightSmall
                numPerRow = rfsuite.app.radio.buttonsPerRowSmall
        end
        -- LARGE ICONS
        if rfsuite.config.iconsizeParam == 2 then

                padding = rfsuite.app.radio.buttonPadding
                buttonW = rfsuite.app.radio.buttonWidth
                buttonH = rfsuite.app.radio.buttonHeight
                numPerRow = rfsuite.app.radio.buttonsPerRow
        end

        local ESCMenu = assert(compile.loadScript(rfsuite.config.suiteDir .. "app/pages/" .. script))()

        local lc = 0
        local bx = 0

        if rfsuite.app.gfx_buttons["escmain"] == nil then rfsuite.app.gfx_buttons["escmain"] = {} end
        if rfsuite.app.menuLastSelected["escmain"] == nil then rfsuite.app.menuLastSelected["escmain"] = 1 end

        for pidx, pvalue in ipairs(ESCMenu.pages) do

                if lc == 0 then
                        if rfsuite.config.iconsizeParam == 0 then y = form.height() + rfsuite.app.radio.buttonPaddingSmall end
                        if rfsuite.config.iconsizeParam == 1 then y = form.height() + rfsuite.app.radio.buttonPaddingSmall end
                        if rfsuite.config.iconsizeParam == 2 then y = form.height() + rfsuite.app.radio.buttonPadding end
                end

                if lc >= 0 then bx = (buttonW + padding) * lc end

                if rfsuite.config.iconsizeParam ~= 0 then
                        if rfsuite.app.gfx_buttons["escmain"][pidx] == nil then rfsuite.app.gfx_buttons["escmain"][pidx] = lcd.loadMask(rfsuite.config.suiteDir .. "app/gfx/esc/" .. pvalue.image) end
                else
                        rfsuite.app.gfx_buttons["escmain"][pidx] = nil
                end

                rfsuite.app.formFields[pidx] = form.addButton(line, {x = bx, y = y, w = buttonW, h = buttonH}, {
                        text = pvalue.title,
                        icon = rfsuite.app.gfx_buttons["escmain"][pidx],
                        options = FONT_S,
                        paint = function()
                        end,
                        press = function()
                                rfsuite.app.menuLastSelected["escmain"] = pidx
                                rfsuite.app.ui.progessDisplay()
                                rfsuite.app.ui.openPage(pidx, pvalue.folder, "esc_tool.lua")
                        end
                })

                if pvalue.disabled == true then rfsuite.app.formFields[pidx]:enable(false) end

                if rfsuite.app.menuLastSelected["escmain"] == pidx then rfsuite.app.formFields[pidx]:focus() end

                lc = lc + 1

                if lc == numPerRow then lc = 0 end

        end

        rfsuite.app.triggers.closeProgressLoader = true

        return
end

rfsuite.app.uiState = rfsuite.app.uiStatus.pages

return {title = "ESC", pages = pages, openPage = openPage}