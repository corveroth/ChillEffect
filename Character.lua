local addonName, addonTable = ...;

--[[
	Usage note:
	The methods of this object manipulate the Blizzard APIs to populate the fields of the Character object.
	To retrieve the final data, access the tables directly.
	
	Rather than getter+setter, I've gone with updater+getter here. I feel like it makes sense.
--]]
local Character = {};
Character.__index = Character;
addonTable.Character = Character;


local ItemScanner, left = CreateFrame("GameTooltip"), {}
    for i = 1, 5 do
        local L, R = ItemScanner:CreateFontString(), ItemScanner:CreateFontString()
        L:SetFontObject(GameFontNormal)
        R:SetFontObject(GameFontNormal)
        ItemScanner:AddFontStrings(L,R)
        left[i] = L
    end
    ItemScanner.left = left

local function IsSoulboundItem(bag, slot)   -- returns boolean
    ItemScanner:SetOwner(UIParent,"ANCHOR_NONE")
    ItemScanner:ClearLines()
    ItemScanner:SetBagItem(bag, slot)
    local t
	for i = 1, 5 do
		if ItemScanner.left[i]:GetText() == ITEM_SOULBOUND then
			return true
		end
	end
    ItemScanner:Hide()
    return false
end

ItemScanner:RegisterEvent("GET_ITEM_INFO_RECEIVED")
ItemScanner.itemWaitingPool = {}
function ItemScanner:AddToItemPool(link, callback)
	-- This check will itself send the remote request. Whee!
	if not GetItemInfo(link) then
		self.itemWaitingPool[link] = callback
	else
		callback(link)
	end
end
ItemScanner:SetScript("OnEvent", function(self, event, ...)
	if event == "GET_ITEM_INFO_RECEIVED" then
		for link, callback in pairs(self.itemWaitingPool) do
			if GetItemInfo(link) then
				self.itemWaitingPool[link] = nil
				callback(link)
			end
		end
	end
end)

function Character:new(db)
	local self = {};
	setmetatable(self, Character);
	
	self.db = db;
	-- self.db.currencies = {};	-- <name, count>
	-- self.db.heirlooms = {};	-- <name, location>
	-- self.db.conveyable = {};	-- <name, count>
	-- self.miscData = {};		-- <key, data>
	
	return self;
end

--[[
	Collects the names and quantities of the character's Currencies.
	NOTE: Includes gold as well, though this is not considered a Currency by Blizzard
--]]
function Character:UpdateCurrencies()
	wipe(self.db.currencies)
	
	self:ExpandCurrencyHeaders();
	
	for i=1, GetCurrencyListSize() do
		-- extraCurrencyType and itemID are used inconsistently, fuck em
		local name, isHeader, isExpanded, isUnused, isWatched, count, extraCurrencyType, icon, itemID = GetCurrencyListInfo(i);
		
		if (not isHeader) then
			self.db.currencies[name] = count;
		end
	end
	
	-- Using a global string, en-US "Money", as key.
	self.db.currencies[MONEY] = GetMoney();
end

--[[
	Expands all header rows in the Currency list
--]]
function Character:ExpandCurrencyHeaders()
	local recheck = false;
	
	for i=1, GetCurrencyListSize() do
		local _, isHeader, isExpanded = GetCurrencyListInfo(i);
		if isHeader and (not isExpanded) then
			recheck = true;
			ExpandCurrencyList(i, 1);
		end
	end
	
	if recheck then
		self:ExpandCurrencyHeaders();
	end
end

--[[
	
--]]
function Character:GetHeirloomData(location)
	
end

function Character:GetBags()

end
--[[
	
--]]
function Character:UpdateBags()
	wipe(self.db.bags)
	
	local link, name, link, rarity, count

	for bag = 0, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(bag) do
			link = GetContainerItemLink(bag, slot)
			if link then
				ItemScanner:AddToItemPool(link, function(link)
					tinsert(self.db.bags, {bag, slot, link, count})
				end)
			end
		end
	end
end

function Character:UpdateBank()
	wipe(self.db.bank)
	
	local link, name, link, rarity, count
	for bag = NUM_BAG_SLOTS, NUM_BAG_SLOTS+NUM_BANKBAGSLOTS do
		if bag == NUM_BAG_SLOTS then bag = 0 end -- a little hackish; the main bank inventory is slot 0 and bank bags start at NUM_BAG_SLOTS+1
		for slot = 1, GetContainerNumSlots(bag) do
			link = GetContainerItemLink(bag, slot)
			if link then
				ItemScanner:AddToItemPool(link, function(link)
					tinsert(self.db.bank, {bag, slot, link, count})
				end)
			end
		end
	end
end

--[[
	Collects broad identifying information about the character.
	Currently collected data consists of:
		
	@return charData - an associative array mapping noteworthy quality names to their values
--]]
function Character:GetMiscData()
	local miscData;
	
	return miscData;
end