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
    return nil
end

function CharBasedRender.FlipBinary(initial)
    local fliped = ''
    for charIDX =1, #initial do
        fliped = fliped .. tostring(1-tonumber(initial:sub(charIDX, charIDX)))
    end
    return fliped
end

function CharBasedRender.FindChar(CharCombination)
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
    return '0'
end

function CharBasedRender.Render(PixelBufer)
    for y=1, #PixelBufer, 3 do
        for x=1, #PixelBufer[y], 2 do

            local colors = {}
            local ColorsCount = 0
            local CharPixels = {}
            local MonochromePixelPatern = {}

            for y_height_char=1, 3 do
                for x_width_char=1, 2 do
                    local _ = CharBasedRender.GetPixelColor(PixelBufer, x_width_char+x, y_height_char+y)
                    table.insert(CharPixels, _ or '0')
                end
            end

            for idx=1, 6 do
                local pxl = CharPixels[idx] or 'a'
                local FinalChar = 'b'

                if colors[pxl] then
                    FinalChar = colors[pxl]

                elseif ColorsCount < 2 then
                    colors[pxl] = tostring(ColorsCount)
                    FinalChar = colors[pxl]
                    ColorsCount = ColorsCount + 1

                else
                    FinalChar = CharBasedRender.FindNearestColorIDX(pxl, colors)
                end

                table.insert(MonochromePixelPatern, FinalChar)
            end

            local char = CharBasedRender.FindChar(table.concat(MonochromePixelPatern, ''))
            local fliped = char[2]
            char = char[1]

            char = string.char(char)

            if fliped then
                backGround = tostring(CharBasedRender.findInTable(colors, '1') or 0)
                foreGround = tostring(CharBasedRender.findInTable(colors, '0') or 0)
            else
                backGround = tostring(CharBasedRender.findInTable(colors, '0') or 0)
                foreGround = tostring(CharBasedRender.findInTable(colors, '1') or 0)
            end

            term.blit(char, foreGround, backGround)

        end
        print()
    end
end

return CharBasedRender