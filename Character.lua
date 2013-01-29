local addonName, addonTable = ...;

--[[
	Usage note:
	The methods of this object manipulate the Blizzard APIs to populate the fields of the Character object.
	To retrieve the final data, access the tables directly.
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
	self.db.currencies = {};	-- <name, count>
	self.db.heirlooms = {};	-- <name, location>
	self.db.conveyable = {};	-- <name, count>
	self.miscData = {};		-- <key, data>
	
	
	
	-- Subtle bug averted here. If these functions are defined using colon syntax, it creates conflicting "self" references as written
	local function UpdateCurrencies()
		self:GetCurrencyData();
		self.db.char.currency = self.currencies;
		addon:RedrawCurrencyFrame()
	end
	
	local function UpdateItems()
		self:GetHeirloomData(1);
		self:GetConveyableData(1);
		if self.isBankOpen then
			-- print("Scanning bank too!")
			self:GetHeirloomData(0);
			self:GetConveyableData(0);
		end
		self.db.char.heirloom = self.heirlooms
		self.db.char.conveyable = self.conveyable
	end
	
	return self;
end

function Character:GetName()
	return GetUnitName("player")
end

--[[
	Collects the names and quantities of the character's Currencies.
	NOTE: Includes gold as well, though this is not considered a Currency by Blizzard
	@return currencies - an associative array mapping currency names to their quantities
--]]
function Character:GetCurrencyData()
	local currencies = {};
	
	self:ExpandCurrencyHeaders();
	
	for i=1, GetCurrencyListSize() do
		-- extraCurrencyType and itemID are used inconsistently, fuck em
		local name, isHeader, isExpanded, isUnused, isWatched, count, extraCurrencyType, icon, itemID = GetCurrencyListInfo(i);
		
		if (not isHeader) then
			currencies[name] = count;
		end
	end
	
	-- Using a global string, en-US "Money", as key.
	currencies[MONEY] = GetMoney();
	
	self.currencies = currencies;
	return currencies;
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
	Collects a list of the heirloom items the character possesses, and their general locations (bank, bags, equipped).
	NOTE: Will fail to detect any heirlooms currently in a mailbox.
	
	@params location - 1 for bags, 2 for bank
	@return heirlooms - an associative array mapping heirloom itemIDs to their general location
--]]
function Character:GetHeirloomData(location)
	local heirlooms = {};
	
	local link
	if location == 1 then
		for bag = 0, NUM_BAG_SLOTS do
			for slot = 1, GetContainerNumSlots(bag) do
				link = GetContainerItemLink(bag, slot)
				if link then
					ItemScanner:AddToItemPool(link, function(link)
						local name, id, rarity = GetItemInfo(link)
						if rarity == 7 then
							heirlooms[name] = {bag, slot}
						end
					end)
				end
			end
		end
	else
		for bag = NUM_BAG_SLOTS, NUM_BAG_SLOTS+NUM_BANKBAGSLOTS do
			if bag == NUM_BAG_SLOTS then bag = 0 end -- a little hackish; the main bank inventory is slot 0 and bank bags start at NUM_BAG_SLOTS+1
			for slot = 1, GetContainerNumSlots(bag) do
				link = GetContainerItemLink(bag, slot)
				if link then
					ItemScanner:AddToItemPool(link, function(link)
						local name, id, rarity = GetItemInfo(link)
						if rarity == 7 then
							heirlooms[name] = {bag, slot}
						end
					end)
				end
			end
		end
	end
	
	self.heirlooms = heirlooms;
	return heirlooms;
end

--[[
	Collects the names and quantities of conveyable items the character possesses, and their general locations (bank, bags, equipped).
	Conveyable is defined as any item that is not soulbound or an heirloom.
	
	@params location - 1 for bags, 2 for bank
	@return conveyables - an associative array mapping conveyable itemIDs to their general locations
--]]
function Character:UpdateBags(location)
	local conveyables = {};
	
	local link, name, link, rarity, count
	if location == 1 then
		for bag = 0, NUM_BAG_SLOTS do
			for slot = 1, GetContainerNumSlots(bag) do
				link = GetContainerItemLink(bag, slot)
				if link then
					ItemScanner:AddToItemPool(link, function(link)
						-- local name, id, rarity = GetItemInfo(link)
						-- if rarity > 1 and rarity < 7 and not IsSoulboundItem(bag, slot) then -- skip heirlooms and vendor trash
							-- count = select(2, GetContainerItemInfo(bag, slot))
							-- if not conveyables[name] then
								-- conveyables[name] = count
							-- else
								-- conveyables[name] = conveyables[name] +count
							-- end
						-- end
						
					end)
				end
			end
		end
	else
		for bag = NUM_BAG_SLOTS, NUM_BAG_SLOTS+NUM_BANKBAGSLOTS do
			if bag == NUM_BAG_SLOTS then bag = 0 end -- a little hackish; the main bank inventory is slot 0 and bank bags start at NUM_BAG_SLOTS+1
			for slot = 1, GetContainerNumSlots(bag) do
				link = GetContainerItemLink(bag, slot)
				if link then
					ItemScanner:AddToItemPool(link, function(link)
						local name, id, rarity = GetItemInfo(link)
						if rarity > 1 and rarity < 7 and not IsSoulboundItem(bag, slot) then -- skip heirlooms and vendor trash
							count = select(2, GetContainerItemInfo(bag, slot))
							if not conveyables[name] then
								conveyables[name] = count
							else
								conveyables[name] = conveyables[name] +count
							end
						end
					end)
				end
			end
		end
	end
	
	self.conveyables = conveyables;
	return conveyables;
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