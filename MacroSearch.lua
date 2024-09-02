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

MacroSearchMixin = {}

function MacroSearchMixin:OnLoad()
	self.searchString = nil
	self.filterdMacros = {}
	self.updateFN = MacroFrame.Update
	self.findmode = "default"
	local offset = 24
	
	local function defaultFind(macro) 
		return string.find(string.lower(macro.info[1]), string.lower(self.searchString)); 
	end

	local function extendedFind(macro) 
		return string.find(string.lower(macro.info[1]), string.lower(self.searchString)) or string.find(string.lower(macro.info[3]), string.lower(self.searchString)); 
	end

	self.findFn = { default = defaultFind, extended = extendedFind }

	
	local function getMacroType()
		return PanelTemplates_GetSelectedTab(MacroFrame) == 1 and "account" or "char"
	end

	self.macroType = getMacroType()
	local tabFn = function()
		self.macroType = getMacroType()
		self:reset()
	end
	local function MacroFrameInitMacroButton(macroButton, selectionIndex, name, texture, body)
		if name ~= nil then
			local nname = name
			if type(name) == "table" then
				nname = self.filterdMacros[macroButton.selectionIndex].info[1]
				texture = self.filterdMacros[macroButton.selectionIndex].info[2]
				local nindex = self.filterdMacros[macroButton.selectionIndex].index
				macroButton:SetSelectionIndex(nindex)
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

	local function getMacroData(max, base)
		local values = {}
		for i = 1, max, 1 do
			local mi = { GetMacroInfo(base + i) }
			if(mi[2]) then 
				table.insert(values, { index = i, info = mi })
			end
		end
		return values
	end

	local accountMacros = getMacroData(MAX_ACCOUNT_MACROS, 0)
	local charMacros = getMacroData(MAX_CHARACTER_MACROS, MAX_ACCOUNT_MACROS)

	self.macros = {
		account = accountMacros,
		char = charMacros
	}

	MacroFrame.MacroSelector:SetPoint("TOPLEFT", 12, -66 - offset)
	MacroHorizontalBarLeft:SetPoint("TOPLEFT", 2, -210 - offset)
	MacroFrameSelectedMacroBackground:SetPoint("TOPLEFT", 5, -218 - offset)
	MacroFrameTextBackground:SetPoint("TOPLEFT", 6, -289 - offset)

	MacroFrame:SetHeight(MacroFrame:GetHeight() + offset)

	MacroSearchNoSearchResultsText:SetAllPoints(MacroFrame.MacroSelector.ScrollBox)


	MacroFrameTab1:HookScript("OnClick", tabFn)
	MacroFrameTab2:HookScript("OnClick", tabFn)
	MacroFrame.MacroSelector:SetSetupCallback(MacroFrameInitMacroButton);

	self.SettingsDropdown:Init()

	-- SearchMacroText = nil
end

function MacroSearchMixin:OnShow()
	self:setFindMode(SearchMacroText)
end

function MacroSearchMixin:OnHide()
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
	self.searchString = str
	MacroFrame.Update = function() end

	local macros = self.macros[self.macroType]
	self.filterdMacros = _.filter(macros, function(macro) return self.findFn[self.findmode](macro) end)

	local function MacroFrameGetMacroInfo(selectionIndex)
		return self.filterdMacros[selectionIndex]
	end

	local function MacroFrameGetNumMacros()
		return #self.filterdMacros
	end

	MacroFrame.MacroSelector:SetSelectionsDataProvider(MacroFrameGetMacroInfo, MacroFrameGetNumMacros);
	MacroSearchNoSearchResultsText:SetShown(MacroFrameGetNumMacros() == 0)
	MacroFrame:UpdateButtons();
end

function MacroSearchMixin:reset()
	MacroFrame.Update = self.updateFN
	MacroFrame:Update()
	self.searchString = nil
	self.SearchBar:Reset()
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