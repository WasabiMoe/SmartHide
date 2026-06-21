-- ============================================================
-- 							SMART HIDE
-- 			Hide your frames during combat.
-- 						https://github.com/WasabiMoe
-- ============================================================

SmartHideDB = SmartHideDB or {}

-- ============================================================
-- Frame Groups
-- Each group is a named set of global frame names to hide/show.
-- Add new groups or entries here no other code needs to change.
-- ============================================================

local groups = {
    {
        key = "unitframes",
        label = "Player / Target Frames",
        frames = { "PlayerFrame", "TargetFrame", "TargetFrameToT" },
    },
    {
        key = "actionbars",
        label = "Action Bars",
        frames = {
            "MainMenuBar",
            "MultiBarBottomLeft",
            "MultiBarBottomRight",
            "MultiBarRight",
            "MultiBarLeft",
        },
    },
    {
        key = "minimap",
        label = "Minimap",
        frames = { "MinimapCluster" },
    },
    {
        key = "partyframes",
        label = "Party Frames",
        frames = { "PartyMemberFrame1", "PartyMemberFrame2", "PartyMemberFrame3", "PartyMemberFrame4" },
    },
}

-- Default: Off
local function isEnabled(key)
    if SmartHideDB[key] == nil then
        return false
    end
    return SmartHideDB[key]
end

-- ============================================================
-- Core Hide / Show
-- ============================================================

local f = CreateFrame("Frame", "SmartHideEventFrame")
f:RegisterEvent("PLAYER_REGEN_DISABLED") 
f:RegisterEvent("PLAYER_REGEN_ENABLED")  
f:RegisterEvent("PLAYER_LOGIN")


local unitGatedFrames = {
    TargetFrame = "target",
    TargetFrameToT = "targettarget",
    PartyMemberFrame1 = "party1",
    PartyMemberFrame2 = "party2",
    PartyMemberFrame3 = "party3",
    PartyMemberFrame4 = "party4",
}

local function showFrame(frameName, frame)
    local unit = unitGatedFrames[frameName]
    if unit then
        if UnitExists(unit) then
            if frameName == "TargetFrame" and TargetFrame_Update then
                TargetFrame_Update(frame)
            elseif frameName == "TargetFrameToT" and TargetofTargetFrame_Update then
                TargetofTargetFrame_Update(frame)
            end
            frame:Show()
        else
            frame:Hide()
        end
    else
        frame:Show()
    end
end

local function applyToGroup(group, shouldShow)
    for _, frameName in ipairs(group.frames) do
        local frame = _G[frameName]
        if frame then
            if shouldShow then
                showFrame(frameName, frame)
            else
                frame:Hide()
            end
        end
    end
end

local function onEnterCombat()
    for _, group in ipairs(groups) do
        if isEnabled(group.key) then
            applyToGroup(group, false)
        end
    end
end

local function onLeaveCombat()
    for _, group in ipairs(groups) do
        if isEnabled(group.key) then
            applyToGroup(group, true)
        end
    end
end

f:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_REGEN_DISABLED" then
        onEnterCombat()
    elseif event == "PLAYER_REGEN_ENABLED" then
        onLeaveCombat()
    elseif event == "PLAYER_LOGIN" then
        -- Safety net: if you reload while in combat, make sure nothing
        -- is left permanently hidden from a previous session.
        if not InCombatLockdown() then
            onLeaveCombat()
        end
    end
end)

-- ============================================================
-- Slash Command: /smarthide
-- ============================================================

local function printStatus()
    print("|cff33ff99SmartHide|r status:")
    for _, group in ipairs(groups) do
        local state = isEnabled(group.key) and "|cff33ff99ON|r" or "|cffff3333OFF|r"
        print(string.format("  %-22s [%s]  (/smarthide toggle %s)", group.label, state, group.key))
    end
end

local function printHelp()
    print("|cff33ff99SmartHide|r commands:")
    print("  /smarthide status        - show current settings")
    print("  /smarthide options       - open the options panel")
    print("  /smarthide toggle <key>  - enable/disable a group")
    print("  /smarthide on <key>      - enable a group")
    print("  /smarthide off <key>     - disable a group")
end

local function findGroup(key)
    for _, group in ipairs(groups) do
        if group.key == key then
            return group
        end
    end
    return nil
