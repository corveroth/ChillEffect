local addonName, addonTable = ...;

local CECF_HEADER_HEIGHT = 84; -- Distance to the top of the inset
local CECF_MAX_WIDTH = 530;
local CECF_TOTALS_ROW_HEIGHT = 20;
local CECF_COLUMN_PADDING = 3;
local CECF_COLUMN_MARGIN = 1;
local CECF_MAX_CHARACTERS_PER_REALM = 11
local CECF_NUM_ROWS = 11
local CECF_FIRST_COLUMN_MIN_WIDTH = 0;
local CECF_LAST_COLUMN_MIN_WIDTH = 24;
local MIN_COLUMN_CHAR_WIDTH = 5;
local NUM_MAX_CURRENCY_HEADERS = 6; -- Mostly a sanity check. We'll run out of space first.
local CharacterModule = addonTable.Character

--[[
	Names are as returned by GetCurrencyListInfo for the relevant row. Localization: to-do
	IDs are used for ordering. Could be a bitfield I suppose.
	category*100 + expansion*10 + order*1
	
	categories:
		0	Always relevant
		1	PvE (generic)
		2	PvE (specific dungeon/patch)
		3	PvP (generic)
		4	PvP	(specific battleground)
		5	Crafting
		6	Miscellaneous
	expansions:	In case of overlap, use the latter expansion
		0	Always relevant
		1	Classic
		2	Burning Crusade
		3	Wrath of the Lich King
		4	Cataclysm
		5	Mists of Pandaria
	
--]]
local CURRENCY_DATA = {
	{"Money", 							6,	[[Interface\MoneyFrame\UI-GoldIcon]],				001},
	{"Justice Points", 					4,	[[Interface\Icons\pvecurrency-justice]],			101},
	{"Valor Points", 					4,	[[Interface\Icons\pvecurrency-valor]],				102},
	{"Elder Charm of Good Fortune", 	2,	[[Interface\Icons\inv_misc_coin_17]],				251},
	{"Lesser Charm of Good Fortune",	4,	[[Interface\Icons\inv_misc_coin_18]],				252},
	{"Honor Points",					4,	[[Interface\Icons\PVPCurrency-Honor-Horde]],		301},
	{"Conquest Points",					5,	[[Interface\Icons\PVPCurrency-Conquest-Horde]],		302},
	{"Ironpaw Token",					3,	[[Interface\Icons\inv_relics_idolofferocity]],		551},
	{"Darkmoon Prize Ticket",			4,	[[Interface\Icons\Inv_misc_ticket_darkmoon_01]],	601},
	{"Epicurean's Award",				3,	[[Interface\Icons\INV_Misc_Ribbon_01]],				541},
	{"Dalaran Jewelcrafter's Token",	3,	[[Interface\Icons\Inv_misc_gem_variety_01]],		531},
	{"Illustrious Jewelcrafter's Token",3,	[[Interface\Icons\Inv_misc_token_argentdawn3]],		542},
	{"Tol Barad Commendation",			4,	[[Interface\Icons\Achievement_zone_tolbarad]],		441},
	{"Mote of Darkness",				2,	[[Interface\Icons\inv_elemental_primal_shadow]],	241},
	{"Essence of Corrupted Deathwing",	2,	[[Interface\Icons\spell_shadow_sealofkings]],		242},
	{"Champion's Seal",					4,	[[Interface\Icons\Ability_Paladin_ArtOfWar]],		231},
}



local Currencies = {}
function Currencies:SetDB(db)
	self.db = db
end

function Currencies:GetDB()
	-- assert(self.db)
	return self.db
