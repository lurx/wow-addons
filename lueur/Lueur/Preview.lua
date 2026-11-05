-- Lueur : fenêtre d'aperçu
-- Comme la cabine d'essayage du jeu montre un équipement sur le personnage, cette fenêtre
-- montre l'effet sur un objet du décor : son modèle 3D, que la souris fait tourner, déplace
-- et rapproche, la nameplate que le jeu lui donnerait, et la lueur qui s'y accroche.
-- Lueur.lua anime la lueur comme sur une vraie cible ; ce fichier lui dit seulement où se
-- poser (ns.StartPreview) et choisit la catégorie montrée.
--
-- La lueur ne se pose pas sur l'objet mais sous sa nameplate, à un nombre fixe de pixels.
-- Pour la montrer au même endroit qu'en jeu, la fenêtre reproduit donc la géométrie du jeu :
-- la nameplate flotte à hauteur fixe au-dessus du pied de l'objet, et sa place à l'écran est
-- celle de ce point vu par la caméra. Rapprocher l'objet l'écarte de sa nameplate, donc de sa
-- lueur, exactement comme lorsqu'on marche vers lui.
-- EN: Lueur: preview window. Just as the game's dressing room shows equipment on the character, this window shows
--     the effect on a world object: its 3D model, which the mouse rotates, moves and zooms, the nameplate the game
--     would give it, and the glow attached to it. Lueur.lua animates the glow as on a real target; this file only
--     tells it where to sit (ns.StartPreview) and chooses the category shown. The glow is not placed on the object
--     but under its nameplate, at a fixed number of pixels. To show it in the same place as in game, the window
--     therefore reproduces the game's geometry: the nameplate floats at a fixed height above the object's base, and
--     its position on screen is that of this point as seen by the camera. Bringing the object closer moves it away
--     from its nameplate, and thus from its glow, exactly as when you walk toward it.

local _, ns = ...
local L = ns.L
local Skin = ns.Skin
if not Skin then return end -- jeu pas relancé depuis la mise à jour qui a apporté Skin.lua : Menu.lua le dit | EN: game not restarted since the update that brought Skin.lua: Menu.lua reports it

local WIDTH, HEIGHT = 360, 470
local DOCK_GAP = 6               -- espace laissé entre cette fenêtre et celle des réglages, onglets compris | EN: space left between this window and the settings window, tabs included
local INSET, VIEW_TOP, VIEW_BOTTOM = 8, 28, 64  -- place de la vue dans la fenêtre | EN: position of the view within the window
local FOV = math.rad(30)         -- champ de vision de la caméra | EN: camera field of view
local PITCH = math.asin(0.36)    -- la caméra plonge sous l'angle habituel du jeu : celui de GROUND, dans Effects.lua | EN: the camera looks down at the game's usual angle: that of GROUND, in Effects.lua
local START_YAW = math.pi - 0.5  -- elle regarde l'objet de trois quarts face | EN: it views the object from a three-quarter front angle
local TURN_SPEED = 0.012         -- rotation autour de l'objet, en radians par pixel de glissement | EN: rotation around the object, in radians per pixel dragged
local ZOOM_STEP = 0.88           -- distance multipliée par ce facteur à chaque cran de molette | EN: distance multiplied by this factor on each mouse wheel step
local ZOOM_NEAR, ZOOM_FAR = 0.2, 2.5  -- bornes de la distance, en fractions de celle de départ | EN: distance bounds, as fractions of the starting distance
local PAN_REACH = 4              -- distance dont la caméra peut s'écarter de l'objet, en mètres du jeu | EN: distance the camera can move away from the object, in game meters
local TRIAL_DISTANCE = 10        -- distance à laquelle se mesure la taille d'un mètre à l'écran | EN: distance at which the on-screen size of one meter is measured
local PLATE_DEFAULT = 45         -- hauteur de la nameplate au-dessus du centre de la vue, sans modèle | EN: height of the nameplate above the center of the view, without a model