end

local function setGroupState(group, enabled)
    SmartHideDB[group.key] = enabled
    if not enabled and InCombatLockdown() then
        -- If we're disabling a group while it's currently hidden,
        -- bring it back immediately so it doesn't get stuck hidden.
        applyToGroup(group, true)
    end
end

SLASH_SMARTHIDE1 = "/smarthide"
SlashCmdList["SMARTHIDE"] = function(msg)
    msg = msg or ""
    local cmd, arg = msg:match("^(%S*)%s*(%S*)$")
    cmd = (cmd or ""):lower()
    arg = (arg or ""):lower()

    if cmd == "" or cmd == "status" then
        printStatus()
    elseif cmd == "options" or cmd == "config" then
        if SmartHideOptionsPanel then
            InterfaceOptionsFrame_OpenToCategory(SmartHideOptionsPanel)
            InterfaceOptionsFrame_OpenToCategory(SmartHideOptionsPanel)
        end
    elseif cmd == "toggle" or cmd == "on" or cmd == "off" then
        local group = findGroup(arg)
        if not group then
            print("|cff33ff99SmartHide|r: unknown group '" .. arg .. "'. Use /smarthide status to see valid keys.")
            return
        end

        if cmd == "toggle" then
            setGroupState(group, not isEnabled(group.key))
        elseif cmd == "on" then
            setGroupState(group, true)
        elseif cmd == "off" then
            setGroupState(group, false)
        end

        local state = isEnabled(group.key) and "HIDDEN" or "DISPLAYED"
        print("|cff33ff99SmartHide|r: " .. group.label .. " is now " .. state)
        if SmartHideOptionsPanel and SmartHideOptionsPanel.RefreshCheckboxes then
            SmartHideOptionsPanel:RefreshCheckboxes()
        end
    else
        printHelp()
    end
end

-- ============================================================
-- Options Panel (Interface > AddOns > SmartHide)
-- ============================================================

local panel = CreateFrame("Frame", "SmartHideOptionsPanel", UIParent)
panel.name = "SmartHide"
panel:Hide()

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("SmartHide")

local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
subtitle:SetWidth(500)
subtitle:SetJustifyH("LEFT")
subtitle:SetText("Choose which UI elements to hide while you're in combat.")

panel.checkboxes = {}

local function createCheckbox(group, anchorTo, index)
    local cb = CreateFrame("CheckButton", "SmartHideCheckbox_" .. group.key, panel, "InterfaceOptionsCheckButtonTemplate")
    if index == 1 then
        cb:SetPoint("TOPLEFT", anchorTo, "BOTTOMLEFT", 0, -24)
    else
        cb:SetPoint("TOPLEFT", anchorTo, "BOTTOMLEFT", 0, -8)
    end
    local label = _G[cb:GetName() .. "Text"]
    if label then
        label:SetText(group.label)
    end
    cb:SetScript("OnClick", function(self)
        local checked = self:GetChecked() and true or false
        setGroupState(group, checked)
        local state = isEnabled(group.key) and "ON" or "OFF"
        print("|cff33ff99SmartHide|r: " .. group.label .. " is now " .. state)
    end)
    panel.checkboxes[group.key] = cb
    return cb
end

local lastAnchor = subtitle
for i, group in ipairs(groups) do
    lastAnchor = createCheckbox(group, lastAnchor, i)
end

function panel:RefreshCheckboxes()
    for key, cb in pairs(panel.checkboxes) do
        cb:SetChecked(isEnabled(key))
    end
end


function panel.refresh(self)
    self.snapshot = {}
    for _, group in ipairs(groups) do
        self.snapshot[group.key] = isEnabled(group.key)
    end
    self:RefreshCheckboxes()
end

function panel.okay(self)
    self.snapshot = nil
end

function panel.cancel(self)
    if self.snapshot then
        for _, group in ipairs(groups) do
            if self.snapshot[group.key] ~= nil then
                setGroupState(group, self.snapshot[group.key])
            end
        end
    end
    self.snapshot = nil
    self:RefreshCheckboxes()
end

panel:SetScript("OnShow", function(self)
    self:RefreshCheckboxes()
end)

InterfaceOptions_AddCategory(panel)