end
-- Body rows get zebra striping and mouseover highlights.
-- Non-body rows get icons in each column.
local function CreateRow(name, isBodyRow)
	local new = CreateFrame("Button", name, ChillEffectCurrencyFrame)
	
	if isBodyRow then
		--== Highlight is the parent for the mouseover
		local highlight = CreateFrame("Frame", name.."Highlight", new)
		highlight:SetPoint("TOPLEFT", 0, 1)
		highlight:SetPoint("BOTTOMRIGHT", 0, -1)
		new.highlight = highlight
			
		--== Create zebra striping
		new.stripe = new:CreateTexture()
		new.stripe:SetTexture(1, 1, 1, 0.05)
		new.stripe:SetPoint("TOPLEFT", 0, 0)--1)
		new.stripe:SetPoint("BOTTOMRIGHT", 0, 0)--1)
			
		--== Create mouseover highlight
		local highlightTexture
		
		highlightTexture = highlight:CreateTexture(highlight:GetName().."TopLeft", "ARTWORK")
		highlightTexture:SetTexture([[Interface\PaperDollInfoFrame\UI-Character-ReputationBar-Highlight]])
		highlightTexture:SetBlendMode("ADD")
		highlightTexture:SetSize(16, 15)
		highlightTexture:SetPoint("TOPLEFT", -1, 3)
		highlightTexture:SetTexCoord(0.06640625, 0, 0.4375, 0.65625)
		
		highlightTexture = highlight:CreateTexture(highlight:GetName().."BottomLeft", "ARTWORK")
		highlightTexture:SetTexture([[Interface\PaperDollInfoFrame\UI-Character-ReputationBar-Highlight]])
		highlightTexture:SetBlendMode("ADD")
		highlightTexture:SetSize(16, 15)
		highlightTexture:SetPoint("BOTTOMLEFT", -1, -3)
		highlightTexture:SetTexCoord(0.06640625, 0, 0.65625, 0.4375)
		
		highlightTexture = highlight:CreateTexture(highlight:GetName().."TopRight", "ARTWORK")
		highlightTexture:SetTexture([[Interface\PaperDollInfoFrame\UI-Character-ReputationBar-Highlight]])
		highlightTexture:SetBlendMode("ADD")
		highlightTexture:SetSize(16, 15)
		highlightTexture:SetPoint("TOPRIGHT", 1, 3)
		highlightTexture:SetTexCoord(0, 0.06640625, 0.4375, 0.65625)
		
		highlightTexture = highlight:CreateTexture(highlight:GetName().."BottomRight", "ARTWORK")
		highlightTexture:SetTexture([[Interface\PaperDollInfoFrame\UI-Character-ReputationBar-Highlight]])
		highlightTexture:SetBlendMode("ADD")
		highlightTexture:SetSize(16, 15)
		highlightTexture:SetPoint("BOTTOMRIGHT", 1, -3)
		highlightTexture:SetTexCoord(0, 0.06640625, 0.65625, 0.4375)
		
		highlightTexture = highlight:CreateTexture(highlight:GetName().."Top", "ARTWORK")
		highlightTexture:SetTexture([[Interface\PaperDollInfoFrame\UI-Character-ReputationBar-Highlight]])
		highlightTexture:SetBlendMode("ADD")
		highlightTexture:SetPoint("TOPLEFT", highlight:GetName().."TopLeft", "TOPRIGHT")
		highlightTexture:SetPoint("BOTTOMRIGHT", highlight:GetName().."TopRight", "BOTTOMLEFT")
		highlightTexture:SetTexCoord(0, 0.015, 0.4375, 0.65625)
		
		highlightTexture = highlight:CreateTexture(highlight:GetName().."Bottom", "ARTWORK")
		highlightTexture:SetTexture([[Interface\PaperDollInfoFrame\UI-Character-ReputationBar-Highlight]])
		highlightTexture:SetBlendMode("ADD")
		highlightTexture:SetPoint("TOPLEFT", highlight:GetName().."BottomLeft", "TOPRIGHT")
		highlightTexture:SetPoint("BOTTOMRIGHT", highlight:GetName().."BottomRight", "BOTTOMLEFT")
		highlightTexture:SetTexCoord(0, 0.015, 0.65625, 0.4375)	
		
		highlightTexture = highlight:CreateTexture(highlight:GetName().."Left", "ARTWORK")
		highlightTexture:SetTexture([[Interface\PaperDollInfoFrame\UI-Character-ReputationBar-Highlight]])
		highlightTexture:SetBlendMode("ADD")
		highlightTexture:SetPoint("TOPLEFT", highlight:GetName().."TopLeft", "BOTTOMLEFT")
		highlightTexture:SetPoint("BOTTOMRIGHT", highlight:GetName().."BottomLeft", "TOPRIGHT")
		highlightTexture:SetTexCoord(0.06640625, 0, 0.65625, 0.6)	
		
		highlightTexture = highlight:CreateTexture(highlight:GetName().."Right", "ARTWORK")
		highlightTexture:SetTexture([[Interface\PaperDollInfoFrame\UI-Character-ReputationBar-Highlight]])
		highlightTexture:SetBlendMode("ADD")
		highlightTexture:SetPoint("TOPLEFT", highlight:GetName().."TopRight", "BOTTOMLEFT")
		highlightTexture:SetPoint("BOTTOMRIGHT", highlight:GetName().."BottomRight", "TOPRIGHT")
		highlightTexture:SetTexCoord(0, 0.06640625, 0.65625, 0.6)
		
		highlight:Hide()
		
		new:SetScript("OnEnter", function(self)
			self.highlight:Show()
		end)
		new:SetScript("OnLeave", function(self)
			self.highlight:Hide()
		end)		
	end
	
	--== Create columns
	local column
	new.columns = {}
	for j = 1, NUM_MAX_CURRENCY_HEADERS+2 do
		column = CreateFrame("Frame", name.."Column"..j, new)
		
		column.text = column:CreateFontString()
		column.text:SetFontObject("GameFontWhite")
		column.text:SetPoint("LEFT", CECF_COLUMN_PADDING*2, 0) -- It needed some space. Weird, I know.
		column.text:SetPoint("RIGHT", -CECF_COLUMN_PADDING, 0)
		
		if j == 1 then
			column:SetPoint("TOPLEFT", new, "TOPLEFT", 0, 0)
			column:SetPoint("BOTTOMLEFT", new, "BOTTOMLEFT", 0, 0)
			column.text:SetJustifyH("LEFT")
		else
			column:SetPoint("TOPLEFT", new.columns[j-1], "TOPRIGHT", CECF_COLUMN_MARGIN, 0)
			column:SetPoint("BOTTOMLEFT", new.columns[j-1], "BOTTOMRIGHT", CECF_COLUMN_MARGIN, 0)
			column.text:SetJustifyH("RIGHT")
		end
		
		-- if isBodyRow then
			column.stripe = column:CreateTexture()
			column.stripe:SetTexture(1, 1, 1, 0.07)
			column.stripe:SetPoint("TOPLEFT", 0, 0)
			column.stripe:SetPoint("BOTTOMRIGHT", 0, 0)
			
			if j % 2 == 0 then
				column.stripe:Show()
			else
				column.stripe:Hide()
			end
		-- end
		
		if not isBodyRow then
			if j > 1 then -- We'll never need the icon in the first column
				column.icon = column:CreateTexture()
				column.icon:SetPoint("CENTER")
				column.icon:SetSize(CECF_TOTALS_ROW_HEIGHT, CECF_TOTALS_ROW_HEIGHT)
			end
		end
	
		new.columns[j] = column
	end
	
	return new