-- Mesuré sur des captures du jeu (7 octobre 2026 : un coffre et deux plantes, à une dizaine de
-- mètres puis de près). La nameplate d'un objet flotte à environ deux mètres au-dessus de son
-- pied, quelle que soit sa hauteur ; et à la distance des premières captures, un mètre du jeu
-- occupe une quarantaine d'unités de l'interface.
-- EN: Measured on game screenshots (October 7, 2026: a chest and two herbs, at about ten meters and then up close).
--     An object's nameplate floats about two meters above its base, whatever its height; and at the distance of the
--     first screenshots, one game meter takes up about forty interface units.
local PLATE_HEIGHT = 2.0
-- Retail (port) : la nameplate d'un objet y flotte à hauteur fixe au-dessus de son sommet, et non du
-- pied : environ deux mètres (trois filons de tailles différentes, captures du 2026-11-01)
-- EN: Retail (port): there an object's nameplate floats at a fixed height above its top, not its base: about two
--     meters (three ore veins of different sizes, screenshots from 2026-11-01)
local RETAIL_PLATE = (select(4, GetBuildInfo()) or 0) >= 120000 and 2.2
local plateHeight = PLATE_HEIGHT -- celle du modèle montré | EN: that of the model shown
local UNITS_PER_YARD = 40

-- Modèle montré pour chaque catégorie : identifiants de fichier du client, relevés dans la
-- liste communautaire wow-listfile
-- EN: Model shown for each category: client file IDs, taken from the community wow-listfile list
local MODELS = {
	ore   = 219514,  -- world/skillactivated/tradeskillnodes/copper_miningnode_01.m2
	herb  = 219481,  -- world/skillactivated/tradeskillnodes/bush_peacebloom01.m2
	quest = 198168,  -- world/generic/human/passive doodads/crates/stormwindcrate01.m2
	chest = 219372,  -- world/skillactivated/containers/treasurechest01.m2
	bobber = 201000, -- world/goober/g_fishingbobber.m2
	other = 199999,  -- world/generic/passivedoodads/postboxes/postboxhuman.m2
}

-- Part de la hauteur du modèle qui, en jeu, reste sous le sol (un filon est un rocher à demi enterré)
-- EN: Fraction of the model's height that, in game, stays below ground (an ore vein is a half-buried rock)
local SINK = { ore = 0.3 }

local window                  -- la fenêtre, créée à sa première ouverture | EN: the window, created when first opened
local view, plate             -- la vue où se dessine l'objet ; le cadre qui y tient lieu de nameplate | EN: the view where the object is drawn; the frame that serves as the nameplate in it
local scene, actor            -- la scène 3D et son modèle ; nil sur un client qui n'en a pas | EN: the 3D scene and its model; nil on a client that lacks them
local name, caption, notice, hint  -- textes : catégorie, état montré, absence de modèle, mode d'emploi | EN: texts: category, state shown, missing model, instructions
local category = ns.CATEGORY_ORDER[1]
local fitted = true           -- le modèle chargé a été cadré | EN: the loaded model has been framed

-- La caméra tourne autour du point qu'elle vise, à une distance que règle la molette
-- EN: The camera rotates around the point it targets, at a distance set by the mouse wheel
local foot = { 0, 0, 0 }      -- pied de l'objet : le centre de sa base | EN: base of the object: the center of its bottom
local target = { 0, 0, 0 }    -- point visé ; il part du milieu entre le pied et la nameplate | EN: target point; it starts halfway between the base and the nameplate
local yaw, distance, fitDistance = START_YAW, TRIAL_DISTANCE, TRIAL_DISTANCE
local signX, signY = 1, 1     -- sens des axes « droite » et « haut » de la caméra à l'écran | EN: direction of the camera's "right" and "up" axes on screen
local drag                    -- glissement en cours : { x, y, pan }, nil sinon | EN: drag in progress: { x, y, pan }, nil otherwise
-- Décor de la cabine d'essayage (retail) : son cercle de pierre est au bas de la vue. Le pied de
-- l'objet y est maintenu en décalant la caméra de `shift` mètres le long de son axe « haut ».
-- EN: Dressing room backdrop (retail): its stone circle is at the bottom of the view. The object's base is kept
--     there by shifting the camera `shift` meters along its "up" axis.
local floorAt                 -- hauteur du cercle, en fraction de la vue ; nil sans ce décor | EN: height of the circle, as a fraction of the view; nil without this backdrop
local shift = 0
local pinned = false          -- le pied suit le cercle ; un déplacement à la souris le libère | EN: the base follows the circle; moving it with the mouse frees it

