local addonName, addonTable = ...;

local CECF_HEADER_HEIGHT = 84; -- Distance to the top of the inset
local CECF_MAX_WIDTH = 530;
local CECF_COLUMN_PADDING = 8;
local CECF_COLUMN_MARGIN = 1;
local CECF_FIRST_COLUMN_MIN_WIDTH = 140;
local CECF_LAST_COLUMN_MIN_WIDTH = 24;
local NUM_MAX_CURRENCY_HEADERS = 10; -- Mostly a sanity check. We'll run out of space first.

-- id = {name, preferredDigits, texturePath}
-- IDs are used for ordering at initial load. Subsequent loads read {priority: ID} pairs from the db.
local CURRENCY_DATA = {
	{"Gold", 							6,	[[Interface\MoneyFrame\UI-GoldIcon]]},
	{"Justice Points", 					4,	[[Interface\Icons\pvecurrency-justice]]},
	{"Valor Points", 					4,	[[Interface\Icons\pvecurrency-valor]]},
	{"Elder Charms of Good Fortune", 	2,	[[Interface\Icons\inv_misc_coin_17]]},
	{"Lesser Charms of Good Fortune",	4,	[[Interface\Icons\inv_misc_coin_18]]},
	{"Honor Points",					4,	[[Interface\Icons\PVPCurrency-Honor-Horde]]},
	{"Conquest Points",					5,	[[Interface\Icons\PVPCurrency-Conquest-Horde]]},
	{"Ironpaw Tokens",					3,	[[Interface\Icons\inv_relics_idolofferocity]]},
	{"Darkmoon Prize Tickets",			4,	[[Interface\Icons\Inv_misc_ticket_darkmoon_01]]},
	{"Epicurean's Awards",				3,	[[Interface\Icons\INV_Misc_Ribbon_01]]},
	{"Dalaran Jewelcrafter's Tokens",	3,	[[Interface\Icons\Inv_misc_gem_variety_01]]},
	{"Illustrious Jewelcrafter's Tokens",3,	[[Interface\Icons\Inv_misc_token_argentdawn3]]},
	{"Tol Barad Commendations",			4,	[[Interface\Icons\Achievement_zone_tolbarad]]},
	{"Motes of Darkness",				2,	[[Interface\Icons\inv_elemental_primal_shadow]]},
	{"Essences of Corrupted Deathwing",	2,	[[Interface\Icons\spell_shadow_sealofkings]]},
	{"Champion's Seals",					4,	[[Interface\Icons\Ability_Paladin_ArtOfWar]]},
}



