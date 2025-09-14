local addonName = ...
TrackyDB = TrackyDB or {}
TrackyHistory = TrackyHistory or {}
TrackyUsage = TrackyUsage or {}
TrackyItemDB = TrackyItemDB or {} -- falls TrackyItems.lua nicht geladen

-- =========================
-- === Einstellungen     ===
-- =========================
local MaxTracked = 8  -- bei Rezepten bis 8

local function getCharKey()
    return UnitName("player") .. "-" .. GetRealmName()
end

if not TrackyDB[getCharKey()] then
    TrackyDB[getCharKey()] = {}
end
local items = TrackyDB[getCharKey()]

-- ======================
-- === Hauptfenster   ===
-- ======================
local frame = CreateFrame("Frame", "TrackyFrame", UIParent)
frame:SetSize(300, 260)
frame:SetPoint("CENTER")
frame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
frame:SetBackdropColor(0,0,0,0.8)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

-- Resizable
frame:SetResizable(true)
frame:SetMinResize(220, 150)
frame:SetMaxResize(600, 600)
local sizeGrab = CreateFrame("Button", nil, frame)
sizeGrab:SetSize(16,16)
sizeGrab:SetPoint("BOTTOMRIGHT", -4, 4)
sizeGrab:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
sizeGrab:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
sizeGrab:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
sizeGrab:SetScript("OnMouseDown", function(self) self:GetParent():StartSizing("BOTTOMRIGHT") end)
sizeGrab:SetScript("OnMouseUp", function(self) self:GetParent():StopMovingOrSizing() end)

-- Close-Button
local closeBtnMain = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
closeBtnMain:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
closeBtnMain:SetScript("OnClick", function() frame:Hide() end)

frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
frame.title:SetPoint("TOPLEFT", 10, -8)
frame.title:SetText("Tracky")

-- Textausgabe
local textScroll = CreateFrame("ScrollFrame", "TrackyMainScroll", frame, "UIPanelScrollFrameTemplate")
textScroll:SetPoint("TOPLEFT", 8, -28)
textScroll:SetPoint("BOTTOMRIGHT", -28, 36)

local textHolder = CreateFrame("Frame", nil, textScroll)
textHolder:SetSize(1,1)
textScroll:SetScrollChild(textHolder)

frame.text = textHolder:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
frame.text:SetPoint("TOPLEFT", 2, -2)
frame.text:SetJustifyH("CENTER")
frame.text:SetJustifyV("TOP")
frame.text:SetText("")

-- Reflow Haupttext bei Größenänderung
local function ReflowMain()
    local w = math.max(50, textScroll:GetWidth() - 6)
    frame.text:SetWidth(w)
    textHolder:SetSize(w+6, frame.text:GetStringHeight() + 6)
end
frame:SetScript("OnSizeChanged", function() ReflowMain() end)

local configBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
configBtn:SetPoint("BOTTOM", 0, 8)
configBtn:SetSize(90, 22)
configBtn:SetText("Optionen")

-- ==========================
-- === Konfigurations-UI  ===
-- ==========================
local config = CreateFrame("Frame", "TrackyConfig", UIParent)
config:SetSize(460, 600)
config:SetPoint("CENTER")
config:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
config:SetBackdropColor(0,0,0,0.9)
config:Hide()

-- Resizable
config:SetResizable(true)
config:SetMinResize(380, 360)
config:SetMaxResize(900, 800)
local sizeGrabCfg = CreateFrame("Button", nil, config)
sizeGrabCfg:SetSize(16,16)
sizeGrabCfg:SetPoint("BOTTOMRIGHT", -4, 4)
sizeGrabCfg:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
sizeGrabCfg:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
sizeGrabCfg:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
sizeGrabCfg:SetScript("OnMouseDown", function(self) self:GetParent():StartSizing("BOTTOMRIGHT") end)
sizeGrabCfg:SetScript("OnMouseUp", function(self) self:GetParent():StopMovingOrSizing() end)

-- Close-Button
local closeBtnCfg = CreateFrame("Button", nil, config, "UIPanelCloseButton")
closeBtnCfg:SetPoint("TOPRIGHT", config, "TOPRIGHT", -5, -5)
closeBtnCfg:SetScript("OnClick", function() config:Hide() end)

config.title = config:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
config.title:SetPoint("TOP", 0, -10)
config.title:SetText("Tracky Optionen")

-- === ITEM-SUCHE GANZ OBEN (Dropdown-Ergebnisse) ===
local searchTopLabel = config:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
searchTopLabel:SetPoint("TOPLEFT", 15, -40)
searchTopLabel:SetText("In Datenbank (Items) suchen:")

local searchBox = CreateFrame("EditBox", "TrackySearchBox", config, "InputBoxTemplate")
searchBox:SetSize(260, 20)
searchBox:SetPoint("TOPLEFT", searchTopLabel, "BOTTOMLEFT", 0, -5)
searchBox:SetAutoFocus(false)

local searchMenu = CreateFrame("Frame", "TrackySearchMenu", UIParent, "UIDropDownMenuTemplate")