end

-- Future self, you're probably going to forget this, but this gets called after the GUI updates, not before.
-- You're welcome. I love you man. ~Your Past Self
local function DropdownRow_OnClick(self, arg1, arg2, checked)
	-- arg1 = currencyID, arg2 = nil
	
	if checked then
		self.db.global.shown[arg1] = true
	else
		self.db.global.shown[arg1] = nil
	end
	
	if #self.db.global.shown >= 6 then
		print("You may only track 6 currencies at once")
		return
	end
end

function Currencies:CreateCurrencyFrame()
	ChillEffectCurrencyFrame = CreateFrame("Frame", "ChillEffectCurrencyFrame", CharacterFrame, "PortraitFrameTemplate")
	ChillEffectCurrencyFrame:SetAllPoints()
	
	-- Set the anchors for the inset during Redraw, because it will shift depending on the number of factions
	ChillEffectCurrencyFrameInset = CreateFrame("Frame", "ChillEffectCurrencyFrameInset", ChillEffectCurrencyFrame, "InsetFrameTemplate")
	
	ChillEffectCurrencyFrame:CreateTexture("ChillEffectCurrencyFramePortrait", "OVERLAY")
	ChillEffectCurrencyFramePortrait:SetSize(60, 60)
	ChillEffectCurrencyFramePortrait:SetPoint("TOPLEFT", -6, 7)
	hooksecurefunc("CharacterFrame_UpdatePortrait", function()
		local masteryIndex = GetSpecialization();
		if (masteryIndex == nil) then
			local _, class = UnitClass("player");
			ChillEffectCurrencyFramePortrait:SetTexture("Interface\\TargetingFrame\\UI-Classes-Circles");
			ChillEffectCurrencyFramePortrait:SetTexCoord(unpack(CLASS_ICON_TCOORDS[class]));
		else
			local _, _, _, icon = GetSpecializationInfo(masteryIndex);
			ChillEffectCurrencyFramePortrait:SetTexCoord(0, 1, 0, 1);
			SetPortraitToTexture(ChillEffectCurrencyFramePortrait, icon); 
		end
	end)

	ChillEffectCurrencyFrameCloseButton:HookScript("OnClick", function()
		CharacterFrameCloseButton:Click()
	end)
	
	ChillEffectCurrencyFrame:Hide()
	

	--== Create, but don't initialize, the headers
	do
		ChillEffectCurrencyFrame.columns = {}
		-- Set the character header
		ChillEffectCurrencyFrameHeader1 = CreateFrame("Button", "ChillEffectCurrencyFrameHeader1", ChillEffectCurrencyFrame, "WhoFrameColumnHeaderTemplate")
		ChillEffectCurrencyFrameHeader1:SetPoint("TOPLEFT", 6, -62)
		ChillEffectCurrencyFrameHeader1:SetScript("OnClick", function()
			PlaySound("igMainMenuOptionCheckBoxOn")
		end)
		ChillEffectCurrencyFrameHeader1:SetText("Character")
		WhoFrameColumn_SetWidth(ChillEffectCurrencyFrameHeader1, CECF_FIRST_COLUMN_MIN_WIDTH)
		ChillEffectCurrencyFrame.columns[1] = ChillEffectCurrencyFrameHeader1
		
		-- OnClick scripts are set during redraw because the last button functions differently
		local new, headerIcon --, active
		for i = 2, NUM_MAX_CURRENCY_HEADERS+2 do -- currencies + characters + expand button
			new = CreateFrame("Button", "ChillEffectCurrencyFrameHeader"..(i), ChillEffectCurrencyFrame, "WhoFrameColumnHeaderTemplate")
			new:SetPoint("TOPLEFT", _G["ChillEffectCurrencyFrameHeader"..(i-1)], "TOPRIGHT", CECF_COLUMN_MARGIN, 0)
			new:SetScript("OnMouseDown", function(self)
				self.icon:SetPoint("TOP", 2, -6)
			end)
			new:SetScript("OnMouseUp", function(self)
				self.icon:SetPoint("TOP", 0, -4)
			end)
			new.icon = new:CreateTexture(new:GetName().."Icon", "ARTWORK")
			new.icon:SetSize(16, 16)
			new.icon:SetPoint("TOP", 0, -4)
			new:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
				GameTooltip:SetText(self.mouseover);
			end)
			new:SetScript("OnLeave", GameTooltip_Hide)
			
			-- new.active = new:CreateTexture(new:GetName().."ActiveLeft", "BORDER")
			-- new.active:SetTexture([[Interface/PaperDollInfoFrame/UI-Character-Tab-RealHighlight]])
			-- new.active:SetBlendMode("ADD")
			-- new.active:SetRotation(PI)
			-- new.active:SetPoint("TOPLEFT", -20, 12)
			-- new.active:SetPoint("BOTTOMRIGHT", 20, -12)
			-- new.active:Hide()

			ChillEffectCurrencyFrame.columns[i] = new
		end
	end
	
	--== Create the currency-selection dropdown
	local dropdown = CreateFrame("Frame", "ChillEffectCurrencyFrameDropdown", ChillEffectCurrencyFrame, "UIDropDownMenuTemplate")
	UIDropDownMenu_Initialize(dropdown, function(self)
		local info = UIDropDownMenu_CreateInfo();
		info.text = "Select Currencies"
		info.disabled = true
		info.isTitle = true
		info.notCheckable = true
		info.justifyH = "CENTER"
		info.keepShownOnClick = true
		UIDropDownMenu_AddButton(info, 1)
		
		for i=1,#CURRENCY_DATA do
			info.text = CURRENCY_DATA[i][1]
			info.arg1 = CURRENCY_DATA[i][1]
			info.icon = CURRENCY_DATA[i][3]
			info.func = DropdownRow_OnClick
			info.keepShownOnClick = true
			info.disabled = false
			info.isTitle = false
			info.isNotRadio = true
			info.notCheckable = false
			info.justifyH = nil
			info.checked = function()
				if (Currencies:GetDB()).global.shown[CURRENCY_DATA[i][1]] then
					return true
				end
			end
			UIDropDownMenu_AddButton(info, 1)
			
		end
	end, "MENU")
	ChillEffectCurrencyFrameDropdown = dropdown

	
	--== Make the character rows
	ChillEffectCurrencyFrame.rows = {}
	local CECF_ROW_HEIGHT = (ChillEffectCurrencyFrame:GetHeight()-CECF_HEADER_HEIGHT-44-8)/CECF_MAX_CHARACTERS_PER_REALM
	for index = 1, CECF_NUM_ROWS do
		ChillEffectCurrencyFrame.rows[index] = CreateRow("ChillEffectCurrencyFrameRow"..index, true)
		
		if index % 2 == 0 then
			ChillEffectCurrencyFrame.rows[index].stripe:Show()
		else
			ChillEffectCurrencyFrame.rows[index].stripe:Hide()
		end
	end

	--== Make the totals rows
	ChillEffectCurrencyFrame.totals = {}
	for index = 1,2 do
		ChillEffectCurrencyFrame.totals[index] = CreateRow("ChillEffectCurrencyFrameTotals"..index, false)
	end
	
	--== CharacterFrame tab-shuffling magic
	ChillEffectCurrencyFrame:SetID(5)
	tinsert(CHARACTERFRAME_SUBFRAMES, "ChillEffectCurrencyFrame")
	ChillEffectCurrencyFrame:SetScript("OnShow", function()
		CharacterFrame:SetWidth(CHARACTERFRAME_EXPANDED_WIDTH)
		CharacterFrame.Expanded = true;
		UpdateUIPanelPositions(CharacterFrame);
	end )
	ChillEffectCurrencyFrame:SetScript("OnHide", function()
		CharacterFrame:SetWidth(PANEL_DEFAULT_WIDTH)
		CharacterFrame.Expanded = false;
		UpdateUIPanelPositions(CharacterFrame);
	end )
	self.frame = ChillEffectCurrencyFrame;
