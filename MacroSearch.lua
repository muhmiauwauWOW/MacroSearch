local _ = LibStub("LibLodash-1"):Get()

local L = {};
local locale = GetLocale()

if locale == "enUS" then
    L["SettingsText1"] = "include macro text in search"
elseif locale == "deDE" then
    L["SettingsText1"] = "Makro-Text in der Suche einbeziehen"
elseif locale == "frFR" then
    L["SettingsText1"] = "inclure le texte des macros dans la recherche"
elseif locale == "esES" then
    L["SettingsText1"] = "incluir texto de macro en la búsqueda"
elseif locale == "ruRU" then
    L["SettingsText1"] = "включить текст макроса в поиск"
elseif locale == "itIT" then
    L["SettingsText1"] = "includere testo macro nella ricerca"
elseif locale == "ptBR" then
    L["SettingsText1"] = "incluir texto de macro na pesquisa"
else
    L["SettingsText1"] = "include macro text in search"
end

local defaultSearchMacroText = false

SearchMacroText = nil


MACROSEARCH_NO_RESULTS = QUEST_LOG_NO_RESULTS or "No Results"


MacroSearchMixin = {}

-- Utility: Safe string.lower (handles nil)
local function safeLower(str)
	return type(str) == "string" and string.lower(str) or ""
end

function MacroSearchMixin:OnLoad()
	self.searchString = nil
	self.filterdMacros = {}
	self.updateFN = MacroFrame.Update
	self.findmode = "default"
	local offset = 24

	self.macros = {}
	self:fillMacroData()
	
	-- Improved search functions with error handling
	local function defaultFind(macro)
		if not macro or not macro.info or not macro.info[1] then return false end
		return string.find(safeLower(macro.info[1]), safeLower(self.searchString), 1, true)
	end

	local function extendedFind(macro)
		if not macro or not macro.info then return false end
		return string.find(safeLower(macro.info[1]), safeLower(self.searchString), 1, true)
			or string.find(safeLower(macro.info[3]), safeLower(self.searchString), 1, true)
	end

	self.findFn = { default = defaultFind, extended = extendedFind }

	

	local function MacroFrameInitMacroButton(macroButton, selectionIndex, name, texture, body)
		if name ~= nil then
			local nname = name
			if type(name) == "table" then
				nname = self.filterdMacros[macroButton.selectionIndex].info[1]
				texture = self.filterdMacros[macroButton.selectionIndex].info[2]
				local nindex = self.filterdMacros[macroButton.selectionIndex].index
				macroButton:SetSelectionIndex(nindex)
				macroButton.GetElementData = function() return nindex end -- fix drag and drop 
			end

			macroButton:SetIconTexture(texture);
			macroButton.Name:SetText(nname);
			macroButton:Enable();
		else
			macroButton:SetIconTexture("");
			macroButton.Name:SetText("");
			macroButton:Disable();
		end
	end

	MacroFrame.MacroSelector:SetPoint("TOPLEFT", 12, -66 - offset)
	MacroHorizontalBarLeft:SetPoint("TOPLEFT", 2, -210 - offset)
	MacroFrameSelectedMacroBackground:SetPoint("TOPLEFT", 5, -218 - offset)
	MacroFrameTextBackground:SetPoint("TOPLEFT", 6, -289 - offset)
	MacroFrame:SetHeight(MacroFrame:GetHeight() + offset)
	MacroSearchNoSearchResultsText:SetAllPoints(MacroFrame.MacroSelector.ScrollBox)



	
	local function getMacroType()
		return PanelTemplates_GetSelectedTab(MacroFrame) == 1 and "account" or "char"
	end

	self.macroType = "account"
	
	self:fillMacroData(self.macroType)
	self:SetScript("OnEvent", function(self, event)
		if event == "PLAYER_REGEN_DISABLED" then
			self.SearchBar:Disable()
			self:reset()
			return
		end

		if event == "PLAYER_REGEN_ENABLED" then
			self.SearchBar:Enable()
			return
		end
		self.macroType = getMacroType()
		self:fillMacroData(self.macroType)
		self:repeatSearch()
	end)

	local tabFn = function()
		local mt = getMacroType()
		if mt == self.macroType then return end
		self.macroType = mt
		self:fillMacroData(self.macroType)
		if self.searchString and self.searchString ~= "" then
			self:search(self.searchString)
		else
			self:search("")
		end
	end

	MacroFrameTab1:HookScript("OnClick", tabFn)
	MacroFrameTab2:HookScript("OnClick", tabFn)
	MacroFrame.MacroSelector:SetSetupCallback(MacroFrameInitMacroButton);



	self.SettingsDropdown.Icon:SetTexture("Interface/AddOns/MacroSearch/questlogframe.blp")
	self.SettingsDropdown.Icon:SetSize(15, 16)
	self.SettingsDropdown.Icon:SetTexCoord(0.21484375, 0.244140625, 0.11328125, 0.14453125)

	self.SettingsDropdown.IconHighhlight:SetTexture("Interface/AddOns/MacroSearch/questlogframe.blp")
	self.SettingsDropdown.IconHighhlight:SetSize(15, 16)
	self.SettingsDropdown.IconHighhlight:SetTexCoord(0.21484375, 0.244140625, 0.11328125, 0.14453125)

	self.SettingsDropdown:Init()