-- === REZEPT-SUCHE (eigenes Feld + Dropdown + Menge + Hinzufügen) ===
local recipeLabel = config:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
recipeLabel:SetPoint("TOPLEFT", searchBox, "BOTTOMLEFT", 0, -12)
recipeLabel:SetText("Rezept suchen (Berufsfenster offen):")

local recipeBox = CreateFrame("EditBox", "TrackyRecipeSearchBox", config, "InputBoxTemplate")
recipeBox:SetSize(220, 20)
recipeBox:SetPoint("TOPLEFT", recipeLabel, "BOTTOMLEFT", 0, -5)
recipeBox:SetAutoFocus(false)

local recipeQty = CreateFrame("EditBox", "TrackyRecipeQty", config, "InputBoxTemplate")
recipeQty:SetSize(36, 20)
recipeQty:SetPoint("LEFT", recipeBox, "RIGHT", 8, 0)
recipeQty:SetNumeric(true)
recipeQty:SetAutoFocus(false)
recipeQty:SetNumber(1)

local recipeQtyLbl = config:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
recipeQtyLbl:SetPoint("LEFT", recipeQty, "RIGHT", 6, 0)
recipeQtyLbl:SetText("x craften")

-- NEU: „Hinzufügen“-Button (bestätigt die Auswahl/Eingabe)
local recipeAddBtn = CreateFrame("Button", nil, config, "UIPanelButtonTemplate")
recipeAddBtn:SetSize(90, 20)
recipeAddBtn:SetPoint("LEFT", recipeQtyLbl, "RIGHT", 8, 0)
recipeAddBtn:SetText("Hinzufügen")

local recipeMenu = CreateFrame("Frame", "TrackyRecipeSearchMenu", UIParent, "UIDropDownMenuTemplate")

-- Merker: zuletzt im Dropdown gewählte Rezept-Index (erst per Button hinzufügen)
local selectedRecipeIndex = nil

-- === Add-Box ===
local addLabel = config:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
addLabel:SetPoint("TOPLEFT", recipeBox, "BOTTOMLEFT", 0, -12)
addLabel:SetText("Item hinzufügen (Shift-Klick oder ID):")

local addBox = CreateFrame("EditBox", nil, config, "InputBoxTemplate")
addBox:SetSize(220, 20)
addBox:SetPoint("TOPLEFT", addLabel, "BOTTOMLEFT", 0, -5)
addBox:SetAutoFocus(false)

local addBtn = CreateFrame("Button", nil, config, "UIPanelButtonTemplate")
addBtn:SetPoint("LEFT", addBox, "RIGHT", 10, 0)
addBtn:SetSize(60, 20)
addBtn:SetText("Add")