end

-- If this is the money column, display it in gold. If the text would overflow the expected column width, try to bignumber it.
local function SetCurrencyColumnText(column, currencyName, currencyWidth, count)
	if currencyName == MONEY then
		if count >= 10000 then
			column.text:SetText(floor(count/10000))
		else
			column.text:SetText(count/10000)
		end
	elseif log10(count) > currencyWidth then -- Honestly, what the hell? We'll try bignumbering it to fit, but this will probably never happen anyways.
		column.text:SetText(floor(count/1000).."k")
	else
		column.text:SetText(count)
	end
end

-- Sets the width of the header, body entries, and totals columns
local function SetColumnWidth(columnIndex, columnWidth)
	WhoFrameColumn_SetWidth(ChillEffectCurrencyFrame.columns[columnIndex], columnWidth)
	for j=1, CECF_NUM_ROWS do
		ChillEffectCurrencyFrame.rows[j].columns[columnIndex]:SetWidth(columnWidth)
	end
	for j=1, 2 do
		ChillEffectCurrencyFrame.totals[j].columns[columnIndex]:SetWidth(columnWidth)
	end
end

local sortType = "Name"
local sortOrder = "ascending"
local function SetSortingOrder(header)
	if sortType == header.sortType then
		if sortOrder == "ascending" then
			sortOrder = "descending"
		else
			sortOrder = "ascending"
		end
	else
		sortType = header.sortType
		sortOrder = "descending"
	end
	-- print(format("Sorting by %s %s", sortType, sortOrder))
	PlaySound("igMainMenuOptionCheckBoxOn")
	Currencies:RedrawCurrencyFrame()
