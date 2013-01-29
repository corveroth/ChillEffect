local addonName, addonTable = ...;
ChillEffectAlts = LibStub("AceAddon-3.0"):NewAddon("ChillEffectAlts", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("ChillEffectAlts", true)

function ChillEffectAlts:OnInitialize()
	local defaults = {
		char = {
			currencies = {},
			bags = {},
			inventory = {},
		},
	}
	self.db = LibStub("AceDB-3.0"):New("CEAltsDB")
	
	SLASH_ChillEffectAlts1 = "/alt"
	SlashCmdList["ChillEffectAlts"] = function()
		if self.frame:IsShown() then
			self.frame:Hide()
		else
			self.frame:Show()
		end
	end
	
	CharacterFrameTab1:SetPoint("TOPLEFT", CharacterFrame, "BOTTOMLEFT", -8, 2)
	AC = CreateFrame("Button", "CharacterFrameTab5", CharacterFrame, "CharacterFrameTabButtonTemplate", 5)
	AC:SetPoint("LEFT", "CharacterFrameTab4", "RIGHT", -15, 0)
	AC:SetText("All Characters")
	AC:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		-- Second arg = GetBindingKey(action)
		GameTooltip:SetText(MicroButtonTooltipText("All Characters", "TOGGLECHARACTER5"), 1.0,1.0,1.0 );
	end)
	AC:SetScript("OnLeave",GameTooltip_Hide)
					
	PanelTemplates_SetNumTabs(CharacterFrame, 5)
	
	local CharTabtable = {}; 
	local CF_TabBoundsCheck = function(self)
		self = self and self:GetName() or "CharacterFrameTab" -- hack to make sure it resizes when the CharacterFrame expands/collapses
		local NUM_CHARACTERFRAME_TABS = 5
		if ( string.sub(self, 1, 17) ~= "CharacterFrameTab" ) then
			return;
		end
		 
		for i=1, NUM_CHARACTERFRAME_TABS do
			_G["CharacterFrameTab"..i.."Text"]:SetWidth(0);
			PanelTemplates_TabResize(_G["CharacterFrameTab"..i], 0, nil, 36, 88);
		end
		 
		local diff = _G["CharacterFrameTab"..NUM_CHARACTERFRAME_TABS]:GetRight() - CharacterFrame:GetRight();
		 
		if ( diff > 0 ) then
			--Find the biggest tab
			for i=1, NUM_CHARACTERFRAME_TABS do
				CharTabtable[i]=_G["CharacterFrameTab"..i];
			end
			table.sort(CharTabtable, function(frame1, frame2)   return frame1:GetWidth() > frame2:GetWidth();	end);
			 
			local i=1;
			while ( diff > 0 and i <= NUM_CHARACTERFRAME_TABS) do
				local tabText = _G[CharTabtable[i]:GetName().."Text"]
				local change = min(10, diff);
				diff = diff - change;
				tabText:SetWidth(0);
				PanelTemplates_TabResize(CharTabtable[i], -change, nil, 36-change, 88);
		--		print(format("Resizing tab %s by %d", CharTabtable[i]:GetName(), change))
				i = i+1;
			end
		end
	end
	hooksecurefunc("CharacterFrame_TabBoundsCheck", CF_TabBoundsCheck)
	hooksecurefunc("CharacterFrame_Expand", CF_TabBoundsCheck)
	hooksecurefunc("CharacterFrame_Collapse", CF_TabBoundsCheck)
	
	hooksecurefunc("CharacterFrameTab_OnClick", function(self, button)
		local name = self:GetName();
		 
		if ( name == "CharacterFrameTab5" ) then
			ToggleCharacter("ChillEffectCurrencyFrame")
		end
		PlaySound("igCharacterInfoTab");
	end)
end

local gui_built = false
function ChillEffectAlts:OnEnable()
	if not gui_built then
		addonTable.Currencies:CreateCurrencyFrame()
	end
	
	local character = addonTable.Character:new(self.db.char)
	function self:RedrawCurrencyFrame(self, currencyOrder)
		addonTable.Currencies:RedrawCurrencyFrame(currencyOrder)
	end
	
	-- Track the open state of the bank. Can't check for IsShown, because addons
	self.isBankOpen = false;
	addon:RegisterEvent("BANKFRAME_OPENED", function() self.isBankOpen = true self.UpdateItems() end)
	addon:RegisterEvent("BANKFRAME_CLOSED", function() self.isBankOpen = false end)
	
	local function UpdateCurrencies()
		character.UpdateCurrencies()
		self.db.char.currencies = character.GetCurrencies()
		self:RedrawCurrencyFrame()
	end
	
	local function UpdateBags()
		character.UpdateBags()
		self.db.char.bags = character.GetBags()
		self.db.char.heirlooms = character.GetHeirlooms()
	end
	
	local function UpdateInventory()
	
	end
	addon:RegisterEvent("PLAYER_ENTERING_WORLD", UpdateCurrencies)
	addon:RegisterEvent("PLAYER_MONEY", UpdateCurrencies)
	addon:RegisterEvent("CURRENCY_DISPLAY_UPDATE", UpdateCurrencies)
	
	addon:RegisterEvent("BAG_UPDATE_DELAYED", UpdateBags)
	
end