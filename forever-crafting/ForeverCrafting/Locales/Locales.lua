-- Locale plumbing. Any key without a translation returns the key itself.
-- Modules add their own strings with FC:AddStrings(locale, table).
local _, FC = ...
FC.L = FC.L or {}
setmetatable(FC.L, { __index = function(_, k) return k end })

FC.locale = GetLocale()

-- Register strings for one locale. "enUS" strings always apply (as the base),
-- any other locale only applies when it matches the game language.
function FC:AddStrings(locale, strings)
    if locale ~= "enUS" and locale ~= FC.locale then return end
    for k, v in pairs(strings) do
        if locale ~= "enUS" or rawget(FC.L, k) == nil then
            rawset(FC.L, k, v)
        end
    end
end
