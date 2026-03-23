-- every special character has 3x2 pixels

-- 12
-- 34
-- 56

-- ["123456"]=char id (/CharList.png)

local CharBasedRender = {}

CharBasedRender.dev = false
function CharBasedRender.debug( ... )
    if CharBasedRender.dev then print( ... ) end
end

CharBasedRender.CharList = {
    ["000000"]=128,
    ["100000"]=129,
    ["010000"]=130,
    ["110000"]=131,
    ["001000"]=132,
    ["101000"]=133,
    ["011000"]=134,
    ["111000"]=135,

    ["000100"]=136,
    ["100100"]=137,
    ["010100"]=138,
    ["110100"]=139,
    ["001100"]=140,
    ["101100"]=141,
    ["011100"]=142,

    ["111100"]=143,
    ["000010"]=144,
    ["100010"]=145,
    ["010010"]=146,
    ["110010"]=147,
    ["001010"]=148,
    ["101010"]=149,
    ["011010"]=150,

    ["111010"]=151,
    ["000110"]=152,
    ["100110"]=153,
    ["010110"]=154,
    ["110110"]=155,
    ["001110"]=156,
    ["101110"]=157,

    ["011110"]=158,
    ["111110"]=159
}
function CharBasedRender.findInTable(table, value)
    for key, val in pairs(table) do
        CharBasedRender.debug(key, value)
        if val==value then
            return key
        end
    end
    return nil
end

function CharBasedRender.GetPixelColor(PixelBufer, x, y)
    local Y = PixelBufer[y]
    if Y then
        return Y[x]
    end
    CharBasedRender.debug('Y POS too big')
    return nil
end

function CharBasedRender.FlipBinary(initial)
    local fliped = ''

    for charIDX =1, #initial do
        fliped = fliped .. tostring(1-tonumber(initial:sub(charIDX, charIDX)))
    end

    return fliped
end

function CharBasedRender.FindChar(CharCombination) -- 123456 yk (line 7)
    if not CharCombination then return nil end
    local char = CharBasedRender.CharList[CharCombination]
    local IsFliped = false
    if not char then
        
        IsFliped = true

        local flipedChar = CharBasedRender.FlipBinary(CharCombination)

        char = CharBasedRender.CharList[flipedChar]
    end
    if not char then
        char = "ERROR"
    end

    return {char, IsFliped}
end

CharBasedRender.colors = {
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'
}

function CharBasedRender.FindNearestColorIDX(colorFrom, colorsList)
    --print(CharBasedRender.findInTable(colorsList, 0))

    -- local ColorOneIDX = CharBasedRender.find(CharBasedRender.colors, colorsList[1])
    -- local ColorTwoIDX = CharBasedRender.find(CharBasedRender.colors, colorsList[2])
    -- local ColorFromIDX = CharBasedRender.find(CharBasedRender.colors, colorFrom)

    -- local ColorTwoIDXDistance = math.abs(ColorTwoIDX-ColorFromIDX)
    -- local ColorOneIDXDistance = math.abs(ColorOneIDX-ColorFromIDX)

    -- if math.min(ColorTwoIDXDistance, ColorOneIDXDistance) == ColorOneIDXDistance then
    --     return 0
    -- else
    --     return 1
    -- end
    
    return '0'
end

function CharBasedRender.Render(PixelBufer)
    for y=1, #PixelBufer, 3 do
        for x=1, #PixelBufer[y], 2 do
            CharBasedRender.debug(x,y, '-- Char --')

            -- for every char 2x3 in pixels

            local colors = {} -- color1:1   color2:2
            local ColorsCount = 1
            local CharPixels = {}
            local MonochromePixelPatern = {} -- 6 digits binnary used to find character

            for y_height_char=1, 3 do  -- every pixel in character space 2x3 CharPixels
                for x_width_char=1, 2 do
                    CharBasedRender.debug(y_height_char, x_width_char, 'Adding pixel to CharPixels')
                    local _ = CharBasedRender.GetPixelColor(PixelBufer, x_width_char+x, y_height_char+y)
                    table.insert(CharPixels, _ or '0')

                    CharBasedRender.debug(CharBasedRender.GetPixelColor(PixelBufer, x_width_char+x, y_height_char+y), '---get pixels--')
                    CharBasedRender.debug(table.concat(CharPixels, ''), '--PIXELS--')
                end
            end

            local LastColor = '0' -- last checked color id
            for idx=1, 6 do -- FOR every pixel.. (6)
                local pxl = CharPixels[idx] or 'a'
            
                local FinalChar = 'b'

                CharBasedRender.debug(pxl, '-- pixel --')
                
                if colors[pxl] then -- if pixel is already in colors
                    FinalChar = colors[pxl] -- set FinalChar to id of color
                    CharBasedRender.debug('ALREADY EXISTS', '-- pixel --')

                elseif ColorsCount<2 then -- if not in colors and there is empty space (max 2) then add current color
                    colors[pxl] = tostring(ColorsCount) -- set color in colors to id
                    ColorsCount = ColorsCount + 1
                    FinalChar = colors[pxl] -- get id
                    CharBasedRender.debug('DOESNT EXISTS', '-- pixel --', #colors, FinalChar, pxl, '--ADDED--', colors[pxl])

                else
                    CharBasedRender.debug('MORE THAN 2 COLORS ON SAME CHAR', '-- pixel --')
                    FinalChar = CharBasedRender.FindNearestColorIDX(pxl, colors) -- nearest color id
                end

                CharBasedRender.debug(FinalChar, '-- pixel -- ID')
                CharBasedRender.debug(table.concat(CharPixels, ''), '--PIXELS--')

                table.insert(MonochromePixelPatern, FinalChar) -- add final char to paterns
            end

            local char = CharBasedRender.FindChar(table.concat(MonochromePixelPatern, ''))

            local fliped = char[2]
            char = char[1]

            CharBasedRender.debug(CharBasedRender.findInTable(colors, '1') or 'NONE', CharBasedRender.findInTable(colors, '2') or 'NONE' ,'--colors--')

            CharBasedRender.debug(char, table.concat(MonochromePixelPatern), '')
            char = string.char(char)

            if fliped then
                backGround = tostring(CharBasedRender.findInTable(colors, '2') or 0)
                foreGround = tostring(CharBasedRender.findInTable(colors, '1') or 0)
            else
                backGround = tostring(CharBasedRender.findInTable(colors, '1') or 0)
                foreGround = tostring(CharBasedRender.findInTable(colors, '2') or 0)
            end

            CharBasedRender.debug(char, backGround, foreGround, type(char), type(backGround), type(foreGround), '-- CHAR AND BG AND FG')

            term.blit(char, foreGround, backGround)

        end
        print()
    end

end

return CharBasedRender