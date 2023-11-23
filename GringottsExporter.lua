local LibBase64 = LibStub('LibBase64-1.0')
local LibJSON = LibStub('LibJSON-1.0')

local function GringottsGetCharName()
    local charName, realmName = UnitName("player")
    realmName = GetRealmName()
    return charName .. "-" .. realmName
end

local function GringottsGetItemCounts(name)
    local charName, realmName = strsplit("-", name)
    local itemCounts = {}

    if BagSyncDB[realmName] ~= nil and BagSyncDB[realmName][charName] ~= nil then
        for _, bagItems in pairs(BagSyncDB[realmName][charName]["bag"]) do
            for _, bagItem in pairs(bagItems) do
                local itemCount = 1
                local itemName = bagItem
                if string.find(bagItem, ";") then
                    local it, ct = strsplit(";", bagItem)
                    itemName = it
                    itemCount = ct
                end

                if itemCounts[itemName] == nil then
                    itemCounts[itemName] = itemCount
                else
                    local curVal = itemCounts[itemName]
                    itemCounts[itemName] = curVal + itemCount
                end
            end
        end

        for _, bankItems in pairs(BagSyncDB[realmName][charName]["bank"]) do
            for _, bankItem in pairs(bankItems) do
                local itemCount = 1
                local itemName = bankItem
                if string.find(bankItem, ";") then
                    local it, ct = strsplit(";", bankItem)
                    itemName = it
                    itemCount = ct
                end

                if itemCounts[itemName] == nil then
                    itemCounts[itemName] = itemCount
                else
                    local curVal = itemCounts[itemName]
                    itemCounts[itemName] = curVal + itemCount
                end
            end
        end
    end

    return itemCounts
end

local function GringottsGetItemNames(itemCounts)
    local itemNames = {}
    for k, _ in pairs(itemCounts) do
        local itemName = GetItemInfo(k)
        if itemName ~= nil then
            itemNames[k] = itemName
        end
    end

    return itemNames
end

-- https://www.wowinterface.com/forums/showthread.php?t=55498
local function GringottsEditBox_Show(text)
    if not GringottsEditBox then
        local f = CreateFrame("Frame", "GringottsEditBox", UIParent, "DialogBoxFrame")
        f:SetPoint("CENTER")
        f:SetSize(600, 500)

        f:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\PVPFrame\\UI-Character-PVP-Highlight", -- this one is neat
            edgeSize = 16,
            insets = { left = 8, right = 6, top = 8, bottom = 8 },
        })
        f:SetBackdropBorderColor(0, .44, .87, 0.5) -- darkblue

        -- Movable
        f:SetMovable(true)
        f:SetClampedToScreen(true)
        f:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then
                self:StartMoving()
            end
        end)
        f:SetScript("OnMouseUp", f.StopMovingOrSizing)

        -- ScrollFrame
        local sf = CreateFrame("ScrollFrame", "GringottsEditBoxScrollFrame", GringottsEditBox,
            "UIPanelScrollFrameTemplate")
        sf:SetPoint("LEFT", 16, 0)
        sf:SetPoint("RIGHT", -32, 0)
        sf:SetPoint("TOP", 0, -16)
        sf:SetPoint("BOTTOM", GringottsEditBoxButton, "TOP", 0, 0)

        -- EditBox
        local eb = CreateFrame("EditBox", "GringottsEditBoxEditBox", GringottsEditBoxScrollFrame)
        eb:SetSize(sf:GetSize())
        eb:SetMultiLine(true)
        eb:SetAutoFocus(false) -- dont automatically focus
        eb:SetFontObject("ChatFontNormal")
        eb:SetScript("OnEscapePressed", function() f:Hide() end)
        sf:SetScrollChild(eb)

        -- Resizable
        f:SetResizable(true)
        f:SetResizeBounds(150, 100)

        local rb = CreateFrame("Button", "GringottsEditBoxResizeButton", GringottsEditBox)
        rb:SetPoint("BOTTOMRIGHT", -6, 7)
        rb:SetSize(16, 16)

        rb:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        rb:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
        rb:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

        rb:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then
                f:StartSizing("BOTTOMRIGHT")
                self:GetHighlightTexture():Hide() -- more noticeable
            end
        end)
        rb:SetScript("OnMouseUp", function(self, button)
            f:StopMovingOrSizing()
            self:GetHighlightTexture():Show()
            eb:SetWidth(sf:GetWidth())
        end)
        f:Show()
    end

    if text then
        GringottsEditBoxEditBox:SetText(text)
    end
    GringottsEditBox:Show()
end

SLASH_GRINGOTTS_SHOW1 = "/ggeshow"
SlashCmdList["GRINGOTTS_SHOW"] = function(msg)
    local charName = GringottsGetCharName()
    local itemCounts = GringottsGetItemCounts(charName)
    local itemNames = GringottsGetItemNames(itemCounts)
    local result = {
        ["charName"] = charName,
        ["itemNames"] = itemNames,
        ["itemCounts"] = itemCounts
    }

    local jsonResult = LibJSON.Serialize(result)
    local b64Result = LibBase64:Encode(jsonResult)
    GringottsEditBox_Show(b64Result)
end