-- Change le texte d'une région, sans y toucher quand il est déjà le bon
-- EN: Changes a region's text, without touching it when it is already correct
local function SetText(region, text)
	if region:GetText() ~= text then region:SetText(text) end
end

-- Position à l'écran d'un point de la scène, en unités de l'interface depuis le coin bas
-- gauche de la vue ; rien si la caméra ne le voit pas. Le client la donne en pixels.
-- EN: On-screen position of a point in the scene, in interface units from the bottom-left corner of the view;
--     nothing if the camera cannot see it. The client gives it in pixels.
local function Project(x, y, z)
	local px, py = scene:Project3DPointTo2D(x, y, z)
	if not px or not py then return nil end
	local scale = scene:GetEffectiveScale()
	return px / scale, py / scale
end

-- Place la caméra : en plongée, tournée de `yaw` autour du point visé, à `distance` de lui.
-- La direction du regard suit la convention des caméras du jeu (Vector3D.lua).
-- EN: Positions the camera: looking down, rotated by `yaw` around the target point, at `distance` from it. The view
--     direction follows the convention of the game's cameras (Vector3D.lua).
local function PlaceCamera()
	local flat = math.cos(-PITCH)
	local x, y, z = flat * math.cos(yaw), flat * math.sin(yaw), math.sin(-PITCH)
	scene:SetCameraOrientationByYawPitchRoll(yaw, PITCH, 0)
	local upX, upY, upZ = 0, 0, 0
	if shift ~= 0 then upX, upY, upZ = scene:GetCameraUp() end
	scene:SetCameraPosition(target[1] - x * distance + upX * shift, target[2] - y * distance + upY * shift,
		target[3] - z * distance + upZ * shift)
	scene:SetLightDirection(x, y, z)
end

-- Met la vue en accord avec la caméra, et la nameplate là où cette caméra la verrait
-- EN: Brings the view in line with the camera, and the nameplate to where this camera would see it
local function UpdateView()
	PlaceCamera()
	if floorAt and pinned then
		local _, footY = Project(foot[1], foot[2], foot[3])
		if footY then
			local miss = footY - view:GetHeight() * floorAt
			if math.abs(miss) > 0.5 then
				shift = shift + miss / (UNITS_PER_YARD * fitDistance / distance) * signY
				PlaceCamera()
			end
		end
	end
	local x, y = Project(foot[1], foot[2], foot[3] + plateHeight)
	if x then plate:SetPoint("CENTER", view, "BOTTOMLEFT", x, y) end
end

-- Cadre le modèle une fois chargé : la caméra vise le milieu entre son pied et sa nameplate,
-- d'assez loin pour qu'il ait la taille qu'il a en jeu
-- EN: Frames the model once loaded: the camera targets the midpoint between its base and its nameplate, from far
--     enough away for it to have the size it has in game
local function Fit()
	fitted = true
	local x1, y1, z1, x2, y2, z2 = actor:GetActiveBoundingBox()
	if x1 and z2 then
		foot[1], foot[2], foot[3] = (x1 + x2) / 2, (y1 + y2) / 2, z1 + (z2 - z1) * (SINK[category] or 0)
	else
		foot[1], foot[2], foot[3] = 0, 0, 0 -- modèle sans volume mesurable | EN: model with no measurable volume
	end
	plateHeight = PLATE_HEIGHT
	if RETAIL_PLATE and z2 and z2 > foot[3] then plateHeight = (z2 - foot[3]) + RETAIL_PLATE end
	target[1], target[2], target[3] = foot[1], foot[2], foot[3] + plateHeight / 2
	yaw, distance = START_YAW, TRIAL_DISTANCE
	shift, pinned = 0, true
	PlaceCamera()
	-- La distance de départ se mesure plutôt qu'elle ne se calcule : on regarde ce qu'occupe à
	-- l'écran un mètre posé au point visé, vu de la distance d'essai. Les mêmes mesures disent
	-- dans quel sens vont, à l'écran, les axes de la caméra.
	-- EN: The starting distance is measured rather than calculated: we look at what a meter placed at the target
	--     point occupies on screen, seen from the test distance. The same measurements tell which way the camera's
	--     axes run on screen.
	fitDistance = view:GetHeight() / (2 * math.tan(FOV / 2) * UNITS_PER_YARD)
	signX, signY = 1, 1
	local rightX, rightY, rightZ = scene:GetCameraRight()
	local upX, upY, upZ = scene:GetCameraUp()
	local x, y = Project(target[1], target[2], target[3])
	local alongRight = Project(target[1] + rightX, target[2] + rightY, target[3] + rightZ)
	local _, alongUp = Project(target[1] + upX, target[2] + upY, target[3] + upZ)
	if x and alongRight and alongUp and alongRight ~= x and alongUp ~= y then
		fitDistance = TRIAL_DISTANCE * math.abs(alongRight - x) / UNITS_PER_YARD
		signX, signY = alongRight > x and 1 or -1, alongUp > y and 1 or -1
	end
	distance = fitDistance
	UpdateView()
	actor:Show()