local Currencies = {}
function Currencies:CreateCurrencyFrame()
	ChillEffectCurrencyFrame = CreateFrame("Frame", "ChillEffectCurrencyFrame", CharacterFrame, "PortraitFrameTemplate")
	ChillEffectCurrencyFrame:SetAllPoints()
	ChillEffectCurrencyFrame:Hide()
	ChillEffectCurrencyFrame:SetHitRectInsets(0, 30, 0, 75) -- borrowed from the PaperDollFrame

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

	ChillEffectCurrencyFrameInset = CreateFrame("Frame", "ChillEffectCurrencyFrameInset", ChillEffectCurrencyFrame, "InsetFrameTemplate")
	ChillEffectCurrencyFrameInset:SetPoint("TOPLEFT", 4, -CECF_HEADER_HEIGHT)
	ChillEffectCurrencyFrameInset:SetPoint("BOTTOMRIGHT", -6, 4)
	
	
	--== Create, but don't initialize, the headers
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
	local new, headerIcon
	for i = 1, NUM_MAX_CURRENCY_HEADERS do
		new = CreateFrame("Button", "ChillEffectCurrencyFrameHeader"..(i+1), ChillEffectCurrencyFrame, "WhoFrameColumnHeaderTemplate")
		new:SetPoint("TOPLEFT", _G["ChillEffectCurrencyFrameHeader"..(i)], "TOPRIGHT", CECF_COLUMN_MARGIN, 0)
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
		
		ChillEffectCurrencyFrame.columns[i+1] = new
	end
	
	self:RedrawCurrencyFrame()
	
	--== Create the currency-selection dropdown
	local dropdown = CreateFrame("Frame", "ChillEffectCurrencyFrameDropdown", ChillEffectCurrencyFrame, "UIDropDownMenuTemplate")
	--dropDown:SetPoint(
	UIDropDownMenu_SetWidth(dropdown, 120)
	UIDropDownMenu_Initialize(dropdown, function(self)
		local info = UIDropDownMenu_CreateInfo();
		info.text = "Select Currencies"
		info.disabled = true
		info.notCheckable = true
		info.justifyH = "CENTER"
		info.keepShownOnClick = true
		UIDropDownMenu_AddButton(info, 1)
		
		-- Start at two: You WILL see your gold!
		for i=2,#CURRENCY_DATA do
			info.text = CURRENCY_DATA[i][1]
			info.arg1 = CURRENCY_DATA[i][2]
			info.icon = CURRENCY_DATA[i][3]
			info.func = function(self, arg1, arg2, checked)
			
			end
			info.keepShownOnClick = true
			info.disabled = false
			info.isNotRadio = true
			info.notCheckable = false
			info.justifyH = nil
			UIDropDownMenu_AddButton(info, 1)
		end
	end, "MENU")

	ChillEffectCurrencyFrameDropdown = dropdown

	
	--== Make the character rows
	ChillEffectCurrencyFrame.rows = {}
	local name
	local CECF_NUM_ROWS = 5
	local CECF_ROW_HEIGHT = (ChillEffectCurrencyFrame:GetHeight()-CECF_HEADER_HEIGHT-14)/CECF_NUM_ROWS
	local scale = ChillEffectCurrencyFrame:GetEffectiveScale()
	for i=1,CECF_NUM_ROWS do
		name = "ChillEffectCurrencyFrameRow"..i
		
		new  = CreateFrame("Button", name, ChillEffectCurrencyFrame)
		-- Attach it to the ChillEffectCurrencyFrame
			-- new:SetPoint("TOPLEFT", ChillEffectCurrencyFrame, "TOPLEFT", 6, -72-((CECF_FULL_HEIGHT-10)*(i-1)/11))
			-- new:SetPoint("BOTTOMRIGHT", ChillEffectCurrencyFrame, "TOPLEFT", CECF_MAX_WIDTH, -72-((CECF_FULL_HEIGHT-10)*(i)/11))
		if i == 1 then
			new:SetPoint("TOPLEFT", ChillEffectCurrencyFrame, "TOPLEFT", 6, -CECF_HEADER_HEIGHT-4)
			new:SetPoint("BOTTOMRIGHT", ChillEffectCurrencyFrame, "TOPLEFT", CECF_MAX_WIDTH, -CECF_HEADER_HEIGHT-4-CECF_ROW_HEIGHT)
		else
			new:SetPoint("TOPLEFT", _G["ChillEffectCurrencyFrameRow"..(i-1)], "BOTTOMLEFT", 0, -1)
			new:SetPoint("BOTTOMRIGHT", _G["ChillEffectCurrencyFrameRow"..(i-1)], "BOTTOMRIGHT", 0, -1-CECF_ROW_HEIGHT)
		end
		
		do -- Set up the highlight. Augh. Why no template?
			glow = new:CreateTexture(name.."GlowTopLeft", "ARTWORK")
			glow:SetTexture([[Interface\PaperDollInfoFrame\UI-Character-ReputationBar-Highlight]])
			glow:SetBlendMode("ADD")
			glow:SetSize(16, 16)
			glow:SetPoint("TOPLEFT", -1, 2)
			glow:SetTexCoord(0.06640625, 0, 0.4375, 0.65625)
			
			glow = new:CreateTexture(name.."GlowBottomLeft", "ARTWORK")
			glow:SetTexture([[Interface\PaperDollInfoFrame\UI-Character-ReputationBar-Highlight]])
			glow:SetBlendMode("ADD")
			glow:SetSize(16, 16)
			glow:SetPoint("BOTTOMLEFT", -1, -2)
			glow:SetTexCoord(0.06640625, 0, 0.65625, 0.4375)
			
			glow = new:CreateTexture(name.."GlowTopRight", "ARTWORK")
			glow:SetTexture([[Interface\PaperDollInfoFrame\UI-Character-ReputationBar-Highlight]])
			glow:SetBlendMode("ADD")
			glow:SetSize(16, 16)
			glow:SetPoint("TOPRIGHT", 1, 2)
			glow:SetTexCoord(0, 0.06640625, 0.4375, 0.65625)
			
			glow = new:CreateTexture(name.."GlowBottomRight", "ARTWORK")
			glow:SetTexture([[Interface\PaperDollInfoFrame\UI-Character-ReputationBar-Highlight]])
			glow:SetBlendMode("ADD")
			glow:SetSize(16, 16)
			glow:SetPoint("BOTTOMRIGHT", 1, -2)
			glow:SetTexCoord(0, 0.06640625, 0.65625, 0.4375)
			
			glow = new:CreateTexture(name.."GlowTop", "ARTWORK")
			glow:SetTexture([[Interface\PaperDollInfoFrame\UI-Character-ReputationBar-Highlight]])
			glow:SetBlendMode("ADD")
			glow:SetPoint("TOPLEFT", name.."GlowTopLeft", "TOPRIGHT")
			glow:SetPoint("BOTTOMRIGHT", name.."GlowTopRight", "BOTTOMLEFT")
			glow:SetTexCoord(0, 0.015, 0.4375, 0.65625)
			
			glow = new:CreateTexture(name.."GlowBottom", "ARTWORK")
			glow:SetTexture([[Interface\PaperDollInfoFrame\UI-Character-ReputationBar-Highlight]])
			glow:SetBlendMode("ADD")
			glow:SetPoint("TOPLEFT", name.."GlowBottomLeft", "TOPRIGHT")
			glow:SetPoint("BOTTOMRIGHT", name.."GlowBottomRight", "BOTTOMLEFT")
			glow:SetTexCoord(0, 0.015, 0.65625, 0.4375)	
			
			glow = new:CreateTexture(name.."GlowLeft", "ARTWORK")
			glow:SetTexture([[Interface\PaperDollInfoFrame\UI-Character-ReputationBar-Highlight]])
			glow:SetBlendMode("ADD")
			glow:SetPoint("TOPLEFT", name.."GlowTopLeft", "BOTTOMLEFT")
			glow:SetPoint("BOTTOMRIGHT", name.."GlowBottomLeft", "TOPRIGHT")
			glow:SetTexCoord(0.06640625, 0, 0.65625, 0.6)	
			
			glow = new:CreateTexture(name.."GlowRight", "ARTWORK")
			glow:SetTexture([[Interface\PaperDollInfoFrame\UI-Character-ReputationBar-Highlight]])
			glow:SetBlendMode("ADD")
			--glow:SetSize(16, 16)
			glow:SetPoint("TOPLEFT", name.."GlowTopRight", "BOTTOMLEFT")
			glow:SetPoint("BOTTOMRIGHT", name.."GlowBottomRight", "TOPRIGHT")
			glow:SetTexCoord(0, 0.06640625, 0.65625, 0.6)
		end
		
		ChillEffectCurrencyFrame.rows[i] = new
	end

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

function Currencies:RedrawCurrencyFrame(currencyOrder)
	local header
	local horzSpaceAvailable = CECF_MAX_WIDTH - CECF_FIRST_COLUMN_MIN_WIDTH - 6; -- the 6 is the left-side offset for the first tab
	-- print(horzSpaceAvailable .. "px available")
	for i = 1, NUM_MAX_CURRENCY_HEADERS do
		
		header = ChillEffectCurrencyFrame.columns[i+1]
		header:Show()
		
		horzSpaceAvailable = horzSpaceAvailable - CECF_COLUMN_MARGIN;
		
		if currencyOrder then
			print("uh oh. No currency order set")
		else
			header.mouseover = CURRENCY_DATA[i][1]
			header.icon:SetTexture(CURRENCY_DATA[i][3])
			header.icon:SetTexCoord(0, 1, 0, 1)
			
			header:SetScript("OnClick", function(self)
				-- Stuff about sorting currencies
				PlaySound("igMainMenuOptionCheckBoxOn")
			end)
		
			WhoFrameColumn_SetWidth(header, 10*CURRENCY_DATA[i][2] +2*CECF_COLUMN_PADDING)
			horzSpaceAvailable = horzSpaceAvailable - header:GetWidth()
			-- print(header:GetWidth() .. "px used, " .. horzSpaceAvailable .. " remaining")
		end
		
		-- Turn this last column into the [+] button and push the extra space into the Character tab
		-- Hide any remaining buttons
		if horzSpaceAvailable < 24 then
			header.mouseover = "" --"Click to select currencies"
			header.icon:SetTexture([[Interface\Common\UI-ModelControlPanel]])
			header.icon:SetTexCoord(0.578125, 0.828125, 0.1484375, 0.2734275)
			horzSpaceAvailable = horzSpaceAvailable + header:GetWidth() - 24
				-- print(header:GetWidth() .. "re-added, 24 taken, " .. horzSpaceAvailable .. " remaining")
		
			header:SetScript("OnClick", function(self)
				ToggleDropDownMenu(1, nil, ChillEffectCurrencyFrameDropdown, header, 30, 26);
				PlaySound("igMainMenuOptionCheckBoxOn")
			end)
			
			WhoFrameColumn_SetWidth(header, CECF_LAST_COLUMN_MIN_WIDTH)
			WhoFrameColumn_SetWidth(ChillEffectCurrencyFrameHeader1, CECF_FIRST_COLUMN_MIN_WIDTH + horzSpaceAvailable)
			
			for j = i+2, NUM_MAX_CURRENCY_HEADERS+1 do
				ChillEffectCurrencyFrame.columns[j]:Hide()
			end
			break
		end
		
		
	end
end

addonTable.Currencies = Currencies