end

local function ShowSelectionDropdown(header)
	ToggleDropDownMenu(1, nil, ChillEffectCurrencyFrameDropdown, header, 30, 26);
	PlaySound("igMainMenuOptionCheckBoxOn")
end

function Currencies:RedrawCurrencyFrame()
	local header
	local currencyName, currencyWidth, currencyIcon 
	local hasHorde, hasAlliance, hasNeutral, numFactions
	local realmName = GetRealmName()
	
	--== Do we have multiple factions on this realm?
	hasHorde = self.db.sv.factionrealm["Horde - ".. realmName] and true or false
	hasAlliance = self.db.sv.factionrealm["Alliance - ".. realmName] and true or false
	hasNeutral = self.db.sv.factionrealm["Neutral - ".. realmName] and true or false
	numFactions = (hasHorde and 1 or 0) + (hasAlliance and 1 or 0) -- + (hasNeutral and 1 or 0)
	
	--== Let's figure out the sorting. Pull everyone into a pair of {characterKey, sortTypeValue} tables, sort those, and use the resulting order
	local character, count
	local sortTable = {}
	for k, v in pairs(self.db.sv.realm[realmName]) do
		character = self.db.sv.char[k.." - ".. realmName]
		if sortType == "Name" then
			tinsert(sortTable, {k, character, k})
		else
			count = CharacterModule.GetCurrencyCount(character, sortType) or 0
			tinsert(sortTable, {k, character, count})
		end
	end
	sort(sortTable, function(a,b) 
		if sortOrder == "ascending" then
			if a[3] < b[3] then
				return true
			elseif a[3] == b[3] and a[1] < b[1] then 
				return true
			else
				return false
			end
		else
			if b[3] < a[3] then
				return true
			elseif a[3] == b[3] and a[1] < b[1] then 
				return true
			else
				return false
			end
		end
	end)
	
	--== Set the first column, the character names, using the savedVars for this realm
	local row = 1
	local widestName = 0
	for k, v in pairs(sortTable) do
		ChillEffectCurrencyFrame.rows[row].columns[1].text:SetText(v[1])
		if ChillEffectCurrencyFrame.rows[row].columns[1].text:GetStringWidth() > widestName then
			widestName = ChillEffectCurrencyFrame.rows[row].columns[1].text:GetStringWidth()
		end
		row = row + 1
	end
	for i = 2, 2 do
		ChillEffectCurrencyFrame.totals[i].columns[1].text:SetText("Totals:")
	end
	ChillEffectCurrencyFrame.columns[1]:SetScript("OnClick", SetSortingOrder)
	ChillEffectCurrencyFrame.columns[1].sortType = "Name"
	
	--== That told us how many characters (rows) we need to show
	for i=row, CECF_NUM_ROWS do
		ChillEffectCurrencyFrame.rows[row]:Hide()
	end
	--== Also, how much space are the names taking? Subtract that, plus the left-side offset, and let's start our column-squeeing mojo
	local horzSpaceAvailable = CECF_MAX_WIDTH - widestName - 6;
	
	local customShown
	if self.db.global.shown then
		customShown = {}
		for k, v in pairs(self.db.global.shown) do
			local currencyIndex
			for i, currencyData in ipairs(CURRENCY_DATA) do
				if currencyData[1] == v then
					currencyIndex = i
				end
			end
			tinsert(customShown, currencyIndex)
		end
		sort(customShown)
	end
	
	--== Okay now figure out the columns
	local numCurrencyColumns
	if customShown then
		numCurrencyColumns = #customShown + 1
	else
		numCurrencyColumns = NUM_MAX_CURRENCY_HEADERS + 1
	end
	
	for i = 1, numCurrencyColumns do
		
		horzSpaceAvailable = horzSpaceAvailable - CECF_COLUMN_MARGIN;
		
		if customShown then
			currencyName, currencyWidth, currencyIcon = unpack(CURRENCY_DATA[customShown[i]])
		else
			currencyName, currencyWidth, currencyIcon = unpack(CURRENCY_DATA[i])
		end
		
		header = ChillEffectCurrencyFrame.columns[i+1]
		header:Show()
		
		header.mouseover = currencyName
		header.icon:SetTexture(currencyIcon)
		header.sortType = currencyName
		
		header:SetScript("OnClick", SetSortingOrder)
		-- SetColumnWidth calls header:SetWidth(). Not sure how I feel about that.
		-- SetColumnWidth(i+1, 9*(currencyWidth+1) +2*CECF_COLUMN_PADDING) -- Why currencyWidth+1? Because the total has an approx max of one more digit (10 characters)
		
		-- Using min-width instead of dynamic due to the choice to implement a column cap.
		if currencyWidth < MIN_COLUMN_CHAR_WIDTH then
			SetColumnWidth(i+1, 9*(MIN_COLUMN_CHAR_WIDTH+1) +2*CECF_COLUMN_PADDING)
		else
			SetColumnWidth(i+1, 9*(currencyWidth+1) +2*CECF_COLUMN_PADDING)
		end
		horzSpaceAvailable = horzSpaceAvailable - header:GetWidth()
			
		--== Turn this last column into the [+] button and push the extra space into the Character tab, and hide any remaining buttons. Break the outer loop - we're done!
		if horzSpaceAvailable < 24 or i > NUM_MAX_CURRENCY_HEADERS then
			-- print("Breaking at column "..i)
			header.mouseover = ""
			header.icon:SetTexture([[Interface\Common\UI-ModelControlPanel]])
			header.icon:SetTexCoord(0.578125, 0.828125, 0.1484375, 0.2734275)
			horzSpaceAvailable = horzSpaceAvailable + header:GetWidth() - 24
			header:SetScript("OnClick", ShowSelectionDropdown)
			
			-- Hide the headers
			for j = i+2, NUM_MAX_CURRENCY_HEADERS+1 do
				ChillEffectCurrencyFrame.columns[j]:Hide()
			end
			
			-- Hide the rows
			for j=1, CECF_NUM_ROWS do
				ChillEffectCurrencyFrame.rows[j].columns[i+1]:Hide()
			end
			
			-- Show the faction icons, hide the stripes
			if numFactions == 1 then
				if hasAlliance then
					ChillEffectCurrencyFrame.totals[1].columns[i+1].icon:SetTexture([[Interface\PVPFrame\PVP-Currency-Alliance]])
					ChillEffectCurrencyFrame.totals[1].columns[i+1].icon:Show()
					ChillEffectCurrencyFrame.totals[1].columns[i+1].stripe:Hide()
				else
					ChillEffectCurrencyFrame.totals[1].columns[i+1].icon:SetTexture([[Interface\PVPFrame\PVP-Currency-Horde]])
					ChillEffectCurrencyFrame.totals[1].columns[i+1].icon:Show()
					ChillEffectCurrencyFrame.totals[1].columns[i+1].stripe:Hide()
				end
			elseif numFactions > 1 then
				ChillEffectCurrencyFrame.totals[1].columns[i+1].icon:SetTexture([[Interface\PVPFrame\PVP-Currency-Alliance]])
				ChillEffectCurrencyFrame.totals[1].columns[i+1].icon:Show()
				ChillEffectCurrencyFrame.totals[1].columns[i+1].stripe:Hide()
				ChillEffectCurrencyFrame.totals[2].columns[i+1].icon:SetTexture([[Interface\PVPFrame\PVP-Currency-Horde]])
				ChillEffectCurrencyFrame.totals[2].columns[i+1].icon:Show()
				ChillEffectCurrencyFrame.totals[2].columns[i+1].stripe:Hide()
			end
			-- Set this column to the right width and dump the extra space on the character name column
			SetColumnWidth(i+1, CECF_LAST_COLUMN_MIN_WIDTH)
			SetColumnWidth(1, widestName + horzSpaceAvailable)
			
			-- Peace out y'all
			break
		end
		
		--== If we get down to here, the column will have content, so set the texts. Including on the totals row(s)
		local row = 1
		local character, count
		local totals = { ["Horde"] = {}, ["Alliance"] = {} }
		totals["Horde"][currencyName] = 0
		totals["Alliance"][currencyName] = 0
		for k, v in pairs(sortTable) do
			character = v[2]
			count = CharacterModule.GetCurrencyCount(character, currencyName) or 0
			
			SetCurrencyColumnText(ChillEffectCurrencyFrame.rows[row].columns[i+1], currencyName, currencyWidth, count)
			
			if self.db.sv.factionrealm["Horde - ".. realmName][v[1]] then
				totals["Horde"][currencyName] = totals["Horde"][currencyName] + count
			elseif self.db.sv.factionrealm["Alliance - ".. realmName][v[1]] then
				totals["Alliance"][currencyName] = totals["Alliance"][currencyName] + count
			end
			row = row + 1
		end
		
		if numFactions == 1 and hasAlliance then
			SetCurrencyColumnText(ChillEffectCurrencyFrame.totals[1].columns[i+1], currencyName, currencyWidth, totals["Alliance"][currencyName])
		elseif numFactions == 1 and hasHorde then
			SetCurrencyColumnText(ChillEffectCurrencyFrame.totals[1].columns[i+1], currencyName, currencyWidth, totals["Horde"][currencyName])
		elseif numFactions > 1 then
			SetCurrencyColumnText(ChillEffectCurrencyFrame.totals[1].columns[i+1], currencyName, currencyWidth, totals["Alliance"][currencyName])
			SetCurrencyColumnText(ChillEffectCurrencyFrame.totals[2].columns[i+1], currencyName, currencyWidth, totals["Horde"][currencyName])
			-- ChillEffectCurrencyFrame.totals[2].columns[i+1].icon:Hide()
		end
		-- ChillEffectCurrencyFrame.totals[1].columns[i+1].icon:Hide()

	end
	
	ChillEffectCurrencyFrameInset:SetPoint("TOPLEFT", 4, -CECF_HEADER_HEIGHT)
	ChillEffectCurrencyFrameInset:SetPoint("BOTTOMRIGHT", -6, 4+CECF_TOTALS_ROW_HEIGHT*numFactions)
	
	local CECF_ROW_HEIGHT = (ChillEffectCurrencyFrame:GetHeight()-CECF_HEADER_HEIGHT-(4+CECF_TOTALS_ROW_HEIGHT*numFactions)-8)/(row-1) --Remember me? "row" is a local var from way up top - incremented after each character
	for index = 1, CECF_NUM_ROWS do		
		if index == 1 then
			ChillEffectCurrencyFrame.rows[index]:SetPoint("TOPLEFT", ChillEffectCurrencyFrame, "TOPLEFT", 6, -1-CECF_HEADER_HEIGHT-4)
			ChillEffectCurrencyFrame.rows[index]:SetPoint("BOTTOMRIGHT", ChillEffectCurrencyFrame, "TOPLEFT", CECF_MAX_WIDTH, -1-CECF_HEADER_HEIGHT-4-CECF_ROW_HEIGHT)
		elseif index <= CECF_MAX_CHARACTERS_PER_REALM then
			ChillEffectCurrencyFrame.rows[index]:SetPoint("TOPLEFT", ChillEffectCurrencyFrame.rows[index-1], "BOTTOMLEFT", 0, 0)
			ChillEffectCurrencyFrame.rows[index]:SetPoint("BOTTOMRIGHT", ChillEffectCurrencyFrame.rows[index-1], "BOTTOMRIGHT", 0, -CECF_ROW_HEIGHT)
		end
	end
	
	ChillEffectCurrencyFrame.totals[1]:SetPoint("TOPLEFT", ChillEffectCurrencyFrameInset, "BOTTOMLEFT", 2, -2)
	ChillEffectCurrencyFrame.totals[1]:SetPoint("BOTTOMRIGHT", ChillEffectCurrencyFrameInset, "BOTTOMLEFT", CECF_MAX_WIDTH, -2-CECF_TOTALS_ROW_HEIGHT)
	if numFactions > 1 then
		ChillEffectCurrencyFrame.totals[2]:SetPoint("TOPLEFT", ChillEffectCurrencyFrame.totals[1], "BOTTOMLEFT", 0, 0)
		ChillEffectCurrencyFrame.totals[2]:SetPoint("BOTTOMRIGHT", ChillEffectCurrencyFrame.totals[1], "BOTTOMRIGHT", 0, -CECF_TOTALS_ROW_HEIGHT)
	end
end

addonTable.Currencies = Currencies