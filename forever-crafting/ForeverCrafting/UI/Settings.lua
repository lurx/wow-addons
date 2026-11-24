-- Settings page inside the main window. Controls are created once and re-anchored
-- to the canvas each time the page is shown.
local _, FC = ...
local L = FC.L
local UI = FC.UI
local U = FC.Util
local S = FC.Style
FC.SettingsPage = {}
local SP = FC.SettingsPage

local controls

local function build(parent)
    local db = FC.db
    controls = {}
    table.insert(controls, UI.Check(parent, L["Show minimap button"],
        function() return not db.minimap.hide end,
        function(v) db.minimap.hide = not v FC.Minimap:Update() end))
    table.insert(controls, UI.Check(parent, L["Show button on the profession window"],
        function() return db.showProfessionButton end,
        function(v) db.showProfessionButton = v FC.ProfessionButton:Update() end))
    table.insert(controls, UI.Check(parent, L["Show the craft bar"],
        function() return db.craftBar end,
        function(v) db.craftBar = v FC.CraftBar:Update() end))
    table.insert(controls, UI.Check(parent, L["Add zones and crafting info to item tooltips"],
        function() return db.tooltips end,
        function(v) db.tooltips = v end))
    table.insert(controls, UI.Check(parent, L["Set a waypoint when showing a place on the map"],
        function() return db.setWaypoint end,
        function(v) db.setWaypoint = v end))
    table.insert(controls, UI.Check(parent, L["Show the Auction House scan button even when Auctioneer or Auctionator is installed"],
        function() return db.forceScanButton end,
        function(v) db.forceScanButton = v end))
    table.insert(controls, UI.Check(parent, "|T" .. FC.Value.ICON .. ":0|t " .. L["Experimental: show the best value of crafted items (vendor, auction or disenchant)"],
        function() return db.experimentalValue end,
        function(v) db.experimentalValue = v FC:Fire("SKILLS_UPDATED") end))

    local factionLabel = parent:CreateFontString(nil, "OVERLAY")
    factionLabel:SetFontObject(FC.Style.fonts.body)
    factionLabel:SetText(L["Guide faction"])
    local faction = UI.ButtonGroup(parent, {
        { value = "auto", text = L["Auto"] },
        { value = "Alliance", text = L["Alliance"] },
        { value = "Horde", text = L["Horde"] },
        { value = "Both", text = L["Both"] },
    }, function() return db.faction end, function(v) db.faction = v FC:Fire("SKILLS_UPDATED") end)
    controls.factionLabel, controls.faction = factionLabel, faction

    local scaleLabel = parent:CreateFontString(nil, "OVERLAY")
    scaleLabel:SetFontObject(FC.Style.fonts.body)
    scaleLabel:SetText(L["Window scale"])
    local scale = UI.Cycle(parent, {
        { value = 0.8, text = "80%" }, { value = 0.9, text = "90%" }, { value = 1, text = "100%" },
        { value = 1.1, text = "110%" }, { value = 1.2, text = "120%" },
    }, function() return db.window.scale end, function(v) db.window.scale = v FC.Window:ApplyPosition() end, 120)
    controls.scaleLabel, controls.scale = scaleLabel, scale

    local skillLabel = parent:CreateFontString(nil, "OVERLAY")
    skillLabel:SetFontObject(FC.Style.fonts.body)
    skillLabel:SetText(L["Skill-up display"])
    local skillMode = UI.ButtonGroup(parent, {
        { value = "bar", text = L["Colour bar"] },
        { value = "text", text = L["Words"] },
        { value = "both", text = L["Both"] },
    }, function() return db.skillDisplay end, function(v) db.skillDisplay = v end)
    controls.skillLabel, controls.skill = skillLabel, skillMode
end

function SP:Render(canvas, mod)
    local parent = canvas.child
    if not controls then build(parent) end
    canvas:Text(L["Settings"], "heading")
    canvas:Space(4)
    for _, c in ipairs(controls) do
        c:ClearAllPoints()
        c:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -canvas.y)
        c:Show()
        canvas:Space(28)
    end
    canvas:Space(6)
    for _, pair in ipairs({ { controls.factionLabel, controls.faction }, { controls.scaleLabel, controls.scale }, { controls.skillLabel, controls.skill } }) do
        pair[1]:ClearAllPoints()
        pair[1]:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -(canvas.y + 4))
        pair[1]:Show()
        pair[2]:ClearAllPoints()
        pair[2]:SetPoint("TOPLEFT", parent, "TOPLEFT", 200, -canvas.y)
        pair[2]:Show()
        pair[2]:Refresh()
        canvas:Space(30)
    end
    canvas:Space(10)
    canvas:Text(FC.Prices:Footnote(), "small")
    canvas:Text(string.format(L["Alt counts from: %s"], FC.Inventory:HasSyndicator() and "Syndicator" or L["Own records"]), "small")
    canvas:Text(L["Commands: /fc, /fc settings, /fc bar"], "small")
    if mod and mod.SettingsNotes then mod:SettingsNotes(canvas) end
    -- Credit line, with a Ko-fi link beside it for anyone who wants to support the addon.
    -- The link stays hidden until FC.SUPPORT_URL points at a real page.
    if not FC.SUPPORT_URL:find("/example$") then canvas:Row({
        height = 22, left = "Forever Crafting v" .. FC.version, leftFont = "small",
        right = "|T" .. FC.SUPPORT_ICON .. ":14|t " .. U.Colorize(L["Support on Ko-fi"], unpack(S.link)), rightWidth = 160,
        onClick = function() FC:ShowCopyLink(FC.SUPPORT_URL, L["Thank you! Copy this link (Ctrl+C) and open it in your browser."]) end,
        onEnter = function(self) UI.TextTooltip(self, L["Support on Ko-fi"], { L["Click for a link you can copy into your browser."] }) end,
    }) else canvas:Text("Forever Crafting v" .. FC.version, "small") end
end

-- The canvas reuses its child for every page, so hide our controls on other pages.
hooksecurefunc(FC.Window, "Refresh", function()
    if not controls then return end
    if FC.Window.current.page ~= "settings" then
        for _, c in ipairs(controls) do c:Hide() end
        for _, k in ipairs({ "factionLabel", "faction", "scaleLabel", "scale", "skillLabel", "skill" }) do controls[k]:Hide() end
    end
end)