end

-- Suit la souris pendant un glissement : le bouton gauche tourne autour de l'objet, le droit
-- le déplace
-- EN: Follows the mouse during a drag: the left button rotates around the object, the right one moves it
local function Drag()
	local scale = view:GetEffectiveScale()
	local x, y = GetCursorPosition()
	x, y = x / scale, y / scale
	local moveX, moveY = x - drag.x, y - drag.y
	drag.x, drag.y = x, y
	if not drag.pan then
		yaw = yaw - moveX * TURN_SPEED
		return
	end
	pinned = false
	-- l'objet suit le curseur : c'est le point visé qui glisse, en sens inverse
	-- EN: the object follows the cursor: it is the target point that slides, in the opposite direction
	local perYard = UNITS_PER_YARD * fitDistance / distance
	local right, up = -moveX / perYard * signX, -moveY / perYard * signY
	local rightX, rightY, rightZ = scene:GetCameraRight()
	local upX, upY, upZ = scene:GetCameraUp()
	local home = { foot[1], foot[2], foot[3] + plateHeight / 2 }
	local away = 0
	for index, axis in ipairs({ { rightX, upX }, { rightY, upY }, { rightZ, upZ } }) do
		target[index] = target[index] + axis[1] * right + axis[2] * up
		away = away + (target[index] - home[index]) ^ 2
	end
	-- pas plus loin que de quoi sortir l'objet de la vue
	-- EN: no farther than enough to take the object out of view
	away = math.sqrt(away)
	if away > PAN_REACH then
		for index = 1, 3 do target[index] = home[index] + (target[index] - home[index]) * PAN_REACH / away end
	end
end

-- Rapproche ou éloigne la caméra d'un cran de molette
-- EN: Moves the camera closer or farther by one mouse wheel step
local function Zoom(delta)
	if not scene or not fitted then return end
	distance = math.max(fitDistance * ZOOM_NEAR, math.min(fitDistance * ZOOM_FAR, distance * ZOOM_STEP ^ delta))
end

-- Crée la scène 3D et son modèle. Ces cadres n'existent pas sur tous les clients : sans eux,
-- la fenêtre montre la lueur seule.
-- EN: Creates the 3D scene and its model. These frames do not exist on all clients: without them, the window shows
--     the glow alone.
local function CreateScene()
	local ok, frame = pcall(CreateFrame, "ModelScene", nil, view)
	if not ok or not frame then return end
	local made
	ok = pcall(function()
		frame:SetAllPoints()
		frame:SetCameraFieldOfView(FOV)
		frame:SetCameraNearClip(0.05)
		frame:SetCameraFarClip(500)
		frame:SetLightVisible(true)
		frame:SetLightAmbientColor(0.75, 0.75, 0.75)
		frame:SetLightDiffuseColor(1, 1, 1)
		made = frame:CreateActor(nil, "ModelSceneActorTemplate")
	end)
	if ok and made then
		scene, actor = frame, made
	else
		frame:Hide()
	end
end

