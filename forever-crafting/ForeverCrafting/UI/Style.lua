-- Visual style for the parchment skin. Everything that decides how the window looks
-- lives here so a different skin (EllesmereUI later) can replace this one table.
local _, FC = ...
FC.Style = {}
local S = FC.Style

S.media = "Interface\\AddOns\\ForeverCrafting\\Media\\"
S.ink = { 0.12, 0.07, 0.03 }
S.inkSoft = { 0.28, 0.18, 0.09 }
S.accent = { 0.50, 0.16, 0.05 }
S.link = { 0.04, 0.30, 0.34 }
S.highlight = { 0.95, 0.80, 0.45, 0.35 }
S.rowAlt = { 0.55, 0.40, 0.20, 0.08 }

local function font(name, file, size, flags, color)
    local f = CreateFont(name)
    f:SetFont(file, size, flags or "")
    if color then f:SetTextColor(color[1], color[2], color[3]) end
    f:SetShadowOffset(0, 0)
    return f
end

S.fonts = {
    title = font("ForeverCraftingFontTitle", "Fonts\\MORPHEUS.TTF", 24, "", S.ink),
    heading = font("ForeverCraftingFontHeading", "Fonts\\MORPHEUS.TTF", 17, "", S.ink),
    body = font("ForeverCraftingFontBody", "Fonts\\FRIZQT__.TTF", 13, "", S.ink),
    small = font("ForeverCraftingFontSmall", "Fonts\\FRIZQT__.TTF", 11.5, "", S.inkSoft),
    tiny = font("ForeverCraftingFontTiny", "Fonts\\ARIALN.TTF", 11, "", S.inkSoft),
    pill = font("ForeverCraftingFontPill", "Fonts\\FRIZQT__.TTF", 11, "", { 0.98, 0.94, 0.84 }),
    tab = font("ForeverCraftingFontTab", "Fonts\\FRIZQT__.TTF", 12, "", { 0.98, 0.88, 0.65 }),
    number = font("ForeverCraftingFontNumber", "Fonts\\ARIALN.TTF", 13, "", S.ink),
}

-- Parchment background with a leather-and-brass border.
function S:Decorate(frame)
    local bg = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
    bg:SetTexture(self.media .. "Parchment")
    bg:SetPoint("TOPLEFT", 6, -6)
    bg:SetPoint("BOTTOMRIGHT", -6, 6)
    frame.bg = bg

    local function edge(p1, p2, horizontal)
        local t = frame:CreateTexture(nil, "BORDER")
        t:SetTexture(self.media .. "Edge", "REPEAT", "REPEAT")
        t:SetHorizTile(horizontal)
        t:SetVertTile(not horizontal)
        if horizontal then
            t:SetHeight(14)
        else
            t:SetWidth(14)
            t:SetRotation(math.pi / 2)
        end
        t:SetPoint(p1[1], frame, p1[2], p1[3], p1[4])
        t:SetPoint(p2[1], frame, p2[2], p2[3], p2[4])
        return t
    end
    edge({ "TOPLEFT", "TOPLEFT", 0, 0 }, { "TOPRIGHT", "TOPRIGHT", 0, 0 }, true)
    edge({ "BOTTOMLEFT", "BOTTOMLEFT", 0, 0 }, { "BOTTOMRIGHT", "BOTTOMRIGHT", 0, 0 }, true)
    -- Vertical edges: a plain dark leather band (rotated tiling is unreliable).
    for _, side in ipairs({ "LEFT", "RIGHT" }) do
        local t = frame:CreateTexture(nil, "BORDER")
        t:SetColorTexture(0.36, 0.22, 0.11, 1)
        t:SetWidth(8)
        t:SetPoint("TOP" .. side, frame, "TOP" .. side, 0, -6)
        t:SetPoint("BOTTOM" .. side, frame, "BOTTOM" .. side, 0, 6)
        local line = frame:CreateTexture(nil, "BORDER", nil, 1)
        line:SetColorTexture(0.86, 0.70, 0.42, 1)
        line:SetWidth(1.5)
        line:SetPoint("TOP", t, "TOP", side == "LEFT" and 3 or -3, 0)
        line:SetPoint("BOTTOM", t, "BOTTOM", side == "LEFT" and 3 or -3, 0)
    end
    for _, c in ipairs({ "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT" }) do
        local t = frame:CreateTexture(nil, "ARTWORK")
        t:SetTexture(self.media .. "Corner")
        t:SetSize(26, 26)
        t:SetPoint("CENTER", frame, c, c:find("LEFT") and 6 or -6, c:find("TOP") and -6 or 6)
    end
end

function S:Divider(parent, width)
    local t = parent:CreateTexture(nil, "ARTWORK")
    t:SetTexture(self.media .. "Divider")
    t:SetSize(width or 300, 12)
    return t
end

function S:DiffColor(diff)
    local c = FC.Util.DIFF_COLORS[diff] or self.ink
    return c[1], c[2], c[3]
end