end

function MacroSearchMixin:fillMacroData(macroType)
	local function getMacroData(max, base)
		local values = {}
		for i = 1, max do
			local mi = { GetMacroInfo(base + i) }
			if mi[2] and mi[1] then -- Error handling: only valid macros
				table.insert(values, { index = i, info = mi })
			end
		end
		return values
	end

	if macroType == "account" then 
		self.macros = getMacroData(MAX_ACCOUNT_MACROS, 0)
	else 
		self.macros = getMacroData(MAX_CHARACTER_MACROS, MAX_ACCOUNT_MACROS)
	end
end

function MacroSearchMixin:OnShow()
	self:RegisterEvent("UPDATE_MACROS")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:setFindMode(SearchMacroText)

	local affectingCombat = UnitAffectingCombat("player")
	if affectingCombat then
		self.SearchBar:Enable() -- Allow searching in combat
	else
		self.SearchBar:Enable()
	end

	self:fillMacroData(self.macroType)
end

function MacroSearchMixin:OnHide()
	self:UnregisterEvent("UPDATE_MACROS");
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	self:reset()
end

function MacroSearchMixin:setFindMode(bool)
	SearchMacroText = bool or defaultSearchMacroText
	self.findmode = bool and "extended" or  "default"
end
function MacroSearchMixin:repeatSearch()
	if not self.searchString then return end
	self:search(self.searchString)
end

function MacroSearchMixin:search(str)
	self:fillMacroData(self.macroType)
	self.searchString = str or ""
	MacroFrame.Update = function() end

	-- Handle empty macro list
	if not self.macros or #self.macros == 0 then
		self.filterdMacros = {}
	else
		self.filterdMacros = _.filter(self.macros, function(macro)
			return self.findFn[self.findmode](macro)
		end)
	end
	
	local function MacroFrameGetMacroInfo(selectionIndex)
		return self.filterdMacros[selectionIndex]
	end

	local function MacroFrameGetNumMacros()
		return #self.filterdMacros
	end

	MacroFrame.MacroSelector:SetSelectionsDataProvider(MacroFrameGetMacroInfo, MacroFrameGetNumMacros)
	MacroSearchNoSearchResultsText:SetShown(MacroFrameGetNumMacros() == 0)
	MacroFrame:UpdateButtons()
end

function MacroSearchMixin:reset()
	MacroFrame.Update = self.updateFN
	MacroFrame:Update()
	self.searchString = nil
	self.SearchBar:Reset()
	MacroSearchNoSearchResultsText:Hide()
end


MacroSearchSearchBarMixin = {}

function MacroSearchSearchBarMixin:OnLoad()
	SearchBoxTemplate_OnLoad(self);
	self.clearButton:HookScript("OnClick", function(btn)
		self:GetParent():reset()
		SearchBoxTemplateClearButton_OnClick(btn);
	end)
end
function MacroSearchSearchBarMixin:search(text)
    if string.len(text) == 0 then
		self:GetParent():reset()
	else
		self:GetParent():search(text)
	end
end

function MacroSearchSearchBarMixin:OnEnterPressed()
	EditBox_ClearFocus(self);
	self:search(self:GetText())
end

function MacroSearchSearchBarMixin:OnKeyUp()
	self:search(self:GetText())
end

function MacroSearchSearchBarMixin:Reset()
	self:SetText("");
end



function MacroSearchSearchBarMixin:OnEnter()
	if self:IsEnabled() then return end

	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	GameTooltip:AddLine("Search is disabled in combat");
	GameTooltip:Show();
end

function MacroSearchSearchBarMixin:OnLeave()
	GameTooltip:Hide();
end



MacroSearchSettingsButtonMixin = {}

function MacroSearchSettingsButtonMixin:Init()


	local function IsSelected()
		return SearchMacroText
	end

	local function SetSelected()
		MacroSearch:setFindMode(not IsSelected())
		MacroSearch:repeatSearch() -- perform search
	end

	self:SetupMenu(function(dropdown, rootDescription)
		rootDescription:CreateCheckbox(L["SettingsText1"], IsSelected, SetSelected);
	end);
end

function MacroSearchSettingsButtonMixin:OnMouseDown()
	self.Icon:AdjustPointsOffset(1, -1);
end

function MacroSearchSettingsButtonMixin:OnMouseUp(button, upInside)
	self.Icon:AdjustPointsOffset(-1, 1);
end