-- Montre une catégorie : son modèle, puis la lueur sur la nameplate qu'il aurait
-- EN: Shows a category: its model, then the glow on the nameplate it would have
local function ShowCategory(shown)
	category = shown
	drag = nil
	shift = 0
	plate:SetPoint("CENTER", view, "CENTER", 0, PLATE_DEFAULT)
	local loaded = false
	if actor then
		actor:Hide() -- le temps qu'il se charge et soit cadré | EN: while it loads and gets framed
		local ok, success = pcall(actor.SetModelByFileID, actor, MODELS[category])
		loaded = ok and success == true
		scene:SetShown(loaded)
	end
	fitted = not loaded
	notice:SetShown(not loaded)
	hint:SetShown(loaded)
	ns.StartPreview(plate, category)
end

-- Passe à la catégorie suivante, ou à la précédente ; le menu, s'il en personnalisait une, suit
-- EN: Switches to the next category, or the previous one; the menu, if it was customizing one, follows
local function Step(direction)
	local order = ns.CATEGORY_ORDER
	for index, key in ipairs(order) do
		if key == category then
			ShowCategory(order[(index - 1 + direction) % #order + 1])
			if ns.FollowPreview then ns.FollowPreview(category) end
			return
		end
	end
end

local function Update()
	SetText(window.title, L.PREVIEW)
	SetText(name, L["CATEGORY_" .. category:upper()])
	name:SetTextColor(ns.GetColor(category))
	-- la lueur a pu être reprise entre-temps (Lueur désactivé, remise à zéro) : la fenêtre la redemande
	-- EN: the glow may have been taken back in the meantime (Lueur disabled, reset): the window requests it again
	if not ns.IsPreviewing() then ns.StartPreview(plate, category) end
	SetText(caption, L["STATE_" .. ns.PreviewState():upper()])
	SetText(notice, L.PREVIEW_NO_MODEL)
	SetText(hint, L.PREVIEW_HINT)
	if not fitted then
		if actor:IsLoaded() then Fit() end
	elseif scene and scene:IsShown() then
		if drag then Drag() end
		UpdateView()
	end
end

local function CreateWindow()
	-- le même cadre que la fenêtre des réglages
	-- EN: the same frame as the settings window
	window = Skin.Window("LueurPreview", WIDTH, HEIGHT)

	-- la vue : rien de ce qu'elle contient n'en déborde, pas même une lueur réglée très grande
	-- EN: the view: nothing it contains overflows it, not even a glow set very large
	view = CreateFrame("Frame", nil, window)
	view:SetSize(WIDTH - 2 * INSET, HEIGHT - VIEW_TOP - VIEW_BOTTOM)
	view:SetPoint("TOPLEFT", INSET, -VIEW_TOP)
	view:SetClipsChildren(true)
	view:EnableMouse(true)
	view:EnableMouseWheel(true)
	view:SetScript("OnMouseDown", function(_, button)
		if not scene or not fitted then return end
		local scale = view:GetEffectiveScale()
		local x, y = GetCursorPosition()
		drag = { x = x / scale, y = y / scale, pan = button == "RightButton" }
	end)
	view:SetScript("OnMouseUp", function() drag = nil end)
	view:SetScript("OnMouseWheel", function(_, delta) Zoom(delta) end)
	local background = view:CreateTexture(nil, "BACKGROUND")
	background:SetAllPoints()
	background:SetColorTexture(0.05, 0.05, 0.07, 1)
	-- le décor de la cabine d'essayage, sur les clients qui l'ont
	-- EN: the dressing room backdrop, on clients that have it
	local class = UnitClass and select(2, UnitClass("player"))
	local atlas = type(class) == "string" and "dressingroom-background-" .. class
	if atlas and C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas) then
		background:SetAtlas(atlas)
		floorAt = 0.1 -- centre du cercle de pierre, relevé sur une capture du 2026-11-01 | EN: center of the stone circle, measured on a screenshot from 2026-11-01
		-- Le devant du sol, redessiné par-dessus le modèle : ce qui passe sous le cercle de pierre
		-- y paraît enterré. Un peu sous le pied, pour ne pas mordre le bas d'un coffre vu en plongée.
		-- EN: The front of the ground, redrawn over the model: whatever passes below the stone circle looks buried
		--     there. Slightly below the base, so as not to cut into the bottom of a chest seen from above.
		local info = C_Texture.GetAtlasInfo(atlas)
		local file = type(info) == "table" and (info.file or info.filename)
		if file and info.leftTexCoord then
			local cut = floorAt - 0.02
			local ground = CreateFrame("Frame", nil, view)
			ground:SetFrameLevel(view:GetFrameLevel() + 3)
			ground:SetPoint("BOTTOMLEFT")
			ground:SetPoint("BOTTOMRIGHT")
			ground:SetHeight(view:GetHeight() * cut)
			local front = ground:CreateTexture(nil, "ARTWORK")
			front:SetAllPoints()
			front:SetTexture(file)
			local top, bottom = info.topTexCoord, info.bottomTexCoord
			front:SetTexCoord(info.leftTexCoord, info.rightTexCoord, bottom - (bottom - top) * cut, bottom)
		end
	end

	CreateScene()
	-- la nameplate de l'objet : la lueur s'y accroche juste sous elle, donc au-dessus du modèle
	-- EN: the object's nameplate: the glow attaches just below it, hence above the model
	plate = CreateFrame("Frame", nil, view)
	plate:SetSize(1, 1)
	plate:SetFrameLevel(view:GetFrameLevel() + 5)

	notice = view:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	notice:SetPoint("BOTTOM", view, "BOTTOM", 0, 8)
	name = window:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	name:SetPoint("BOTTOM", window, "BOTTOM", 0, 42)
	caption = window:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	caption:SetPoint("BOTTOM", window, "BOTTOM", 0, 26)
	hint = window:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
	hint:SetPoint("BOTTOM", window, "BOTTOM", 0, 10)

	for direction, text in pairs({ [-1] = "<", [1] = ">" }) do
		local button = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
		button:SetSize(28, 22)
		button:SetPoint(direction < 0 and "BOTTOMLEFT" or "BOTTOMRIGHT", direction < 0 and 16 or -16, 30)
		button:SetText(text)
		button:SetScript("OnClick", function()
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION)
			Step(direction)
		end)
	end

	window:SetScript("OnShow", function() ShowCategory(category) end)
	window:SetScript("OnHide", function()
		drag = nil
		ns.StopPreview()
	end)
	window:SetScript("OnUpdate", Update)
