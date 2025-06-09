

-----
-- Keyboard
-----
-- https://forum.cfx.re/t/use-displayonscreenkeyboard-properly/51143/2
function KeyboardInput(TextEntry, InputText, MaxStringLength)
    -- TextEntry		-->	The Text above the typing field in the black square
    -- ExampleText		-->	An Example Text, what it should say in the typing field
    -- MaxStringLenght	-->	Maximum String Lenght

    AddTextEntry('FMMC_KEY_TIP1', TextEntry)                                             --Sets the Text above the typing field in the black square
    -- DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP1", "", ExampleText, "", "", "", MaxStringLenght) --Actually calls the Keyboard Input
    DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP1", "", InputText, "", "", "", MaxStringLength) --Actually calls the Keyboard Input
    blockinput = true                                                                    --Blocks new input while typing if **blockinput** is used

    while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do             --While typing is not aborted and not finished, this loop waits
        Citizen.Wait(0)
    end

    if UpdateOnscreenKeyboard() ~= 2 then
        local result = GetOnscreenKeyboardResult() --Gets the result of the typing
        Citizen.Wait(500)                    --Little Time Delay, so the Keyboard won't open again if you press enter to finish the typing
        blockinput = false                   --This unblocks new Input when typing is done
        return result                        --Returns the result
    else
        Citizen.Wait(500)                    --Little Time Delay, so the Keyboard won't open again if you press enter to finish the typing
        blockinput = false                   --This unblocks new Input when typing is done
        return nil                           --Returns nil if the typing got aborted
    end
end

-----
-- Text
-----

function Draw3DText(x, y, z, text)
    -- Check if coords are visible and get 2D screen coords

    local gameplayCoords = GetFinalRenderedCamCoord()

    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        -- Calculate text scale to use
        local dist = GetDistanceBetweenCoords(gameplayCoords.x, gameplayCoords.y, gameplayCoords.z, x, y, z, true)
        local scale = 1.8 * (1 / dist) * (1 / GetGameplayCamFov()) * 100

        -- Draw text on screen
        SetTextScale(scale, scale)
        SetTextFont(4)
        SetTextProportional(true)
        SetTextColour(255, 255, 255, 255)
        SetTextDropShadow()
        SetTextDropShadow()
        SetTextEdge(4, 0, 0, 0, 255)
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(true)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

-- Draw 2D text on screen
function Draw2DText(x, y, text, scale)
    -- Draw text on screen
    SetTextFont(4)
    SetTextProportional(true)
    SetTextScale(scale, scale)
    SetTextColour(255, 255, 255, 255)
    SetTextDropShadow()
    SetTextDropShadow()
    SetTextEdge(4, 0, 0, 0, 255)
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x, y)
end