-- === ScrollFrame für dynamische Inhalte ===
local scrollFrame = CreateFrame("ScrollFrame", "TrackyScrollFrame", config, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", addBox, "BOTTOMLEFT", 0, -20)
scrollFrame:SetSize(420, 360)

local content = CreateFrame("Frame", nil, scrollFrame)
content:SetSize(400, 1) -- Breite fix, Höhe dynamisch
scrollFrame:SetScrollChild(content)

-- Sicherstellen, dass die Eingabefelder vor dem ScrollFrame liegen
local overlayFixLevel = scrollFrame:GetFrameLevel() + 1
searchBox:SetFrameLevel(overlayFixLevel)
recipeBox:SetFrameLevel(overlayFixLevel)
recipeQty:SetFrameLevel(overlayFixLevel)
recipeQtyLbl:SetFrameLevel(overlayFixLevel)
recipeAddBtn:SetFrameLevel(overlayFixLevel)
addBox:SetFrameLevel(overlayFixLevel)
addBtn:SetFrameLevel(overlayFixLevel)

config.list = {}

-- passt die ScrollFrame-Größe bei Fenster-Resize an
local function ReflowConfig()
    local w = math.max(320, config:GetWidth() - 40)
    local h = math.max(200, config:GetHeight() - 180)
    scrollFrame:SetSize(w, h)
    content:SetWidth(w - 20)
    scrollFrame:UpdateScrollChildRect()
end
config:SetScript("OnSizeChanged", function() ReflowConfig() end)

-- ============================
-- === Anzeige aktualisieren ===
-- ============================
local function UpdateDisplay()
    local str = ""
    for _, entry in ipairs(items) do
        local id = entry.id
        local goal = entry.goal or 0
        local name, _, _, _, _, _, _, _, _, icon = GetItemInfo(id)
        local count = GetItemCount(id, false)
        local iconTag = "|T"..(icon or 134400)..":16|t"
        if name then
            if goal > 0 then
                str = str .. iconTag .. " " .. name .. " – " .. count .. " / " .. goal .. "\n"
            else
                str = str .. iconTag .. " " .. name .. " – " .. count .. "\n"
            end
        else
            str = str .. iconTag .. " ItemID " .. id .. " – " .. (count or "?") .. "\n"
        end
    end
    frame.text:SetText(str ~= "" and str or "Keine Items getrackt.")
    ReflowMain()
end

-- ==========================
-- === Hilfsfunktionen   ===
-- ==========================
local function GetEntryByID(itemID)
    for _, entry in ipairs(items) do
        if entry.id == itemID then
            return entry
        end
    end
    return nil
end

local function LearnInItemDB(itemID)
    local found = false
    for _, it in ipairs(TrackyItemDB) do
        if it.id == itemID then found = true; break end
    end
    if not found then
        local nm = GetItemInfo(itemID) or ("ItemID " .. itemID)
        table.insert(TrackyItemDB, { id = itemID, name = nm })
    end
end

local function PushHistory(itemID)
    for i, hid in ipairs(TrackyHistory) do
        if hid == itemID then table.remove(TrackyHistory, i); break end
    end
    table.insert(TrackyHistory, 1, itemID)
    if #TrackyHistory > 10 then table.remove(TrackyHistory) end
end

-- Sorgt dafür, dass ein Item in der Track-Liste ist (oder fügt es hinzu, wenn Platz).
-- Gibt (entry, status) zurück, status = "existing" | "added" | "limit"
local function EnsureTracked(itemID)
    local entry = GetEntryByID(itemID)
    if entry then return entry, "existing" end
    if #items >= MaxTracked then return nil, "limit" end
    entry = { id = itemID, goal = 0 }
    table.insert(items, entry)
    TrackyUsage[itemID] = (TrackyUsage[itemID] or 0) + 1
    PushHistory(itemID)
    LearnInItemDB(itemID)
    return entry, "added"
end

-- ============================
-- === Item hinzufügen (UI) ===
-- ============================
function AddItem(id)
    local entry, status = EnsureTracked(id)
    if status == "limit" then
        print("Tracky: Maximal "..MaxTracked.." Items gleichzeitig trackbar.")
        return
    end

    if searchBox then searchBox:SetText("") end
    if recipeBox then recipeBox:SetText("") end
    selectedRecipeIndex = nil
    CloseDropDownMenus()

    print("Tracky: ItemID " .. id .. (status == "added" and " hinzugefügt." or " bereits vorhanden."))
    RefreshConfigList()
    UpdateDisplay()
    scrollFrame:SetVerticalScroll(0)
end

-- ==========================
-- === UI: Scroll-Inhalt  ===
-- ==========================
function RefreshConfigList()
    for _, w in ipairs(config.list) do w:Hide() end
    wipe(config.list)

    local y = -5

    -- Aktuell getrackt (Überschrift zentriert)
    local curTitle = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    curTitle:SetPoint("TOP", 0, y - 10)
    curTitle:SetText("Aktuell getrackt:")
    table.insert(config.list, curTitle)
    y = y - 30

    for i, entry in ipairs(items) do
        local id = entry.id
        local goal = tonumber(entry.goal or 0) or 0
        local name = GetItemInfo(id) or ("ItemID "..id)

        -- Zeilen-Container: volle Breite, mittig
        local row = CreateFrame("Frame", nil, content)
        row:SetSize(content:GetWidth(), 20)
        row:SetPoint("TOP", 0, y)
        table.insert(config.list, row)

        -- Ziel zuerst (max. 3 Stellen)
        local goalBox = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
        goalBox:SetSize(34, 20)
        goalBox:SetAutoFocus(false)
        goalBox:SetNumeric(true)
        if goalBox.SetMaxLetters then goalBox:SetMaxLetters(3) end
        goalBox:SetNumber(math.min(goal, 999))

        -- Name (zentriert)
        local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        label:SetJustifyH("CENTER")
        local nameWidth = math.max(120, row:GetWidth() - 34 - 24 - 40) -- Platz für goalBox + X + Puffer
        label:SetWidth(nameWidth)
        label:SetPoint("CENTER", row, "CENTER", 0, 0)
        label:SetText(name)

        -- goalBox links neben dem Namen
        goalBox:SetPoint("Center", label, "LEFT", -6, 0)

        -- Entfernen-Button rechts vom Namen
        local removeBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        removeBtn:SetSize(20, 20)
        removeBtn:SetText("X")
        removeBtn:SetPoint("LEFT", label, "RIGHT", 6, 0)
        removeBtn:SetScript("OnClick", function()
            table.remove(items, i)
            RefreshConfigList()
            UpdateDisplay()
        end)

        -- Live-Update (0..999)
        goalBox:SetScript("OnTextChanged", function(self)
            local n = tonumber(self:GetText()) or 0
            if n > 999 then n = 999; self:SetNumber(999); self:HighlightText(0, -1) end
            if n < 0 then n = 0; self:SetNumber(0); self:HighlightText(0, -1) end
            entry.goal = n
            UpdateDisplay()
        end)
        goalBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
        goalBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

        y = y - 26
    end

    -- Zuletzt genutzt (max 8)
    local histTitle = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    histTitle:SetPoint("TOPLEFT", 0, y - 10)
    histTitle:SetText("Zuletzt genutzt:")
    table.insert(config.list, histTitle)
    y = y - 30

    for i = 1, math.min(8, #TrackyHistory) do
        local id = TrackyHistory[i]
        local name = GetItemInfo(id) or ("ItemID "..id)
        local btn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
        btn:SetSize(260, 20)
        btn:SetPoint("TOPLEFT", 0, y)
        btn:SetText(name)
        btn:SetScript("OnClick", function() AddItem(id) end)
        table.insert(config.list, btn)
        y = y - 25
    end

    local total = (-y) + 20
    content:SetHeight(total)
    scrollFrame:UpdateScrollChildRect()
end

-- ===================================
-- === Rezept-Helfer / Suche / Add ===
-- ===================================

local function Tracky_FindRecipeIndexBySpellID(spellID)
    if not TradeSkillFrame or not TradeSkillFrame:IsShown() then return nil end
    if not GetNumTradeSkills then return nil end
    local n = GetNumTradeSkills()
    for i = 1, n do
        local _, skillType = GetTradeSkillInfo(i)
        if skillType ~= "header" and GetTradeSkillRecipeLink then
            local link = GetTradeSkillRecipeLink(i)
            if link then
                local sid = link:match("Hspell:(%d+)")
                if not sid then sid = link:match("Henchant:(%d+)") end
                if sid and tonumber(sid) == tonumber(spellID) then
                    return i
                end
            end
        end
    end
    return nil
end

local function Tracky_FindRecipeIndexByItemID(itemID)
    if not TradeSkillFrame or not TradeSkillFrame:IsShown() then return nil end
    if not GetNumTradeSkills then return nil end
    local n = GetNumTradeSkills()
    for i = 1, n do
        local _, skillType = GetTradeSkillInfo(i)
        if skillType ~= "header" and GetTradeSkillItemLink then
            local out = GetTradeSkillItemLink(i)
            if out then
                local iid = out:match("Hitem:(%d+)")
                if iid and tonumber(iid) == tonumber(itemID) then
                    return i
                end
            end
        end
    end
    return nil
end

local function Tracky_BuildRecipeIndex()
    local map = {}
    if not TradeSkillFrame or not TradeSkillFrame:IsShown() then return map end
    if not GetNumTradeSkills then return map end
    local n = GetNumTradeSkills()
    for i = 1, n do
        local _, skillType = GetTradeSkillInfo(i)
        if skillType ~= "header" then
            local outLink = GetTradeSkillItemLink and GetTradeSkillItemLink(i)
            local outID = outLink and tonumber(outLink:match("Hitem:(%d+)"))
            if outID then
                local minMade, maxMade = 1, 1
                if GetTradeSkillNumMade then
                    local a,b = GetTradeSkillNumMade(i)
                    if a then minMade = a end
                    if b then maxMade = b end
                end
                local outCount = maxMade or 1
                local reagents = {}
                local rN = GetTradeSkillNumReagents and GetTradeSkillNumReagents(i) or 0
                for r = 1, rN do
                    local _, _, reqCount = GetTradeSkillReagentInfo(i, r)
                    local link = GetTradeSkillReagentItemLink and GetTradeSkillReagentItemLink(i, r)
                    local rid = link and tonumber(link:match("item:(%d+)"))
                    if rid and reqCount then
                        table.insert(reagents, { id = rid, count = reqCount })
                    end
                end
                map[outID] = { index = i, outCount = math.max(1, outCount), reagents = reagents }
            end
        end
    end
    return map
end

local function Tracky_FlattenToBase(map, outID, neededCount, acc, visiting)
    acc = acc or {}
    visiting = visiting or {}

    if not outID or neededCount <= 0 then return acc end
    if visiting[outID] then
        acc[outID] = (acc[outID] or 0) + neededCount
        return acc
    end

    local node = map[outID]
    if not node or not node.reagents or #node.reagents == 0 then
        acc[outID] = (acc[outID] or 0) + neededCount
        return acc
    end

    visiting[outID] = true

    local crafts = math.ceil(neededCount / math.max(1, node.outCount))
    for _, r in ipairs(node.reagents) do
        local need = crafts * (r.count or 0)
        if need > 0 then
            Tracky_FlattenToBase(map, r.id, need, acc, visiting)
        end
    end

    visiting[outID] = nil
    return acc
end

local function Tracky_AddBaseReagentsToTracking(reagentCounts)
    local added, updated, limited = 0, 0, 0
    for itemID, need in pairs(reagentCounts) do
        local entry, status = EnsureTracked(itemID)
        if status == "limit" then
            limited = limited + 1
        elseif entry then
            entry.goal = (tonumber(entry.goal) or 0) + (need or 0)
            if status == "added" then added = added + 1 else updated = updated + 1 end
        end
    end
    RefreshConfigList()
    UpdateDisplay()
    return added, updated, limited
end

local function Tracky_AddRecipeByIndex(index, mult)
    mult = tonumber(mult) or 1
    local reagents = GetTradeSkillNumReagents and GetTradeSkillNumReagents(index)
    if not reagents or reagents <= 0 then return 0,0,0,0 end
    local added, updated, skipped, limited = 0,0,0,0
    for r = 1, reagents do
        local _, _, reqCount = GetTradeSkillReagentInfo(index, r)
        local link = GetTradeSkillReagentItemLink and GetTradeSkillReagentItemLink(index, r)
        local itemID = link and link:match("item:(%d+)")
        if itemID and reqCount then
            itemID = tonumber(itemID)
            local need = (reqCount or 0) * mult
            local entry, status = EnsureTracked(itemID)
            if status == "limit" then
                limited = limited + 1
            elseif entry then
                entry.goal = (tonumber(entry.goal) or 0) + need
                if status == "added" then added = added + 1 else updated = updated + 1 end
            else
                skipped = skipped + 1
            end
        else
            skipped = skipped + 1
        end
    end
    RefreshConfigList()
    UpdateDisplay()
    return added, updated, skipped, limited
end

local function Tracky_AddRecipeFlattened(index, mult)
    mult = tonumber(mult) or 1
    local outLink = GetTradeSkillItemLink and GetTradeSkillItemLink(index)
    local outID = outLink and tonumber(outLink:match("Hitem:(%d+)"))
    if not outID then
        local a,b,c,l = Tracky_AddRecipeByIndex(index, mult)
        print(("Tracky: (ohne Ergebnis-Item) → %d neu, %d aktualisiert, %d überspr., %d Limit."):format(a,b,c,l))
        return
    end
    local map = Tracky_BuildRecipeIndex()
    local minMade, maxMade = 1,1
    if GetTradeSkillNumMade then
        local a,b = GetTradeSkillNumMade(index)
        if a then minMade = a end
        if b then maxMade = b end
    end
    local outPerCraft = maxMade or 1
    local craftsNeeded = math.ceil(mult / math.max(1, outPerCraft))
    local flattened = Tracky_FlattenToBase(map, outID, craftsNeeded, {}, {})
    local a,u,l = Tracky_AddBaseReagentsToTracking(flattened)
    local baseCount = 0
    for _ in pairs(flattened) do baseCount = baseCount + 1 end
    print(("Tracky: Flatten '%s' → %d Basisressourcen, %d neu, %d aktualisiert, %d Limit.")
        :format(outID, baseCount, a, u, l))
end

local function Tracky_AddRecipeFromLink(link, mult, doFlatten)
    if not link or link == "" then return false end
    mult = tonumber(mult) or 1
    local sid = link:match("Hspell:(%d+)") or link:match("Henchant:(%d+)")
    if sid then
        local idx = Tracky_FindRecipeIndexBySpellID(tonumber(sid))
        if idx then
            if doFlatten then Tracky_AddRecipeFlattened(idx, mult)
            else
                local a,u,s,l = Tracky_AddRecipeByIndex(idx, mult)
                print(("Tracky: Rezept (%s) → %d neu, %d aktualisiert, %d überspr., %d Limit.")
                    :format(sid, a,u,s,l))
            end
            if searchBox then searchBox:SetText("") end
            if recipeBox then recipeBox:SetText("") end
            selectedRecipeIndex = nil
            CloseDropDownMenus()
            return true
        else
            print("Tracky: Rezept nicht im geöffneten Berufsfenster gefunden.")
            return false
        end
    end
    local iid = link:match("Hitem:(%d+)")
    if iid then
        local idx = Tracky_FindRecipeIndexByItemID(tonumber(iid))
        if idx then
            if doFlatten then Tracky_AddRecipeFlattened(idx, mult)
            else
                local a,u,s,l = Tracky_AddRecipeByIndex(idx, mult)
                print(("Tracky: Rezept für Item %s → %d neu, %d aktualisiert, %d überspr., %d Limit.")
                    :format(iid, a,u,s,l))
            end
            if recipeBox then recipeBox:SetText("") end
            selectedRecipeIndex = nil
            CloseDropDownMenus()
            return true
        end
        AddItem(tonumber(iid))
        return true
    end
    return false
end

-- ===================================
-- === Suche: Dropdown befüllen    ===
-- ===================================
local function ShowItemSearchMenu(anchor, query)
    if not query or query == "" then
        CloseDropDownMenus(); return
    end
    local q = string.lower(query)
    local menu = {}
    local hits = 0
    for _, it in ipairs(TrackyItemDB) do
        local nm = it.name
        if nm and string.find(string.lower(nm), q, 1, true) then
            hits = hits + 1
            table.insert(menu, {
                text = nm,
                notCheckable = true,
                func = function()
                    AddItem(it.id)
                    if searchBox then searchBox:SetText("") end
                    CloseDropDownMenus()
                end,
            })
            if hits >= 30 then break end
        end
    end
    if hits == 0 then
        table.insert(menu, { text = "Keine Treffer", isTitle = true, notCheckable = true, disabled = true })
    end
    EasyMenu(menu, searchMenu, anchor, 0, 0, "MENU", 3)
end

local function Tracky_ScanTradeSkills(query)
    local results = {}
    if not TradeSkillFrame or not TradeSkillFrame:IsShown() or not GetNumTradeSkills then
        return results, false
    end
    local q = string.lower(query or "")
    local n = GetNumTradeSkills()
    for i = 1, n do
        local name, skillType = GetTradeSkillInfo(i)
        if skillType ~= "header" and name then
            if q == "" or string.find(string.lower(name), q, 1, true) then
                local icon = GetTradeSkillIcon and GetTradeSkillIcon(i)
                local display = icon and ("|T"..icon..":16|t "..name) or name
                table.insert(results, { index = i, text = display, name = name })
                if #results >= 30 then break end
            end
        end
    end
    return results, true
end

local function ShowRecipeSearchMenu(anchor, query, doFlatten)
    local list, ok = Tracky_ScanTradeSkills(query)
    local menu = {}
    if not ok then
        table.insert(menu, { text = "Berufsfenster ist nicht offen", isTitle = true, notCheckable = true, disabled = true })
        table.insert(menu, { text = "Öffne z. B. Schneiderei/Verzauberkunst", isTitle = true, notCheckable = true, disabled = true })
    elseif #list == 0 then
        table.insert(menu, { text = "Keine Rezepte gefunden", isTitle = true, notCheckable = true, disabled = true })
    else
        local mult = tonumber(recipeQty:GetText() or "1") or 1
        for _, r in ipairs(list) do
            table.insert(menu, {
                text = r.text .. "  x"..mult .. "  (zur Auswahl)",
                notCheckable = true,
                func = function()
                    selectedRecipeIndex = r.index
                    if recipeBox then recipeBox:SetText(r.name or "") end
                end
            })
        end
    end
    EasyMenu(menu, recipeMenu, anchor, 0, 0, "MENU", 3)
end

-- ============
-- === Events
-- ============
frame:SetScript("OnEvent", UpdateDisplay)
frame:RegisterEvent("BAG_UPDATE")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

-- =====================
-- === Button-Logik  ===
-- =====================
configBtn:SetScript("OnClick", function()
    if config:IsShown() then
        config:Hide()
    else
        RefreshConfigList()
        config:Show()
        searchBox:SetFocus()
        ReflowConfig()
    end
end)

addBtn:SetScript("OnClick", function()
    local text = addBox:GetText()
    local id
    if text and text:match("item:(%d+)") then
        id = tonumber(text:match("item:(%d+)"))
    elseif text and tonumber(text) then
        id = tonumber(text)
    end
    if id then
        AddItem(id)
        addBox:SetText("")
        addBox:ClearFocus()
    else
        print("Tracky: Bitte gültige ItemID oder per Shift-Klick einfügen.")
    end
end)

-- NEU: Rezept „Hinzufügen“-Button – fügt erst NACH Bestätigung hinzu (flatten)
recipeAddBtn:SetScript("OnClick", function()
    local mult = tonumber(recipeQty:GetText() or "1") or 1

    if selectedRecipeIndex then
        Tracky_AddRecipeFlattened(selectedRecipeIndex, mult)
        if recipeBox then recipeBox:SetText("") end
        selectedRecipeIndex = nil
        CloseDropDownMenus()
        return
    end

    local text = recipeBox:GetText()
    if text and text ~= "" then
        if Tracky_AddRecipeFromLink(text, mult, true) then
            if recipeBox then recipeBox:SetText("") end
            selectedRecipeIndex = nil
            CloseDropDownMenus()
            return
        end
    end

    print("Tracky: Bitte Rezept aus dem Dropdown wählen oder per Shift-Klick Link ins Feld setzen, dann 'Hinzufügen'.")
end)

-- Sucheingaben → Dropdowns
searchBox:SetScript("OnTextChanged", function(self)
    ShowItemSearchMenu(self, self:GetText() or "")
end)
recipeBox:SetScript("OnTextChanged", function(self)
    -- Freitexteingabe löscht bewusste Dropdown-Auswahl, bis erneut gewählt wird
    selectedRecipeIndex = nil
    ShowRecipeSearchMenu(self, self:GetText() or "", true)
end)

searchBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() CloseDropDownMenus() end)
recipeBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() CloseDropDownMenus() end)