end

-- Place la fenêtre à côté de celle des réglages quand elle est ouverte : à sa droite, ou à sa
-- gauche si la place manque ; sinon à droite du centre de l'écran, où le personnage reste visible
-- EN: Places the window next to the settings window when it is open: to its right, or to its left if there is not
--     enough room; otherwise to the right of the screen center, where the character stays visible
local function Dock()
	local menu = LueurMenu
	window:ClearAllPoints()
	if menu and menu:IsShown() then
		-- la fenêtre des réglages porte des onglets sur son bord droit : l'aperçu se range au-delà
		-- EN: the settings window has tabs on its right edge: the preview is placed beyond them
		local tab = menu.tabs and menu.tabs.look
		local tabs = tab and tab:GetWidth() or 0
		if menu:GetRight() + tabs + DOCK_GAP + WIDTH <= UIParent:GetWidth() then
			window:SetPoint("TOPLEFT", menu, "TOPRIGHT", tabs + DOCK_GAP, 0)
		elseif menu:GetLeft() >= DOCK_GAP + WIDTH then
			window:SetPoint("TOPRIGHT", menu, "TOPLEFT", -DOCK_GAP, 0)
		else
			window:SetPoint("RIGHT", UIParent, "RIGHT", -20, 0)
		end
	else
		window:SetPoint("CENTER", UIParent, "CENTER", 320, 0)
	end
end

-- Ouvre ou ferme la fenêtre d'aperçu ; renvoie true si elle est désormais ouverte
-- EN: Opens or closes the preview window; returns true if it is now open
function ns.TogglePreview()
	if not window then CreateWindow() end
	if window:IsShown() then
		window:Hide()
	else
		Dock()
		window:Show()
	end
	return window:IsShown()
end

function ns.ClosePreview()
	if window then window:Hide() end
end

-- Montre cette catégorie dans la fenêtre d'aperçu, si elle est ouverte : le menu l'appelle
-- quand on y choisit la catégorie à personnaliser
-- EN: Shows this category in the preview window, if it is open: the menu calls it when the category to customize is
--     chosen there
function ns.ShowPreviewCategory(shown)
	if window and window:IsShown() and shown ~= category then ShowCategory(shown) end
end