-- =================================================
-- === Rezepte/Items via Shift-Klick in Felder   ===
-- =================================================
local orig_ChatEdit_InsertLink = ChatEdit_InsertLink
function ChatEdit_InsertLink(text)
    if addBox:HasFocus() and text then
        addBox:SetText(text); addBox:SetFocus(); return true
    elseif searchBox:HasFocus() and text then
        -- Items im Suchfeld dürfen weiterhin sofort hinzugefügt werden, wenn möglich
        if Tracky_AddRecipeFromLink(text, 1, true) then
            if searchBox then searchBox:SetText("") end
            searchBox:SetFocus()
            CloseDropDownMenus()
            return true
        end
        searchBox:SetText(text); searchBox:SetFocus(); return true
    elseif recipeBox:HasFocus() and text then
        -- NEU: Im Rezeptfeld nur EINTRAGEN, nicht sofort hinzufügen.
        recipeBox:SetText(text)
        recipeBox:SetFocus()
        selectedRecipeIndex = nil
        return true
    end
    return orig_ChatEdit_InsertLink(text)
end

-- =========================
-- === Minimap-Button    ===
-- =========================
do
    local cos, sin, rad, deg, atan2 = math.cos, math.sin, math.rad, math.deg, math.atan2
    local charTbl = TrackyDB[getCharKey()]
    if type(charTbl) ~= "table" then charTbl = {}; TrackyDB[getCharKey()] = charTbl end
    charTbl._mmAngleDeg = charTbl._mmAngleDeg or 45

    local RADIUS = 80
    local OFFSET = 52

    local btn = CreateFrame("Button", "TrackyMinimapButton", Minimap)
    btn:SetSize(31, 31)
    btn:SetFrameStrata("MEDIUM")
    btn:SetMovable(true)
    btn:RegisterForDrag("LeftButton")
    btn:RegisterForClicks("AnyUp")

    local icon = btn:CreateTexture(nil, "BACKGROUND")
    icon:SetTexture("Interface\\Icons\\INV_Fabric_Soulcloth")
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    icon:SetPoint("TOPLEFT",     btn, "TOPLEFT",     7, -5)
    icon:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -7,  7)

    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(54, 54)
    border:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)

    local hl = btn:CreateTexture(nil, "HIGHLIGHT")
    hl:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    hl:SetBlendMode("ADD")
    hl:SetAllPoints(border)

    local function MoveToAngle(angleDeg)
        charTbl._mmAngleDeg = angleDeg
        local a = rad(angleDeg)
        local x = OFFSET - (RADIUS * cos(a))
        local y = (RADIUS * sin(a)) - OFFSET
        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", Minimap, "TOPLEFT", x, y)
    end

    local dragging = false
    btn:SetScript("OnDragStart", function(self)
        self:LockHighlight()
        dragging = true
        self:SetScript("OnUpdate", function()
            if not dragging then self:SetScript("OnUpdate", nil) return end
            local cx, cy = GetCursorPosition()
            local scaleParent = UIParent:GetScale()
            local xmin, ymin = Minimap:GetLeft(), Minimap:GetBottom()
            local xpos = xmin - (cx / scaleParent) + 70
            local ypos = (cy / scaleParent) - ymin - 70
            local angleDeg = deg(atan2(ypos, xpos))
            MoveToAngle(angleDeg)
        end)
    end)
    btn:SetScript("OnDragStop", function(self)
        dragging = false
        self:SetScript("OnUpdate", nil)
        self:UnlockHighlight()
    end)

    btn:SetScript("OnClick", function(self, button)
        if button == "LeftButton" then
            if frame:IsShown() then frame:Hide() else frame:Show() end
        elseif button == "RightButton" then
            if config:IsShown() then config:Hide() else RefreshConfigList(); config:Show(); ReflowConfig() end
        end
    end)

    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Tracky", 1, 1, 1)
        GameTooltip:AddLine("Linksklick: Fenster ein/aus", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("Rechtsklick: Optionen", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("Ziehen: Button verschieben", 0.9, 0.9, 0.9)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local init = CreateFrame("Frame")
    init:RegisterEvent("PLAYER_ENTERING_WORLD")
    init:SetScript("OnEvent", function() MoveToAngle(charTbl._mmAngleDeg or 45) end)

    SLASH_TRACKYMM1 = "/trackymm"
    SlashCmdList.TRACKYMM = function(msg)
        local m = (msg or ""):lower()
        if m == "reset" then
            charTbl._mmAngleDeg = 45
            MoveToAngle(45)
            print("Tracky: Minimap-Button zurückgesetzt (45°).")
        elseif m:match("^set%s+(-?%d+%.?%d*)$") then
            local a = tonumber(m:match("set%s+(-?%d+%.?%d*)"))
            if a then
                MoveToAngle(a % 360)
                print(("Tracky: Winkel auf %.1f° gesetzt."):format(a % 360))
            end
        else
            print("Tracky: /trackymm reset  – setzt Position zurück.")
            print("Tracky: /trackymm set <grad>  – z.B. /trackymm set 135")
        end
    end
end

-- ===================================
-- === Direkt im TradeSkill-UI     ===
-- ===================================
local function Tracky_TrackCurrentRecipe(mult, doFlatten)
    mult = tonumber(mult) or 1
    if not TradeSkillFrame or not TradeSkillFrame:IsShown() then
        print("Tracky: Berufsfenster ist nicht offen.")
        return
    end

    local idx = GetTradeSkillSelectionIndex and GetTradeSkillSelectionIndex()
    if not idx or idx <= 0 then
        print("Tracky: Kein Rezept ausgewählt.")
        return
    end

    if doFlatten then
        Tracky_AddRecipeFlattened(idx, mult)
        return
    end

    local reagents = GetTradeSkillNumReagents and GetTradeSkillNumReagents(idx)
    if not reagents or reagents <= 0 then
        print("Tracky: Dieses Rezept hat keine klassischen Reagenzien.")
        return
    end

    local added, updated, skipped, limited = 0, 0, 0, 0
    for r = 1, reagents do
        local _, _, reqCount = GetTradeSkillReagentInfo(idx, r)
        local link = GetTradeSkillReagentItemLink and GetTradeSkillReagentItemLink(idx, r)
        local itemID = link and link:match("item:(%d+)")
        if itemID and reqCount then
            itemID = tonumber(itemID)
            local need = (reqCount or 0) * mult
            local entry, status = EnsureTracked(itemID)
            if status == "limit" then
                limited = limited + 1
            elseif entry then
                entry.goal = (tonumber(entry.goal) or 0) + need
                if status == "added" then added = added + 1 else updated = updated + 1 end
            else
                skipped = skipped + 1
            end
        else
            skipped = skipped + 1
        end
    end

    print(("Tracky: Rezept getrackt – %d neu, %d aktualisiert, %d übersprungen, %d Limit.")
        :format(added, updated, skipped, limited))

    RefreshConfigList()
    UpdateDisplay()
end

local function Tracky_CreateRecipeWidgets()
    if not TradeSkillFrame or TrackyRecipePane then return end

    local pane = CreateFrame("Frame", "TrackyRecipePane", TradeSkillFrame)
    pane:SetSize(260, 24)
    pane:SetPoint("TOPRIGHT", TradeSkillFrame, "TOPRIGHT", -20, -40)

    local qtyBox = CreateFrame("EditBox", "TrackyRecipeQtyBox", pane, "InputBoxTemplate")
    qtyBox:SetSize(36, 20)
    qtyBox:SetAutoFocus(false)
    qtyBox:SetNumeric(true)
    qtyBox:SetNumber(1)
    qtyBox:SetPoint("LEFT", pane, "LEFT", 0, 0)

    local qtyLbl = pane:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    qtyLbl:SetPoint("LEFT", qtyBox, "RIGHT", 6, 0)
    qtyLbl:SetText("x herstellen")

    local btn = CreateFrame("Button", "TrackyRecipeBtn", pane, "UIPanelButtonTemplate")
    btn:SetSize(100, 20)
    btn:SetPoint("LEFT", qtyLbl, "RIGHT", 8, 0)
    btn:SetText("Rezept tracken")
    btn:SetScript("OnClick", function()
        local mult = tonumber(qtyBox:GetText()) or 1
        Tracky_TrackCurrentRecipe(mult, false)
    end)

    local btn2 = CreateFrame("Button", "TrackyRecipeBtnFlat", pane, "UIPanelButtonTemplate")
    btn2:SetSize(100, 20)
    btn2:SetPoint("LEFT", btn, "RIGHT", 6, 0)
    btn2:SetText("Flatten")
    btn2:SetScript("OnClick", function()
        local mult = tonumber(qtyBox:GetText()) or 1
        Tracky_TrackCurrentRecipe(mult, true)
    end)

    for _, b in ipairs({btn, btn2}) do
        b:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
            if self == btn2 then
                GameTooltip:AddLine("Tracky – Flatten", 1,1,1)
                GameTooltip:AddLine("Rechnet Zwischenprodukte auf Basisressourcen herunter.", .9,.9,.9)
                GameTooltip:AddLine("Ziele werden additiv erhöht (Limit "..MaxTracked..").", .9,.9,.9)
            else
                GameTooltip:AddLine("Tracky – Rezept tracken", 1,1,1)
                GameTooltip:AddLine("Fügt Reagenzien direkt als Ziele hinzu (ohne Flatten).", .9,.9,.9)
            end
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
end

local TrackyRecipeEvt = CreateFrame("Frame")
TrackyRecipeEvt:RegisterEvent("TRADE_SKILL_SHOW")
TrackyRecipeEvt:RegisterEvent("TRADE_SKILL_CLOSE")
TrackyRecipeEvt:SetScript("OnEvent", function(self, ev)
    if ev == "TRADE_SKILL_SHOW" then
        Tracky_CreateRecipeWidgets()
        if TrackyRecipePane then TrackyRecipePane:Show() end
    elseif ev == "TRADE_SKILL_CLOSE" then
        if TrackyRecipePane then TrackyRecipePane:Hide() end
        -- Beim Schließen Auswahl zurücksetzen
        selectedRecipeIndex = nil
    end
end)

-- Slash
SLASH_TRACKYREZEPT1 = "/trackyrezept"
SlashCmdList.TRACKYREZEPT = function(msg)
    local mult = tonumber(msg) or 1
    Tracky_TrackCurrentRecipe(mult, true)
end

-- =========================
-- === Init (ohne C_Timer)
-- =========================
do
    -- kleiner OnUpdate-Ticker (~0.1s), um GetItemInfo-Caches zu füllen und UI zu layouten
    local initTicker = CreateFrame("Frame")
    local t = 0
    initTicker:SetScript("OnUpdate", function(self, elapsed)
        t = t + elapsed
        if t > 0.1 then
            UpdateDisplay()
            ReflowMain()
            ReflowConfig()
            self:SetScript("OnUpdate", nil)
        end
    end)
end
